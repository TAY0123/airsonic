import 'dart:developer';
import 'dart:io';

import 'package:airsonic/utils/native/mediaplayer.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

//this initalizer is for web only
Future<AudioHandler> initAppleAudioService() async {
  if (Platform.isMacOS) {
    return MyAudioHandler();
  } else {
    return await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.mycompany.myapp.audio',
        androidNotificationChannelName: 'Audio Service Demo',
      ),
    );
  }
}

//TODO: prev info not correct
// this handler work for iOS macOS Android
class MyAudioHandler extends BaseAudioHandler {
  //final _player = AudioPlayer();
  final _player = CustomMediaPlayer.instance;

  MyAudioHandler() {
    _player.status.listen((event) {
      playbackState.add(PlaybackState(
          playing: event.playing, updatePosition: event.position));

      final playlist = _player.queue;
      if (event.stopped || playlist.isEmpty) return;
      if (_player.currentItem.hasValue) {
        inspect(_player.currentItem.value);
        mediaItem.add(_player.currentItem.value);
      }
      queue.add(_player.queue);
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
    print(mediaItem);
    _player.add(mediaItem);
  }

  @override
  // ignore: avoid_renaming_method_parameters
  Future<void> updateQueue(List<MediaItem> mediaItems) async {
    //clear playlist
    print(mediaItems.length);
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
