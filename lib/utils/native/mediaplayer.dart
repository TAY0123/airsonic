import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';

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

  late Stream<PlayerStatus> status;
  var playlist = List<MediaItem>.empty(growable: true);
  var index = 0;
  var stopped = true;

  bool playing = false;
  CustomMediaPlayer._() {
    status = event.receiveBroadcastStream().map((e) => PlayerStatus(
          playing: e["playing"],
          stopped: e["stopped"],
          index: index,
          duration: Duration(seconds: (e["duration"] as double).round()),
          position: Duration(seconds: (e["position"] as double).round()),
          format: e["format"],
          sampleRate: e["sampleRate"],
          bitRate: e["bitRate"],
          volume: e["volume"],
        ));
    status.listen((event) {
      playing = event.playing;
      stopped = event.stopped;
      if (event.stopped && event.playing) {
        next();
      }
    });
    update();
  }

  /// the one and only instance of this singleton
  static final instance = CustomMediaPlayer._();

  void next() {
    if (playlist.length - 1 == index) {
      return;
    }
    index++;
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

  Future<void> clear() async {
    //await platform.invokeMethod("clear", null);
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
    if (index > playlist.length - 1) return;
    this.index = index;
    await add(playlist[index]);
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
