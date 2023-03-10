import 'dart:async';
import 'dart:ffi';
import 'dart:math';

import 'package:airsonic/pages/splitview.dart';
import 'package:airsonic/utils/airsonic_connection.dart';
import 'package:airsonic/layout.dart';
import 'package:airsonic/utils/utils.dart';
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

  final speed = const Duration(milliseconds: 250);

  late Animation _animation;
  late AnimationController _barController;
  bool _animating = false;

  late Animation<double> _playBtn;
  late Animation<double> _playbackBar;
  bool _dragging = false;

  Duration seekTo = Duration.zero;

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

  void updateProgressBar() async {
    if (_dragging) {
      return;
    }
    final current = await currentItemPosition?.first;
    if (current != null && _barController.duration != null) {
      final progress =
          current.inMilliseconds / _barController.duration!.inMilliseconds;
      _barController.forward(from: progress);
    }
  }

  Future<void> init() async {
    currentItemSubscriber = (await mp.currentItem);
    currentItemSubscriber?.listen((event) {
      if (event?.duration != null && event?.duration?.inMilliseconds != 0) {
        _barController.duration = event?.duration!;
        updateProgressBar();
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
        updateProgressBar();
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
        if (_dragging)
          Center(
              child: FilledButton(
            onPressed: null,
            child: Text(printDuration(seekTo)),
          ))
      ],
    );

    return FutureBuilder(
        future: init(),
        builder: (context, snapshot) => SizedBox(
            height: bottomHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragStart: (details) {
                      _barController.stop();
                      setState(() {
                        _dragging = true;
                      });
                    },
                    onHorizontalDragCancel: () {
                      _dragging = false;
                      updateProgressBar();
                    },
                    onHorizontalDragUpdate: (details) {
                      final ratio = max<double>(
                          0,
                          min<double>(1,
                              details.localPosition.dx / constraints.maxWidth));
                      if (_barController.duration != null) {
                        setState(() {
                          seekTo = Duration(
                              milliseconds:
                                  (_barController.duration!.inMilliseconds *
                                          ratio)
                                      .round());
                        });
                      }

                      _barController.animateTo(ratio, duration: Duration.zero);
                    },
                    onHorizontalDragEnd: (details) async {
                      setState(() {
                        _dragging = false;
                      });
                      final p = await mp.futurePlayer;
                      p.seek(seekTo);
                      updateProgressBar();
                    },
                    child: bar);
              },
            )));
  }
}
