import 'package:audio_service/audio_service.dart';
import 'package:dart_vlc/dart_vlc.dart' as vlc;
import 'package:shared_preferences/shared_preferences.dart';

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
    print(a.toString());
    return a;
  }

  VlcAudioHandler() {
    _listenForDurationChanges();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForCurrentSongIndexChanges();

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
      "c": "flutsonic"
    };
    _base = _base.replace(queryParameters: _param);

    return true;
  }

  Future<void> _loadEmptyPlaylist() async {
    try {
      _player.open(_playlist);
    } catch (e) {
      print("Error: $e");
    }
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
      _apiEndpointUrl("stream", query: {"id": mediaItem.id, "format": "raw"}),
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
