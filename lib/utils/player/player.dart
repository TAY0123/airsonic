import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:airsonic/utils/native/mediaplayer.dart';
import 'package:airsonic/utils/utils.dart';

//this initalizer is for web only
NativeAudioHandler initAppleAudioService() {
  if (Platform.isMacOS) {
    return NativeAudioHandler();
  } else {
    throw "Unsupported platform";
  }
}

//TODO: prev info not correct
// this handler work for iOS macOS Android
class NativeAudioHandler {
  final _player = CustomMediaPlayer.instance;

  final StreamController<PlayerStatus> status = StreamController();

  NativeAudioHandler() {
    _player.status.listen((event) {
      status.add(event);
      final playlist = _player.queue.valueOrNull;
      if (event.stopped || playlist == null || playlist.isEmpty) return;
      if (_player.currentItem.hasValue) {
        inspect(_player.currentItem.value);
        //mediaItem.add(_player.currentItem.value);
      }
      //queue.add(_player.queue);
    });
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    for (var element in mediaItems) {
      _player.add(element);
    }
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    inspect(mediaItem);
    _player.add(mediaItem);
  }

  @override
  // ignore: avoid_renaming_method_parameters
  Future<void> updateQueue(List<MediaItem> mediaItems) async {
    //clear playlist
    inspect(mediaItems.length);
    _player.clear();
    for (var element in mediaItems) {
      _player.add(element);
    }
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> skipToNext() async {
    _player.next();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    await _player.seekIndex(index);
  }

  @override
  Future<void> stop() async {
    if (_player.playing) {
      await _player.stop();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    _player.previous();
    /*
    await _player.seekToPrevious();
    if (_player.processingState == ProcessingState.completed) {
      await play();
    }
    */
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position.inSeconds);
}
