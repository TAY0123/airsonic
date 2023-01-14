import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:airsonic/player.dart';
import 'package:audio_service/audio_service.dart';

import 'package:crypto/crypto.dart';
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
  late Future<ValueStream<List<MediaItem>>> playlist;
  late Future<Stream<Duration>> currentPosition;
  late Future<ValueStream<PlaybackState>> playerStatus;

  /// private constructor
  MediaPlayer._() {
    () async {
      _listenToChangesInSong();
      _listenToChangesInPlaylist();
      _listenToCurrentPosition();
      _listenToPlayerStatus();
    }();
  }
  void _listenToChangesInSong() {
    currentItem = () async {
      final player = await futurePlayer;
      return player.mediaItem;
    }();
    /*
    final player = await futurePlayer;
    current = player.mediaItem;
    player.mediaItem.listen((mediaItem) {
      print(mediaItem?.duration?.inSeconds);
      currentItem.value = mediaItem ?? const MediaItem(id: "", title: "");
      _updateSkipButtons();
    });
    */
  }

  void _updateSkipButtons() async {
    final player = await futurePlayer;
    final mediaItem = player.mediaItem.value;
    final playlist = player.queue.value;
    if (playlist.length < 2 || mediaItem == null) {
      //isFirstSongNotifier.value = true;
      //isLastSongNotifier.value = true;
    } else {
      //isFirstSongNotifier.value = playlist.first == mediaItem;
      //isLastSongNotifier.value = playlist.last == mediaItem;
    }
  }

  void _listenToChangesInPlaylist() {
    playlist = () async {
      final player = await futurePlayer;
      return player.queue;
    }();
    /*
    final player = await futurePlayer;
    player.queue.listen((playlist) {
      if (playlist.isEmpty) return;
      final newList = playlist.map((item) => item.title).toList();
    });
    */
  }

  void _listenToCurrentPosition() {
    currentPosition = () async {
      await futurePlayer;
      return AudioService.position;
    }();
    /*
    await futurePlayer;
    AudioService.position.listen((position) {
      currentPos.value = position;
    });
    */
  }

  void _listenToPlayerStatus() {
    playerStatus = () async {
      final player = await futurePlayer;
      return player.playbackState;
    }();
    /*
    await futurePlayer;
    AudioService.position.listen((position) {
      currentPos.value = position;
    });
    */
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

  Future<AirSonicResult> login(
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
      final prefs = await SharedPreferences.getInstance();
      prefs.setString("domain", domain);
      prefs.setString("username", username);
      prefs.setString("token", token);
      prefs.setString("salt", salt);
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

  Future<Response> _apiEndpoint(String ednpoint,
      {Map<String, String>? query}) async {
    Map<String, dynamic> p = Map.from(_param);
    if (query != null) {
      p.addAll(query);
    }
    final a = _base.replace(
        pathSegments: _segments.followedBy([ednpoint]), queryParameters: p);
    print(a);
    late Response resp;
    try {
      resp = await http.get(a);
    } catch (e) {
      throw e;
    }
    if (resp.statusCode > 299 || resp.statusCode < 200) {
      throw resp.statusCode;
    }
    return resp;
  }

  Future<AirSonicResult> _xmlEndpoint(String endpoint,
      {Map<String, String>? query}) async {
    final data = await _apiEndpoint(endpoint, query: query);
    final root = XmlDocument.parse(data.body);

    var result = AirSonicResult();

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

    return result;
  }

  Future<AirSonicResult> fetchAlbumList(
      {int offset = 0,
      int count = 0,
      AlbumListType type = AlbumListType.recent,
      String folderId = ""}) async {
    await _inited;
    Map<String, String> q = {};
    if (folderId.isNotEmpty) {
      q["musicFolderId"] = folderId;
    }
    q["type"] = AlbumListType.recent.name;
    q["offset"] = "$offset";
    var result = await _xmlEndpoint("getAlbumList2", query: q);
    return result;
  }

  Future<AirSonicResult> fetchAlbumInfo(String albumId) async {
    return await _xmlEndpoint("getAlbum", query: {"id": albumId});
  }

  Future<AirSonicResult> fetchFolder(String folderId) async {
    var albumlist = await _xmlEndpoint("getAlbum", query: {"id": folderId});
    AirSonicResult result = AirSonicResult();
    for (final album in albumlist.albums) {
      result.albums.addAll((await fetchAlbumInfo(album.id)).albums);
    }
    return result;
  }

  Future<ImageProvider?> fetchCover(String id, {full = false}) async {
    if (id.isEmpty) return Future.error(Exception("no image data"));
    final Directory temp = await getTemporaryDirectory();
    final File imageFile = File('${temp.path}/images/$id.png');

    if ((await imageFile.exists()) && (await imageFile.length()) != 0) {
      // Use the cached images if it exists
      if (!full) {
        return MemoryImage(await imageFile.readAsBytes(), scale: 0.75);
      } else {
        return MemoryImage(await imageFile.readAsBytes());
      }
    } else {
      // Image doesn't exist in cache
      final file = await imageFile.create(recursive: true);
      final data = await _apiEndpoint("getCoverArt", query: {"id": id});
      if (data.headers["content-type"]?.contains("image") ?? false) {
        file.writeAsBytes(data.bodyBytes);
      } else {
        throw "Content type is not image";
      }

      // Download the image and write to above file
      if (!full) {
        return MemoryImage(data.bodyBytes, scale: 0.75);
      } else {
        return MemoryImage(data.bodyBytes);
      }
    }
  }

  Future<Uri?> _coverUri(String id) async {
    if (id.isEmpty) return null;
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
    List<MediaItem> res = [];
    for (Song song in playlist.skip(index)) {
      res.add(MediaItem(
        id: song.id,
        artUri: await _coverUri(song.coverArt),
        title: song.title,
        duration: Duration(seconds: song.duration),
        artist: song.artist?.name ?? song.album?.artist?.name ?? "Unknown",
        album: song.album?.name ?? "test album",
      ));
    }
    await fplayer.updateQueue(res);

    /*
      player.playFromUri(_apiEndpointUrl("stream",
          query: {"id": playlist[i].id, "format": "mp3"}));
          */

    fplayer.play();
  }
}

class AirSonicResult {
  bool status = false;
  List<Album> albums = [];
  List<Song> songs = [];
  List<Artist> artists = [];
}

class Album {
  Album(this.id, this.name, this.coverArt, {this.artist, this.songs});

  String id;
  String name;
  String coverArt;
  Artist? artist;
  List<Song>? songs;

  factory Album.fromElement(XmlElement element) {
    final a = Album(
        element.getAttribute("id") ?? "",
        element.getAttribute("name") ?? "",
        element.getAttribute("coverArt") ?? "",
        artist: element.getAttribute("artistId") != null
            ? Artist.FromAlbum(element)
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

  Song(this.id, this.title, this.coverArt, this.duration,
      {this.track = 0, this.album, this.artist});

  factory Song.fromAlbum(Album album, XmlElement element) {
    var re = Song(
        element.getAttribute("id") ?? "",
        element.getAttribute("title") ?? "",
        element.getAttribute("coverArt") ?? "",
        int.parse(element.getAttribute("duration") ?? ""),
        track: int.tryParse(element.getAttribute("track") ?? "") ?? 0,
        album: album);
    final a = element.getAttribute("artistId");
    if (a != null) {
      re.artist = Artist.FromSong(element);
    }
    return re;
  }
}

class Artist {
  String id = "";
  String name = "";
  String coverID = "";
  List<Album>? albums;
  int albumsCount = 0;

  Artist(this.id, this.name,
      {this.coverID = "", this.albums, this.albumsCount = 0});

  factory Artist.fromElement(XmlElement element) {
    return Artist(
      element.getAttribute("Id") ?? "",
      element.getAttribute("name") ?? "",
      coverID: element.getAttribute("coverArt") ?? "",
      albumsCount: int.parse(element.getAttribute("albumCount") ?? ""),
    );
  }

  //TODO: implement
  void getDetail() {}

  factory Artist.FromAlbum(XmlElement element) {
    return Artist(element.getAttribute("artistId") ?? "",
        element.getAttribute("artist") ?? "");
  }

  factory Artist.FromSong(XmlElement element) {
    return Artist(element.getAttribute("artistId") ?? "",
        element.getAttribute("artist") ?? "");
  }
}

enum AlbumListType {
  random,
  newest,
  frequent,
  recent,
  starred,
  alphabeticalByName,
  alphabeticalByArtist,
  byYear,
  byGenre
}

extension FutureExtension<T> on Future<T> {
  /// Checks if the future has returned a value, using a Completer.
  bool isCompleted() {
    final completer = Completer<T>();
    then((v) {
      return completer.complete(v);
    }).catchError(completer.completeError);
    return completer.isCompleted;
  }
}
