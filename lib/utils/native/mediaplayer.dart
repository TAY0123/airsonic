import 'dart:async';

import 'package:flutter/services.dart';

class PlayerStatus {
  bool playing;
  Duration position;
  Duration duration;

  PlayerStatus(
      {this.playing = false,
      this.duration = Duration.zero,
      this.position = Duration.zero});
}

class CustomMediaPlayer {
  static const platform = MethodChannel('samples.flutter.dev/mediaplayer');
  static const event = EventChannel("samples.flutter.dev/mediaplayerStatus");

  bool playing = false;
  CustomMediaPlayer() {
    event.receiveBroadcastStream().listen((event) {
      playing = event["playing"];
    });
  }

  Stream<PlayerStatus> status() {
    return event.receiveBroadcastStream().map((e) => PlayerStatus(
          playing: e["playing"],
          duration: Duration(seconds: (e["duration"] as double).round()),
          position: Duration(seconds: (e["position"] as double).round()),
        ));
  }

  Future<void> play(String url) async {
    await platform.invokeMethod("play", url);
    return;
  }

  Future<void> pause() async {
    await platform.invokeMethod("pause");
  }

  Future<void> stop() async {
    await platform.invokeMethod("stop");
  }

  Future<void> seek(int second) async {
    await platform.invokeMethod("seek", second);
  }
}
