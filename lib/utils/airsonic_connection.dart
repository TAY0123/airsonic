import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:airsonic/utils/player/shared.dart';
import 'package:audio_service/audio_service.dart';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();

String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
    length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

String generateMd5(String input) {
  return md5.convert(utf8.encode(input)).toString();
}

class MediaPlayer {
  late Future<ValueStream<MediaItem?>> currentItem;
  late Future<ValueStream<List<MediaItem>>> queue;
  late Future<Stream<Duration>> currentPosition;
  late Future<ValueStream<PlaybackState>> playerStatus;
  final preferenceStorage = SharedPreferences.getInstance();

  late Future<List<MediaItem>> previousQueue;

  /// private constructor
  MediaPlayer._() {
    () async {
      _listenToChangesInSong();
      _listenToChangesInPlaylist();
      _listenToCurrentPosition();
      _listenToPlayerStatus();
      previousQueue = _loadPreviousQueue();
    }();
  }

  Future<List<MediaItem>> _loadPreviousQueue() async {
    final List<MediaItem> result = [];
    final storage = await preferenceStorage;
    final data = storage.getString("queue");
    List<dynamic> objects = jsonDecode(
      data ?? "[]",
    );
    for (var element in objects) {
      result.add(MediaItem(
          id: element["id"],
          title: element["title"],
          artist: element["artist"],
          album: element["album"],
          artUri: Uri.parse(element["artUri"]),
          duration: Duration(seconds: element["duration"])));
    }

    //optional: load previous queue to mediaplayer
    //final player = await futurePlayer;
    //player.updateQueue(result);

    return result;
  }

  void _listenToChangesInSong() {
    currentItem = () async {
      final player = await futurePlayer;
      return player.mediaItem;
    }();
  }

  void _listenToChangesInPlaylist() {
    queue = () async {
      final player = await futurePlayer;
      player.queue.listen((playlist) async {
        if (playlist.isNotEmpty) {
          final storage = await preferenceStorage;
          storage.setString(
              "queue", jsonEncode(playlist.map((e) => e.toJson()).toList()));
        }
      });
      return player.queue;
    }();
  }

  void _listenToCurrentPosition() {
    currentPosition = () async {
      await futurePlayer;
      return AudioService.position;
    }();
  }

  void _listenToPlayerStatus() {
    playerStatus = () async {
      final player = await futurePlayer;
      return player.playbackState;
    }();
  }

  ValueNotifier<Duration> currentPos = ValueNotifier(Duration.zero);

  /// the one and only instance of this singleton
  static final instance = MediaPlayer._();

  //public
  String username = "";

  //private
  Uri _base = Uri();
  List<String> _segments = [];
  Map<String, dynamic> _param = {};
  late final Future<bool> _inited = init(); //initalize the information
  late final Future<AudioHandler> futurePlayer = initAudioService();

  Future<XMLResult> login(
      {String domain = "", String username = "", String password = ""}) async {
    if (domain.endsWith("/")) {
      //remove trailing "/" due to parse will include it in segments
      domain = domain.substring(0, domain.length - 1);
    }

    try {
      _base = Uri.parse(domain);
    } catch (e) {
      throw "invalid url";
    }

    final salt = getRandomString(20);
    final token = generateMd5(password + salt);
    _segments = List<String>.of(_base.pathSegments);
    _segments.add("rest");
    _param = {
      "u": username,
      "t": token,
      "s": salt,
      "v": "1.15",
      "c": "flutsonic"
    };

    final res = await _xmlEndpoint(
      "ping.view",
    );
    if (res.status) {
      //write credentials to storage
      final storage = await preferenceStorage;
      storage.setString("domain", domain);
      storage.setString("username", username);
      storage.setString("token", token);
      storage.setString("salt", salt);
    }
    return res;
  }

