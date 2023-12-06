import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class medeia with ChangeNotifier {
  List<String> mediaFiles = [];
  int _mediaCount = 0;
  int get mediaCount => _mediaCount;
  void a() {
    final d = Directory("/Users/tommy/Music");
    final s = d.list(recursive: true);
    s.forEach((element) {
      switch (p.extension(element.path)) {
        case ".flac":
        case ".wav":
        case ".mp3":
        case ".opus":
        case ".aac":
        case ".m4a":
        case ".ogg":
          mediaFiles.add(element.path);
          _mediaCount++;
          notifyListeners();
          break;
        default:
          debugPrint(p.extension(element.path));
      }
    });
  }

  void b(String p) async {
    final c = await FFprobeKit.getMediaInformationAsync(p);
  }
}