import 'dart:ffi';

import 'package:airsonic/airsonicConnection.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AudioHandler> initAudioService() async {
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.mycompany.myapp.audio',
      androidNotificationChannelName: 'Audio Service Demo',
    ),
  );
}

class MyAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);

  //private
  Uri _base = Uri();
  List<String> _segments = [];
  Map<String, dynamic> _param = {};

  late Future<bool> inited;

  Uri _apiEndpointUrl(String ednpoint, {Map<String, String>? query}) {
    Map<String, dynamic> p = Map.from(_param);
    if (query != null) {
      p.addAll(query);
    }
    final a = _base.replace(
        pathSegments: _segments.followedBy([ednpoint]), queryParameters: p);
    print(a.toString());
    return a;
  }

  MyAudioHandler() {
    _loadEmptyPlaylist();
    _listenForDurationChanges();

    //init
    inited = _init();
  }

  Future<bool> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final domain = prefs.getString("domain") ?? "";
    final username = prefs.getString("username") ?? "";
    final token = prefs.getString("token") ?? "";
    final salt = prefs.getString("salt") ?? "";

    if (domain.isEmpty || token.isEmpty || username.isEmpty) {
      throw ("login credentials error");
    }

    _base = Uri.parse(domain);
    _segments = _base.pathSegments.toList();
    _segments.add("rest");
    _param = {
      "u": username,
      "t": token,
      "s": salt,
      "v": "1.15",
      "c": "flutterTest"
    };
    _base = _base.replace(queryParameters: _param);

    return true;
  }

  Future<void> _loadEmptyPlaylist() async {
    try {
      await _player.setAudioSource(_playlist);
    } catch (e) {
      print("Error: $e");
    }
  }

  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      final index = _player.currentIndex;
      final newQueue = queue.value;
      if (index == null || newQueue.isEmpty) return;
      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    });
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    await inited;
    // manage Just Audio
    final audioSource = mediaItems.map(_createAudioSource);
    _playlist.addAll(audioSource.toList());
    // notify system
    final newQueue = queue.value..addAll(mediaItems);
    queue.add(newQueue);
    try {
      await _player.setAudioSource(audioSource.first);
    } catch (e) {
      print(e);
    }
  }

  UriAudioSource _createAudioSource(MediaItem mediaItem) {
    return AudioSource.uri(
      _apiEndpointUrl("stream", query: {"id": mediaItem.id, "format": "mp3"}),
      tag: mediaItem,
    );
  }

  @override
  Future<void> play() async {
    _player.play();

    playbackState.add(PlaybackState(
      // Which buttons should appear in the notification now
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      // Which other actions should be enabled in the notification
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      // Which controls to show in Android's compact view.
      androidCompactActionIndices: const [0, 1, 3],
      // Whether audio is ready, buffering, ...
      processingState: AudioProcessingState.ready,
      // Whether audio is playing
      playing: true,
      // The current position as of this update. You should not broadcast
      // position changes continuously because listeners will be able to
      // project the current position after any elapsed time based on the
      // current speed and whether audio is playing and ready. Instead, only
      // broadcast position updates when they are different from expected (e.g.
      // buffering, or seeking).
      updatePosition: _player.position,
      // The current speed
      speed: 1.0,
      // The current queue position
      queueIndex: 0,
    ));
  }

  @override
  Future<void> pause() async {
    _player.pause();

    playbackState.add(PlaybackState(
      // Which buttons should appear in the notification now
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      // Which other actions should be enabled in the notification
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      // Which controls to show in Android's compact view.
      androidCompactActionIndices: const [0, 1, 3],
      // Whether audio is ready, buffering, ...
      processingState: AudioProcessingState.ready,
      // Whether audio is playing
      playing: false,
      // The current position as of this update. You should not broadcast
      // position changes continuously because listeners will be able to
      // project the current position after any elapsed time based on the
      // current speed and whether audio is playing and ready. Instead, only
      // broadcast position updates when they are different from expected (e.g.
      // buffering, or seeking).
      updatePosition: _player.position,
      // The current speed
      speed: 1.0,
      // The current queue position
      queueIndex: 0,
    ));
  }
}