  Future<bool> init() async {
    final prefs = await SharedPreferences.getInstance();
    final domain = prefs.getString("domain") ?? "";
    username = prefs.getString("username") ?? "";
    final token = prefs.getString("token") ?? "";
    final salt = prefs.getString("salt") ?? "";

    if (domain.isEmpty || token.isEmpty || username.isEmpty) {
      throw ("login credentials error");
    }

    _base = Uri.parse(domain);
    _segments = _base.pathSegments.toList();
    _segments.add("rest");
    _param = {
      "u": username,
      "t": token,
      "s": salt,
      "v": "1.15",
      "c": "flutsonic"
    };
    _base = _base.replace(queryParameters: _param);

    final resp = await _xmlEndpoint("ping.view");

    return resp.status;
  }

  Uri _getApiUri(String ednpoint, {Map<String, String>? query}) {
    Map<String, dynamic> p = Map.from(_param);
    if (query != null) {
      p.addAll(query);
    }
    final a = _base.replace(
        pathSegments: _segments.followedBy([ednpoint]), queryParameters: p);
    return a;
  }

  Future<Response> _apiEndpoint(String ednpoint,
      {Map<String, String>? query}) async {
    Map<String, dynamic> p = Map.from(_param);
    if (query != null) {
      p.addAll(query);
    }
    final a = _base.replace(
        pathSegments: _segments.followedBy([ednpoint]), queryParameters: p);
    debugPrint(a.toString());
    late Response resp;

    ///this seem that occur due to too many request at the same time
    try {
      resp = await http.get(a);
    } catch (e) {
      if (e == SocketException) {
        throw "too many request";
      } else {
        rethrow;
      }
    }
    if (resp.statusCode > 299 || resp.statusCode < 200) {
      throw resp.statusCode;
    }
    return resp;
  }

  Future<XMLResult> _xmlEndpoint(String endpoint,
      {Map<String, String>? query}) async {
    final data = await _apiEndpoint(endpoint, query: query);
    final root = XmlDocument.parse(data.body);

    var result = XMLResult();

    //check if status ok
    final status =
        root.getElement("subsonic-response")?.getAttribute("status") ?? "";
    if (status != "ok") {
      throw ("login credentials error");
    } else {
      result.status = true;
    }

    //fetch album
    for (var album in root.findAllElements(
      "album",
    )) {
      var albumObj = Album.fromElement(album);
      //if (album.childElements.isNotEmpty) {}
      result.albums.add(albumObj);
    }
    for (var artist in root.findAllElements("artist")) {
      result.artists.add(Artist.fromElement(artist));
    }
    for (var playlist in root.findAllElements("playlist")) {
      result.playlists.add(Playlist.fromElement(playlist));
    }
    for (var song in root.findAllElements("song")) {
      result.songs.add(Song.fromElement(song));
    }
    return result;
  }

  AirSonicResult getAlbumList2({
    AlbumListType type = AlbumListType.recent,
    String folderId = "",
  }) {
    final res = AirSonicResult();

    res.album = AlbumList(
      (offset, count) async {
        await _inited;
        Map<String, String> q = {};
        if (folderId.isNotEmpty) {
          q["musicFolderId"] = folderId;
        }
        q["type"] = type.name;
        q["offset"] = "$offset";
        q["size"] = "$count";

        return await _xmlEndpoint("getAlbumList2", query: q);
      },
    );

    return res;
  }

  AirSonicResult getArtists() {
    final res = AirSonicResult();
    res.artist = ArtistList((offset, count) async {
      await _inited;
      return await _xmlEndpoint("getArtists");
    });

    return res;
  }

  Future<XMLResult> getAlbum(String albumId) async {
    return await _xmlEndpoint("getAlbum", query: {"id": albumId});
  }

  Future<XMLResult> getSong(String songId) async {
    return await _xmlEndpoint("getSong", query: {"id": songId});
  }

  Future<XMLResult> fetchFolder(String folderId) async {
    var albumlist = await _xmlEndpoint("getAlbum", query: {"id": folderId});
    XMLResult result = XMLResult();
    for (final album in albumlist.albums) {
      result.albums.addAll((await getAlbum(album.id)).albums);
    }
    return result;
  }

