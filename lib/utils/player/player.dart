import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);

  MyAudioHandler() {
    _loadEmptyPlaylist();
    _listenForDurationChanges();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForCurrentSongIndexChanges();
  }

  Future<void> _loadEmptyPlaylist() async {
    try {
      await _player.setAudioSource(_playlist);
    } catch (e) {
      print("Error: $e");
    }
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playerStateStream.listen((event) {
      print(event.processingState.name);
      late MediaControl btn;
      bool playing = event.playing;
      if (event.processingState == ProcessingState.completed) {
        playing = false;
      }
      if (!event.playing) {
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
        }[event.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ));
    });
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
  }

  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      final index = _player.currentIndex;
      final newQueue = queue.value;
      if (index == null || newQueue.isEmpty || newQueue.length - 1 < index)
        return;
      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    });
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    // manage Just Audio
    List<UriAudioSource> audioSource = [];
    for (final e in mediaItems) {
      final c = await _createAudioSource(e);
      audioSource.add(c);
    }
    await _playlist.addAll(audioSource.toList());
    // notify system
    final newQueue = queue.value..addAll(mediaItems);
    //final newQueue = mediaItems;
    queue.add(newQueue);
    try {
      await _player.load();
    } catch (e) {
      print(e);
    }
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    // manage Just Audio
    await _playlist.add(await _createAudioSource(mediaItem));
    // notify system
    final newQueue = queue.value..add(mediaItem);
    //final newQueue = mediaItems;
    queue.add(newQueue);
    try {
      await _player.load();
    } catch (e) {
      print(e);
    }
  }

  @override
  // ignore: avoid_renaming_method_parameters
  Future<void> updateQueue(List<MediaItem> mediaItems) async {
    // manage Just Audio
    List<UriAudioSource> audioSource = [];
    for (final e in mediaItems) {
      final c = await _createAudioSource(e);
      audioSource.add(c);
    }
    //clear playlist
    await _playlist.clear();
    await _playlist.addAll(audioSource);
    // notify system
    //final newQueue = queue.value..addAll(mediaItems);
    final newQueue = mediaItems;
    queue.add(newQueue);
    try {
      await _player.load();
    } catch (e) {
      print(e);
    }
  }

  Future<UriAudioSource> _createAudioSource(MediaItem mediaItem) async {
    return AudioSource.uri(
      Uri.parse(mediaItem.id),
      tag: mediaItem,
    );
  }

  void _listenForCurrentSongIndexChanges() {
    _player.currentIndexStream.listen((index) {
      final playlist = queue.value;
      if (index == null || playlist.isEmpty) return;
      mediaItem.add(playlist[index]);
    });
  }

  @override
  Future<void> play() async {
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }
    _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> skipToNext() async {
    await _player.seekToNext();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    await _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> stop() async {
    if (_player.playing) {
      await _player.stop();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.seekToPrevious();
    if (_player.processingState == ProcessingState.completed) {
      await play();
    }
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);
}
