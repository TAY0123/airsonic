import 'dart:io';

import 'package:airsonic/player.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:dart_vlc/dart_vlc.dart' as vlc;
import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AudioHandler> initAudioService() async {
  if (Platform.isIOS || Platform.isMacOS) {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }
  if ((Platform.isWindows || Platform.isLinux) && !kIsWeb) {
    return await AudioService.init(
      builder: () => VlcAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.mycompany.myapp.audio',
        androidNotificationChannelName: 'Audio Service Demo',
      ),
    );
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

class VlcAudioHandler extends BaseAudioHandler {
  final _player = vlc.Player(
    id: 69420,
    commandlineArguments: ['--no-video'],
  );
  var _playlist = vlc.Playlist(medias: []);

  //private
  Uri _base = Uri();
  List<String> _segments = [];
  Map<String, dynamic> _param = {};

  int index = 0;

  late Future<bool> inited;

  Uri _apiEndpointUrl(String ednpoint, {Map<String, String>? query}) {
    Map<String, dynamic> p = Map.from(_param);
    if (query != null) {
      p.addAll(query);
    }
    final a = _base.replace(
        pathSegments: _segments.followedBy([ednpoint]), queryParameters: p);
    return a;
  }

  VlcAudioHandler() {
    DartVLC.initialize();
    HardwareKeyboard.instance.addHandler(_mediakeyHandler);
    _listenForDurationChanges();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForCurrentSongIndexChanges();

    //init
    inited = _init();
  }

  bool _mediakeyHandler(KeyEvent e) {
    if (e is KeyDownEvent) {
      switch (e.logicalKey.keyId) {
        case 4294969861: //play pause
          _player.playOrPause();
          break;
        case 176:
          skipToNext();
          break;
        case 177:
          skipToPrevious();
          break;
        default:
      }
    }
    return false;
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
      "c": "flutsonic"
    };
    _base = _base.replace(queryParameters: _param);

    return true;
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackStream.listen((vlc.PlaybackState state) {
      final playing = state.isPlaying;
      state.isSeekable;
      state.isCompleted;

      playbackState.add(playbackState.value.copyWith(
        playing: playing,
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
        },
      ));
    });
    _player.currentStream.listen((event) {
      playbackState.add(playbackState.value.copyWith(
        queueIndex: event.index,
      ));

      index = event.index ?? 0;
    });
  }

  void _listenForDurationChanges() {
    //update position and duration
    _player.positionStream.listen((vlc.PositionState state) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: state.position ?? const Duration(seconds: 0),
      ));
      final newQueue = queue.value;
      if (newQueue.isEmpty) {
        return;
      }
      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: state.duration);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    });
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    /*
    await inited;
    // manage Just Audio
    final audioSource = mediaItems.map(_createAudioSource);
    _playlist.addAll(audioSource.toList());
    // notify system
    final newQueue = queue.value..addAll(mediaItems);
    //final newQueue = mediaItems;
    queue.add(newQueue);
    _player.load();
    */
    await inited;
    // manage Just Audio
    final audioSource = mediaItems.map(_createAudioSource);
    //clear playlist
    _playlist = vlc.Playlist(medias: audioSource.toList());
    _player.open(_playlist);
    // notify system
    //final newQueue = queue.value..addAll(mediaItems);
    final newQueue = mediaItems;
    queue.add(newQueue);
  }

  @override
  Future<void> updateQueue(List<MediaItem> mediaItems) async {
    await inited;
    // manage Just Audio
    final audioSource = mediaItems.map(_createAudioSource);
    //clear playlist
    _playlist = vlc.Playlist(medias: audioSource.toList());
    _player.open(_playlist);
    // notify system
    //final newQueue = queue.value..addAll(mediaItems);
    final newQueue = mediaItems;
    queue.add(newQueue);
  }

  vlc.Media _createAudioSource(MediaItem mediaItem) {
    return vlc.Media.network(
      _apiEndpointUrl("stream", query: {"id": mediaItem.id, "format": "flac"}),
    );
  }

  void _listenForCurrentSongIndexChanges() {
    _player.currentStream.listen((index) {
      final playlist = queue.value;
      if (index == null || playlist.isEmpty) return;
      print(playlist[index.index ?? 0].artUri);
      mediaItem.add(playlist[index.index ?? 0]);
    });
  }

  @override
  Future<void> play() async {
    _player.play();
  }

  @override
  Future<void> pause() async {
    _player.pause();
  }

  @override
  Future<void> skipToNext() async {
    _player.next();
  }

  @override
  Future<void> skipToPrevious() async {
    _player.previous();
  }

  @override
  Future<void> seek(Duration position) async {
    _player.seek(position);
  }
}
