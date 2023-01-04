import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
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
  /// private constructor
  MediaPlayer._();

  /// the one and only instance of this singleton
  static final instance = MediaPlayer._();

  //public
  String username = "";

  //private
  Uri _base = Uri();
  List<String> _segments = [];
  Map<String, dynamic> _param = {};
  late final Future<bool> _inited = init(); //initalize the information

  Future<AirSonicResult> login(
      {String domain = "", String username = "", String password = ""}) async {
    if (domain.endsWith("/")) {
      //remove trailing "/" due to parse will include it in segments
      domain = domain.substring(0, domain.length - 1);
    }
    _base = Uri.parse(domain);
    final salt = getRandomString(20);
    final token = generateMd5(password + salt);
    _segments = List<String>.of(_base.pathSegments);
    _segments.add("rest");
    _param = {
      "u": username,
      "t": token,
      "s": salt,
      "v": "1.15",
      "c": "flutterTest"
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
    return AirSonicResult();
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
      "c": "flutterTest"
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
    final resp = await http.get(a);
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

  Future<AirSonicResult> fetchAlbum(
      {int offset = 0,
      int count = 0,
      AlbumListType type = AlbumListType.recent}) async {
    await _inited;

    var result = await _xmlEndpoint("getAlbumList2",
        query: {"type": AlbumListType.recent.name, "offset": "$offset"});
    return result;
  }

  Future<AirSonicResult> fetchAlbumInfo(String albumId) async {
    return await _xmlEndpoint("getAlbum", query: {"id": albumId});
  }

  Future<ImageProvider?> fetchCover(String id, {full = false}) async {
    if (id.isEmpty) return Future.error(Exception("no image data"));
    final Directory temp = await getTemporaryDirectory();
    final File imageFile = File('${temp.path}/images/$id.png');

    if (await imageFile.exists()) {
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
      file.writeAsBytes(data.bodyBytes);
      // Download the image and write to above file
      if (!full) {
        return MemoryImage(data.bodyBytes, scale: 0.75);
      } else {
        return MemoryImage(data.bodyBytes);
      }
    }
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
        final tmp = Song.fromElement(song);
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

  factory Song.fromElement(XmlElement element) {
    var re = Song(
      element.getAttribute("id") ?? "",
      element.getAttribute("title") ?? "",
      element.getAttribute("coverArt") ?? "",
      int.parse(element.getAttribute("duration") ?? ""),
      track: int.tryParse(element.getAttribute("track") ?? "") ?? 0,
    );
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