  AirSonicResult search3(String keyword) {
    final result = AirSonicResult();
    result.keywords = keyword;
    result.album = AlbumList((offset, count) async {
      return _xmlEndpoint("search3", query: {
        "query": keyword,
        "albumOffset": "$offset",
        "albumCount": "$count",
      });
    });
    result.artist = ArtistList((offset, count) async {
      return _xmlEndpoint("search3", query: {
        "query": keyword,
        "artistOffset": "$offset",
        "artistCount": "$count",
      });
    });
    return result;
  }

  ImageProvider _resizeImage(ImageProvider src, ImageSize size) {
    switch (size) {
      case ImageSize.thumb:
        return ResizeImage(src, width: 50);
      case ImageSize.avatar:
        return ResizeImage(src, width: 256);
      case ImageSize.grid:
        return ResizeImage(src, width: 350);
      case ImageSize.card:
        return ResizeImage(src, width: 512);
      case ImageSize.original:
        return src;
    }
  }

  Future<ImageProvider?> getCoverArt(String id,
      {ImageSize size = ImageSize.grid}) async {
    if (id.isEmpty) return null;
    if (kIsWeb) {
      final url = _getApiUri("getCoverArt", query: {"id": id});
      return _resizeImage(NetworkImage(url.toString()), size);
    } else {
      final Directory temp = await getTemporaryDirectory();
      final File imageFile = File('${temp.path}/images/$id.png');

      if ((await imageFile.exists()) && (await imageFile.length()) != 0) {
        // Use the cached images if it exists
        ImageProvider file;
        try {
          file = FileImage(imageFile);
        } catch (e) {
          return null;
        }
        return _resizeImage(file, size);
      } else {
        // Image doesn't exist in cache
        final file = await imageFile.create(recursive: true);
        final data = await _apiEndpoint("getCoverArt", query: {"id": id});
        if (data.headers["content-type"]?.contains("image") ?? false) {
          // Download the image and write to above file
          file.writeAsBytes(data.bodyBytes);
        } else {
          return null;
          //throw "Content type is not image";
        }

        return _resizeImage(MemoryImage(data.bodyBytes), size);
      }
    }
  }

  Future<bool> startScan() async {
    await _xmlEndpoint("startScan");
    return true;
  }

  Future<XMLResult> getPlaylists() async {
    return _xmlEndpoint("getPlaylists");
  }

  Future<Uri?> _coverUri(String id) async {
    if (id.isEmpty) return null;
    if (kIsWeb) return _getApiUri("getCoverArt", query: {"id": id});
    final Directory temp = await getTemporaryDirectory();
    final File imageFile = File('${temp.path}/images/$id.png');

    if ((await imageFile.exists()) && (await imageFile.length()) != 0) {
      // Use the cached images if it exists
    } else {
      // Image doesn't exist in cache
      final file = await imageFile.create(recursive: true);
      final data = await _apiEndpoint("getCoverArt", query: {"id": id});
      if (data.headers["content-type"]?.contains("image") ?? false) {
        await file.writeAsBytes(data.bodyBytes);
      } else {
        return null;
      }

      // Download the image and write to above file
    }
    return imageFile.uri;
  }

  void playPlaylist(List<Song> playlist, {int index = 0}) async {
    final fplayer = await futurePlayer;
    await fplayer.stop();
    List<MediaItem> res = [];
    for (Song song in playlist) {
      res.add(await song.getMediaItem());
    }

    await fplayer.updateQueue(res);
    await fplayer.skipToQueueItem(index);
    fplayer.play();
  }

  Future<XMLResult> getPlaylist(String id) async {
    return await _xmlEndpoint("getPlaylist", query: {"id": id});
  }

  Future<XMLResult> fetchArtist(String id) async {
    return await _xmlEndpoint("getArtist", query: {"id": id});
  }

  ///Skip to indexed if current playlist is the album
  Future<void> skipToIndexed(int index) async {
    final player = await futurePlayer;
    await player.skipToQueueItem(index);
  }
}

class XMLResult {
  bool status = false;
  List<Album> albums = [];
  List<Song> songs = [];
  List<Artist> artists = [];
  List<Playlist> playlists = [];
}

class CachedImage {
  ImageSize size;
  ImageProvider? image;

