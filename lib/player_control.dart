import 'dart:async';
import 'dart:ffi';

import 'package:airsonic/pages/splitview.dart';
import 'package:airsonic/utils/airsonic_connection.dart';
import 'package:airsonic/layout.dart';
import 'package:airsonic/widgets/card.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

//TODO: over 1/4 change to large view
class PlayBackControl extends StatefulWidget {
  const PlayBackControl({super.key});
  @override
  State<PlayBackControl> createState() => _PlayBackControlState();
}

class _PlayBackControlState extends State<PlayBackControl>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  bool opened = false;
  bool playing = false;

  final mp = MediaPlayer.instance;

  Duration pos = Duration.zero;
  Duration duration = Duration.zero;

  ValueStream<MediaItem?>? currentItemSubscriber;
  Stream<Duration>? currentItemPosition;
  late StreamSubscription<PlaybackState> currentStatusSubscriber;

  late Animation _animation;
  late AnimationController _barController;
  bool _animating = false;

  final speed = const Duration(milliseconds: 250);

  late Animation<double> _playBtn;

  late Animation<double> _playbackBar;

  @override
  void initState() {
    super.initState();
    _listenToChangesInSong();
    _listenToChangeInPosition();
    _listenToPlayerStatus();
    _controller = AnimationController(vsync: this, duration: speed);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _playBtn = _animation.drive(Tween(begin: 1, end: 0));

    _barController = AnimationController(vsync: this);
    _playbackBar = _barController.drive(Tween(begin: 0, end: 1));

    _controller.addListener(() {
      if (_controller.isCompleted || _controller.isDismissed) {
        setState(() {
          animationEnded = true;
        });
        if (_animating) {
          setState(() {
            _animating = false;
          });
        }
      } else {}
    });
  }

  Future<void> init() async {
    currentItemSubscriber = (await mp.currentItem);
    currentItemSubscriber?.listen((event) {
      if (event?.duration != null && event?.duration?.inMilliseconds != 0) {
        _barController.duration = event?.duration!;
        () async {
          final current = await currentItemPosition?.first;
          if (current != null) {
            final progress =
                current.inMilliseconds / event!.duration!.inMilliseconds;
            _barController.forward(from: progress);
          }
        }();
      }
    });
    currentItemPosition = (await mp.currentPosition);
  }

  void _listenToPlayerStatus() async {
    currentStatusSubscriber = (await mp.playerStatus).listen((event) {
      playing = event.playing;
      if (event.playing) {
        _controller.reverse();
        //start animation
        () async {
          final current = await currentItemPosition?.first;
          if (current != null && _barController.duration != null) {
            final progress = current.inMilliseconds /
                _barController.duration!.inMilliseconds;
            _barController.forward(from: progress);
          }
        }();
      } else {
        _controller.forward();
        _barController.stop();
      }
    });
  }

  void _listenToChangesInSong() async {}

  void _listenToChangeInPosition() async {}

  @override
  void dispose() {
    currentStatusSubscriber.cancel();
    _controller.dispose();
    _barController.dispose();
    super.dispose();
  }

  var animationEnded = true;
  var curves = Curves.linear;
  var dragFinish = true;
  double progress = 0.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final bar = Stack(
      children: [
        AnimatedBuilder(
            animation: _playbackBar,
            builder: (context, child) => FractionallySizedBox(
                  widthFactor: _playbackBar.value,
                  child: Container(
                    color: colorScheme.primaryContainer,
                  ),
                )),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: StreamBuilder(
            stream: currentItemSubscriber,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.requireData != null) {
                final current = snapshot.requireData!;
                return Row(
                  children: [
                    CoverImage(
                      current.extras?["coverArt"] ?? "",
                      size: ImageSize.avatar,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            current.title,
                            style: textTheme.bodyMedium,
                          ),
                          Text(
                            current.album ?? "",
                            style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onPrimaryContainer),
                          ),
                          Text(
                            current.artist ?? "",
                            style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onPrimaryContainer),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    IconButton(
                        onPressed: () async {
                          final p = await mp.futurePlayer;
                          if (playing) {
                            p.pause();
                          } else {
                            p.play();
                          }
                        },
                        icon: AnimatedIcon(
                            icon: AnimatedIcons.play_pause,
                            progress: _playBtn)),
                    Padding(padding: EdgeInsets.all(4)),
                  ],
                );
              } else {
                return Container();
              }
            },
          ),
        ),
      ],
    );

    return FutureBuilder(
      future: init(),
      builder: (context, snapshot) =>
          SizedBox(height: bottomHeight, child: bar),
    );
  }
}
