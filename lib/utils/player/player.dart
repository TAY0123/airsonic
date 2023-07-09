import 'dart:io';

import 'package:airsonic/utils/native/mediaplayer.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

//this initalizer is for web only
Future<AudioHandler> initAudioService() async {
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

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.status.listen((event) {
      late MediaControl btn;
      bool playing = event.playing;
      if (event.playing) {
        btn = MediaControl.pause;
      } else {
        btn = MediaControl.play;
      }

      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          btn,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[ProcessingState.ready]!,
        playing: playing,
        updatePosition: event.position,
      ));

      final playlist = queue.value;
      if (event.stopped || playlist.isEmpty) return;
      mediaItem.add(playlist[event.index]);

      final newQueue = queue.value;
      if (event.stopped ||
          newQueue.isEmpty ||
          newQueue.length - 1 < event.index) {
        return;
      }
      final oldMediaItem = newQueue[event.index];
      var newMediaItem = oldMediaItem.copyWith(duration: event.duration);
      newMediaItem.extras?["sampleRate"] = event.sampleRate;
      newMediaItem.extras?["bitRate"] = event.bitRate;
      newMediaItem.extras?["format"] = event.format;

      newQueue[event.index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
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