  CachedImage(this.image, this.size);
}

class Album {
  Album(
    this.id, {
    this.name = "",
    this.coverArt = "",
    this.artist,
    this.songs,
  });

  String id;
  String name;
  String coverArt;
  Artist? artist;
  List<Song>? songs;
  CachedImage? image;
  bool combined = false; //it indicate if a album has already combined

  Future<bool> fetchCover({ImageSize size = ImageSize.grid}) async {
    final connection = MediaPlayer.instance;
    try {
      image = CachedImage(await connection.getCoverArt(coverArt), size);
    } catch (e) {
      return false;
    }
    return true;
  }

  ///fetch all albumInfo from server
  ///return false if failed and true on success
  Future<bool> fetchInfo() async {
    //get if album enabled
    final storage = await SharedPreferences.getInstance();
    final combine = storage.getBool("albumCombine") ?? false;

    final connection = MediaPlayer.instance;
    try {
      final result = await connection.getAlbum(id);
      if (result.albums.isEmpty) {
        return false;
      } else {
        id = result.albums[0].id;
        artist = result.albums[0].artist;
        songs = result.albums[0].songs;
        name = result.albums[0].name;
        coverArt = result.albums[0].coverArt;
      }
      if (combine) {
        final others = connection.search3(name);
        while (!(others.album?.finished ?? true)) {
          await others.album?._fetchUncombinedNext(count: 30);
          if (others.album?.albums.last.name != name) {
            break;
          }
        }
        List<Future<void>> results = [];
        for (var a in others.album?.albums ?? List<Album>.empty()) {
          if (a.name == name) {
            if (a.id != id) {
              combined = true;
              results.add(connection
                  .getAlbum(a.id)
                  .then((value) => songs?.addAll(value.albums[0].songs ?? [])));
            }
          } else {
            continue;
          }
        }
        await Future.wait(results);
      }
    } catch (e) {
      return false;
    }

    //remove duplicate entries having same name
    if (storage.getBool("hideDuplicate") ?? false) {
      songs?.retainWhere((element) =>
          songs!.lastWhere((last) => ((last.title == element.title ||
                  (last.track == element.track &&
                      last.duration == element.duration)) &&
              last.artist?.name == element.artist?.name)) ==
          element);

      ///hide album from list if name equal
      ///or index equal + duration equal
      ///and artist equal if above any condition meet
    }
    //TODO: classify album  to separarte disc 1,2 maybe by coverArt?
    songs?.sort((a, b) => (a.track - b.track));
    return true;
  }

  ///Parameter	Required	Default	Comment
  ///id	        Yes		    The album or song ID.
  static Future<Album> fromId(String id) async {
    final result = Album(id);
    await result.fetchInfo();
    return result;
  }

  factory Album.fromElement(XmlElement element) {
    final a = Album(element.getAttribute("id") ?? "",
        name: element.getAttribute("name") ?? "",
        coverArt: element.getAttribute("coverArt") ?? "",
        artist: element.getAttribute("artistId") != null
            ? Artist.fromAlbum(element)
            : null);

    if (element.childElements.isNotEmpty) {
      a.songs = [];
      for (var song in element.childElements) {
        final tmp = Song.fromAlbum(a, song);
        if (tmp.id.isNotEmpty) {
          a.songs?.add(tmp);
        }
      }
    }
    return a;
  }
}

class Song {
  String id;
  String title;
  String coverArt;
  int duration;
  Album? album;
  Artist? artist;
  int track;

  final mp = MediaPlayer.instance;

  Song(this.id,
      {this.title = "",
      this.coverArt = "",
      this.duration = 0,
      this.track = 0,
      this.album,
      this.artist});

  Future<bool> getInfo() async {
    final result = await mp.getSong(id);
    if (result.songs.isEmpty) {
      return false;
    }
    final currentSong = result.songs[0];
    id = currentSong.id;
    album = currentSong.album;
    artist = currentSong.artist;
    duration = currentSong.duration;
    title = currentSong.title;
    coverArt = currentSong.coverArt;
    track = currentSong.track;

    return true;
  }

