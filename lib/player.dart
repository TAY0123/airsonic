import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

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
  MediaPlayer._() {}

  /// the one and only instance of this singleton
  static final instance = MediaPlayer._();

  //public
  String username = "";

  //private
  Uri _base = Uri();
  List<String> _segments = [];
  Map<String, dynamic> _param = {};
  late final Future<bool> _inited = init();

  Future<AirSonicResult> login(
      {String domain = "", String username = "", String password = ""}) async {
    if (domain.endsWith("/")) {
      //remove trailing "/" due to parse will include it in segments
      domain = domain.substring(0, domain.length - 1);
    }
    var connectionTestUri = Uri.parse(domain);
    final salt = getRandomString(20);
    final token = generateMd5(password + salt);
    connectionTestUri = connectionTestUri.replace(
        pathSegments:
            connectionTestUri.pathSegments.followedBy(["rest", "ping.view"]),
        queryParameters: {
          "u": username,
          "t": token,
          "s": salt,
          "v": "1.15",
          "c": "flutterTest"
        });
    if (await init()) {
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

    final resp = await xmlEndpoint("ping.view");

    return resp.status;
  }

  Future<Response> apiEndpoint(String ednpoint,
      {Map<String, dynamic>? query}) async {
    Map<String, dynamic> p = {};
    if (query != null) {
      p.addAll(_param);
      p.addAll(query);
    } else {
      p = _param;
    }
    final a = _base.replace(
        pathSegments: _segments.followedBy([ednpoint]), queryParameters: p);

    final resp = await http.get(a);
    if (resp.statusCode > 299 || resp.statusCode < 200) {
      throw resp.statusCode;
    }
    return resp;
  }

  Future<AirSonicResult> xmlEndpoint(String endpoint,
      {Map<String, dynamic>? query}) async {
    final data = await apiEndpoint(endpoint, query: query);
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

  Future<AirSonicResult> fetchAlbum() async {
    await _inited;
    var result = await xmlEndpoint("getAlbumList2", query: {"type": "recent"});
    return result;
  }

  fetchCover(String id) async {
    final Directory temp = await getTemporaryDirectory();
    final File imageFile = File('${temp.path}/images/$id.png');

    if (await imageFile.exists()) {
      // Use the cached images if it exists
    } else {
      // Image doesn't exist in cache
      final file = await imageFile.create(recursive: true);
      final data = await apiEndpoint("getCoverArt", query: {"id": id});
      file.writeAsBytes(data.bodyBytes);
      // Download the image and write to above file

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
  Album(this.id, this.name, this.coverArt, {this.songs});

  String id;
  String name;
  String coverArt;
  List<Song>? songs;

  factory Album.fromElement(XmlElement element) {
    return Album(
        element.getAttribute("id") ?? "",
        element.getAttribute("name") ?? "",
        element.getAttribute("coverArt") ?? "");
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
      track: int.parse(element.getAttribute("track") ?? ""),
    );
    final a = element.getAttribute("artistID");
    if (a != null) {
      re.artist = Artist();
      re.artist?.id = a;
      re.artist?.name = element.getAttribute("artist") ?? "";
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
}

enum AlbumListType { frequent, recent, newest }

extension FutureExtension<T> on Future<T> {
  /// Checks if the future has returned a value, using a Completer.
  bool isCompleted() {
    final completer = Completer<T>();
    then(completer.complete).catchError(completer.completeError);
    return completer.isCompleted;
  }
}
