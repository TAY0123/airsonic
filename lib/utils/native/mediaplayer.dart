import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

class PlayerStatus {
  bool playing;
  bool stopped;
  Duration position;
  Duration duration;
  String format;
  double sampleRate;
  int bitRate;
  double volume;
  int index;

  PlayerStatus({
    this.playing = false,
    this.stopped = true,
    this.duration = Duration.zero,
    this.position = Duration.zero,
    this.format = "",
    this.sampleRate = 0,
    this.bitRate = 0,
    this.volume = 0,
    this.index = 0,
  });
}

class CustomMediaPlayer {
  static const platform = MethodChannel('samples.flutter.dev/mediaplayer');
  static const event = EventChannel("samples.flutter.dev/mediaplayerStatus");

  final StreamController<MediaItem> _current = StreamController();

  var index = 0;
  var stopped = true;
  List<MediaItem> queue = [];

  late Stream<PlayerStatus> status;
  late ValueStream<MediaItem?> currentItem;

  bool playing = false;
  CustomMediaPlayer._() {
    currentItem = ValueConnectableStream(_current.stream);
    status = event.receiveBroadcastStream().map((e) {
      queue = (e["queue"] as List<dynamic>).map((e) {
        return MediaItem(
            id: e["url"],
            title: e["title"] ?? "",
            album: e["album"] ?? "",
            artUri: Uri.file(e["cover"] ?? ""),
            artist: e["artist"] ?? "",
            extras: Map<String, dynamic>.from(e["data"]));
      }).toList();
      return PlayerStatus(
        playing: e["playing"],
        stopped: e["stopped"],
        index: e["index"],
        duration: Duration(seconds: (e["duration"] as double).round()),
        position: Duration(seconds: (e["position"] as double).round()),
        format: e["format"],
        sampleRate: e["sampleRate"],
        bitRate: e["bitRate"],
        volume: e["volume"],
      );
    });
    status.listen((event) {
      playing = event.playing;
      stopped = event.stopped;
      if (playing && index != event.index) {
        index = event.index;
        _current.add(queue[index]);
      }
    });
    update();
  }

  /// the one and only instance of this singleton
  static final instance = CustomMediaPlayer._();

  void next() {
    _next();
    play();
  }

  void previous() async {
    if (index == 0) {
      return;
    }
    index--;
    _previous();
    play();
  }

  Future<void> _replace(MediaItem item) async {
    await clear();
    await platform.invokeMethod("add", {
      "url": item.id,
      "cover": item.artUri?.toString() ?? "",
      "album": item.album ?? "",
      "artist": item.artist ?? "",
      "data": item.extras
    });
    return;
  }

  Future<void> add(MediaItem item) async {
    await platform.invokeMethod("add", {
      "url": item.id,
      "title": item.title,
      "cover": item.artUri?.toString() ?? "",
      "album": item.album ?? "",
      "artist": item.artist ?? "",
      "data": item.extras
    });
    return;
  }

  Future<void> addPlaylist(List<MediaItem> items) async {
    for (var element in items) {
      add(element);
    }
  }

  Future<void> clear() async {
    await platform.invokeMethod("clear", null);
    return;
  }

  Future<void> update() async {
    await platform.invokeMethod("update");
    return;
  }

  Future<void> _next() async {
    await platform.invokeMethod("next");
  }

  Future<void> _previous() async {
    await platform.invokeMethod("previous");
  }

  Future<void> play() async {
    await platform.invokeMethod("play");
    return;
  }

  Future<void> pause() async {
    await platform.invokeMethod("pause");
  }

  Future<void> stop() async {
    await platform.invokeMethod("stop");
  }

  Future<void> seekIndex(int index) async {
    if (index > queue.length - 1) return;
    await platform.invokeMethod("seekIndex", index);
    play();
  }

  Future<void> seek(int second) async {
    await platform.invokeMethod("seek", second);
  }
}

class MacMediaItem {
  String url = "";
  String cover = "";
  String album = "";
  String artist = "";
  Map<String, dynamic> data = {};
}