  Future<MediaItem> getMediaItem() async {
    final storage = await SharedPreferences.getInstance();
    final mediaURI = mp._getApiUri("stream",
        query: {"id": id, "format": storage.getString("format") ?? "mp3"});
    return MediaItem(
      id: mediaURI.toString(),
      artUri: await mp._coverUri(coverArt),
      title: title,
      duration: Duration(seconds: duration),
      artist: artist?.name ?? album?.artist?.name ?? "Unknown",
      album: album?.name ?? "test album",
    );
  }

  factory Song.fromAlbum(Album album, XmlElement element) {
    var re = Song(element.getAttribute("id") ?? "",
        title: element.getAttribute("title") ?? "",
        coverArt: element.getAttribute("coverArt") ?? "",
        duration: int.parse(element.getAttribute("duration") ?? ""),
        track: int.tryParse(element.getAttribute("track") ?? "") ?? 0,
        album: album);
    final a = element.getAttribute("artistId");
    if (a != null) {
      re.artist = Artist.fromSong(element);
    }
    return re;
  }

  factory Song.fromElement(XmlElement element) {
    return Song(element.getAttribute("id") ?? "",
        title: element.getAttribute("title") ?? "",
        coverArt: element.getAttribute("coverArt") ?? "",
        duration: int.parse(element.getAttribute("duration") ?? ""),
        track: int.tryParse(element.getAttribute("track") ?? "") ?? 0,
        artist: Artist(element.getAttribute("artistId") ?? "",
            element.getAttribute("artist") ?? ""),
        album: Album(element.getAttribute("albumId") ?? "",
            name: element.getAttribute("album") ?? ""));
  }
}

class Artist {
  String id = "";
  String name = "";
  String coverID = "";
  List<Album>? albums;
  int albumsCount = 0;
  ImageProvider? img;

  MediaPlayer mp = MediaPlayer.instance;

  Artist(this.id, this.name,
      {this.coverID = "", this.albums, this.albumsCount = 0});

  Future<bool> fetchCover() async {
    final connection = MediaPlayer.instance;
    try {
      img = await connection.getCoverArt(coverID);
    } catch (e) {
      return false;
    }
    return true;
  }

  factory Artist.fromElement(XmlElement element) {
    final res = Artist(
      element.getAttribute("id") ?? "",
      element.getAttribute("name") ?? "",
      coverID: element.getAttribute("coverArt") ?? "",
      albumsCount: int.tryParse(element.getAttribute("albumCount") ?? "") ?? 0,
    );
    if (element.childElements.isNotEmpty) {
      res.albums = [];
      for (var ele in element.childElements) {
        final tmp = Album.fromElement(ele);
        if (tmp.id != "") {
          res.albums?.add(tmp);
        }
      }
    }
    return res;
  }

  Future<bool> getDetail() async {
    final res = await mp.fetchArtist(id);
    if (res.artists.isEmpty) {
      return false;
    } else {
      name = res.artists[0].name;
      coverID = res.artists[0].coverID;
      albums = res.artists[0].albums;
      albumsCount = res.artists[0].albumsCount;
    }
    return true;
  }

  AirSonicResult getAlbumController() {
    final res = AirSonicResult();
    res.album = AlbumList((offset, count) async {
      return XMLResult();
    });
    res.album?.albums = albums!;
    res.album?.finished = true;
    return res;
  }

  factory Artist.fromAlbum(XmlElement element) {
    return Artist(element.getAttribute("artistId") ?? "",
        element.getAttribute("artist") ?? "");
  }

  factory Artist.fromSong(XmlElement element) {
    return Artist(element.getAttribute("artistId") ?? "",
        element.getAttribute("artist") ?? "");
  }
}

class Playlist {
  final String id;
  String? name;
  String? comment;
  int? songCount;
  String? owner;
  bool? public;
  Duration? duration;
  DateTime? created;
  String? coverArt;
  List<Song>? entries;

  Playlist(this.id,
      {this.name,
      this.comment,
      this.songCount,
      this.owner,
      this.public,
      this.duration,
      this.created,
      this.coverArt,
      this.entries});

