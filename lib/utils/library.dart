import 'package:airsonic/utils/utils.dart';
import 'package:flutter/material.dart';

abstract class LibrarySource {
  AlbumController getAlbums() {
    throw "unimplemented";
  }
}

abstract class AlbumController {
  ///fetch next count of item to album list and
  ///return success fetched albums
  List<LAlbum> next({int count = 10}) {
    throw "unimplemented";
  }
}

abstract class LAlbum {
  String id;
  String name;
  String coverArt;
  LArtist? artist;
  List<LSong>? _songs;
  CachedImage? _image;

  LAlbum(
    this.id, {
    this.name = "",
    this.coverArt = "",
    this.artist,
  });

  //function will be call automatically if image is null when display
  Future<bool> fetchCover({ImageSize size = ImageSize.grid}) async {
    throw "unimplemented";
  }

  //function will be call automatically if no songs exist and are require
  Future<bool> fetchInfo() async {
    throw "unimplemented";
  }

  Future<List<LSong>> getSong() async {
    if (_songs == null) {
      await fetchInfo();
    }
    return Future.value(_songs);
  }

  Future<CachedImage?> getImage() async {
    if (_image == null) {
      await fetchCover();
    }
    return Future.value(_image);
  }
}

abstract class LArtist {
  String id = "";
  String name = "";
  String coverID = "";
  List<LAlbum>? albums;
  int albumsCount = 0;
  ImageProvider? img;
}

abstract class LSong {
  String id;
  String title;
  String coverArt;
  int duration;
  LAlbum? album;
  LArtist? artist;
  int track;

  LSong(this.id,
      {this.title = "",
      this.coverArt = "",
      this.duration = 0,
      this.track = 0,
      this.album,
      this.artist});
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
