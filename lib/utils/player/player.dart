import 'package:airsonic/utils/native/mediaplayer.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

//this initalizer is for web only
Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.mycompany.myapp.audio',
      androidNotificationChannelName: 'Audio Service Demo',
    ),
  );
}

//TODO: prev info not correct
// this handler work for iOS macOS Android
class MyAudioHandler extends BaseAudioHandler {
  //final _player = AudioPlayer();
  final _player = CustomMediaPlayer.instance;

  MyAudioHandler() {
    _loadEmptyPlaylist();
    _listenForDurationChanges();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForCurrentSongIndexChanges();
  }

  Future<void> _loadEmptyPlaylist() async {
    try {
      //await _player.setAudioSource(_playlist);
    } catch (e) {
      print("Error: $e");
    }
  }

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
    /*
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
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
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    });
    */
  }

  void _listenForDurationChanges() {
    /*
    _player.durationStream.listen((duration) {
      final index = _player.currentIndex;
      final newQueue = queue.value;
      if (index == null || newQueue.isEmpty || newQueue.length - 1 < index) {
        return;
      }
      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    });
    */
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    // manage Just Audio
    /*
    List<UriAudioSource> audioSource = [];
    for (final e in mediaItems) {
      final c = _createAudioSource(e);
      audioSource.add(c);
    }
    */
    final source = mediaItems.map((e) => e.id);
    _player.playlist.addAll(source);
    // notify system
    final newQueue = queue.value..addAll(mediaItems);
    //final newQueue = mediaItems;
    queue.add(newQueue);
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    // manage Just Audio
    _player.playlist.add(mediaItem.id);
    // notify system
    final newQueue = queue.value..add(mediaItem);
    //final newQueue = mediaItems;
    queue.add(newQueue);
  }

  @override
  // ignore: avoid_renaming_method_parameters
  Future<void> updateQueue(List<MediaItem> mediaItems) async {
    // manage Just Audio
    /*
    List<UriAudioSource> audioSource = [];
    for (final e in mediaItems) {
      final c = _createAudioSource(e);
      audioSource.add(c);
    }
    */

    //clear playlist
    _player.playlist.clear();
    _player.playlist.addAll(mediaItems.map((e) => e.id));
    // notify system
    //final newQueue = queue.value..addAll(mediaItems);
    final newQueue = mediaItems;
    queue.add(newQueue);
  }

  void _listenForCurrentSongIndexChanges() {
    /*
    _player.currentIndexStream.listen((index) {
      final playlist = queue.value;
      if (index == null || playlist.isEmpty) return;
      mediaItem.add(playlist[index]);
    });
    */
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