  factory Playlist.fromElement(XmlElement element) {
    var id = element.getAttribute("id");
    var name = element.getAttribute("name");
    var comment = element.getAttribute("comment");
    var songCount = int.tryParse(element.getAttribute("songCount") ?? "");
    var owner = element.getAttribute("owner");
    var duration = Duration(
        seconds: int.tryParse(element.getAttribute("duration") ?? "") ?? 0);
    var coverArt = element.getAttribute("coverArt");
    List<Song>? entries;
    if (element.childElements.isNotEmpty) {
      entries = [];
      for (var entry in element.childElements) {
        entries.add(Song.fromElement(entry));
      }
    }
    return Playlist(
      id ?? "",
      name: name,
      comment: comment ?? "",
      songCount: songCount ?? 0,
      owner: owner ?? "",
      duration: duration,
      coverArt: coverArt ?? "",
      entries: entries,
      //public
      //created
    );
  }

  Future<bool> getInfo() async {
    final res = await MediaPlayer.instance.getPlaylist(id);
    if (res.playlists.isNotEmpty) {
      final detailedPlaylist = res.playlists[0];
      name = detailedPlaylist.name;
      coverArt = detailedPlaylist.coverArt;
      songCount = detailedPlaylist.songCount;
      owner = detailedPlaylist.owner;
      duration = detailedPlaylist.duration;
      comment = detailedPlaylist.comment;
      entries = detailedPlaylist.entries;
    }
    return true;
  }
}

enum AlbumListType {
  random,
  newest,
  frequent,
  recent,
  starred,
  alphabeticalByName,
  /* support on 1.10.1 */
  alphabeticalByArtist,
  byYear,
  byGenre
}

enum ImageSize { thumb, avatar, grid, card, original }

class AlbumList {
  int _offset = 0;
  List<Album> albums = [];
  bool finished = false;

  final Future<XMLResult> Function(int offset, int count) _fetch;

  AlbumList(this._fetch);
  final mp = MediaPlayer.instance;

  Future<int> _fetchUncombinedNext({int count = 10}) async {
    final result = (await _fetch(_offset, count)).albums;
    albums.addAll(result);

    _offset += result.length;

    if (result.isEmpty || result.length != count) {
      finished = true;
    }
    return result.length;
  }

  ///fetch next count of item to album list and
  ///return count of success fetched albums
  Future<int> fetchNext({int count = 10}) async {
    final result = (await _fetch(_offset, count)).albums;
    final storage = await SharedPreferences.getInstance();
    final combine = storage.getBool("albumCombine") ?? false;
    if (combine) {
      for (var resultAlbum in result) {
        final index =
            albums.indexWhere((element) => element.name == resultAlbum.name);
        if (index != -1) {
          albums[index].songs?.addAll(resultAlbum.songs?.where((e) =>
                  albums[index]
                      .songs!
                      .every((element) => !(e.title == element.title))) ??
              []);
          //indicate the album has combined other album id
          albums[index].combined = true;
        } else {
          albums.add(resultAlbum);
        }
      }
    } else {
      albums.addAll(result);
    }

    _offset += result.length;

    if (result.isEmpty || result.length != count) {
      finished = true;
    }
    return result.length;
  }
}

class ArtistList {
  int _offset = 0;
  List<Artist> artists = [];
  bool finished = false;

  final Future<XMLResult> Function(int offset, int count) _fetch;

  ArtistList(this._fetch);
  final mp = MediaPlayer.instance;

  ///fetch next count of item to album list and
  ///return count of success fetched albums
  Future<int> fetchNext({int count = 10}) async {
    final result = (await _fetch(_offset, count)).artists;
    artists.addAll(result);
    _offset += result.length;

    if (result.length != count) {
      finished = true;
    }
    return result.length;
  }
}

class AirSonicResult {
  AlbumList? album;
  ArtistList? artist;
  String keywords = "";
}

extension ToJSON on MediaItem {
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'id': id,
      'artist': artist,
      'album': album,
      'artUri': artUri.toString(),
      'duration': duration?.inSeconds,
    };
  }
}