import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:airsonic/airsonic_connection.dart';
import 'package:airsonic/album_info.dart';
import 'package:airsonic/main.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:text_scroll/text_scroll.dart';

import 'a.dart';
import 'after_layout.dart';
import 'const.dart';

//TODO: over 1/4 change to large view
class PlayBackControl extends StatefulWidget {
  const PlayBackControl({super.key});
  @override
  State<PlayBackControl> createState() => _PlayBackControlState();
}

class _PlayBackControlState extends State<PlayBackControl>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double? _height = 60.0;
  var _original = 60.0;
  var _offset = 0.0;
  var _old = 60.0;

  bool opened = false;
  bool playing = false;

  final mp = MediaPlayer.instance;

  MediaItem current = const MediaItem(id: "", title: "");
  Duration pos = Duration.zero;
  Duration duration = Duration.zero;

  late StreamSubscription<MediaItem?> currentItemSubscriber;
  late StreamSubscription<Duration> currentItemPosition;
  late StreamSubscription<PlaybackState> currentStatusSubscriber;

  late Animation _animation;
  bool _animating = false;

  WidgetWithTransition coverImage = WidgetWithTransition();
  WidgetWithTransition progressBar = WidgetWithTransition();
  WidgetWithTransition text = WidgetWithTransition();

  final speed = const Duration(milliseconds: 250);

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

  void _listenToPlayerStatus() async {
    currentStatusSubscriber = (await mp.playerStatus).listen((event) {
      setState(() {
        playing = event.playing;
      });
    });
  }

  void _listenToChangesInSong() async {
    currentItemSubscriber = (await mp.currentItem).listen((mediaItem) {
      setState(() {
        current = mediaItem ?? const MediaItem(id: "", title: "");
        if ((mediaItem?.duration?.inMicroseconds ?? 0) != 0) {
          duration = mediaItem!.duration!;
        }

        coverImage.child = ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: current.artUri != null
                ? Image.file(
                    File.fromUri(current.artUri ?? Uri()),
                    filterQuality: FilterQuality.high,
                  )
                : Container(
                    color: Theme.of(context).primaryColorDark,
                  ));
      });
    });
  }

  void _listenToChangeInPosition() async {
    currentItemPosition = (await mp.currentPosition).listen((event) {
      if (duration.inMilliseconds != 0) {
        setState(() {
          pos = event;
        });
      }
    });
  }

  @override
  void dispose() {
    currentItemSubscriber.cancel();
    currentItemPosition.cancel();
    currentStatusSubscriber.cancel();
    _controller.dispose();
    super.dispose();
  }

  void open() {
    Navigator.of(context).push(TRoute(
      builder: (context) => WillPopScope(
          onWillPop: () async {
            close();
            return true;
          },
          child: Container()),
    ));
  }

  var animationEnded = true;
  var curves = Curves.linear;
  var dragFinish = true;
  double progress = 0.0;

  @override
  Widget build(BuildContext context) {
    var playbackControlButton = Row(
      //full size = 48
      children: [
        IconButton(
            onPressed: () async {
              final player = await mp.futurePlayer;
              player.skipToPrevious();
            },
            icon: const Icon(Icons.skip_previous)),
        Ink(
          decoration: ShapeDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: CircleBorder(),
          ),
          child: IconButton(
              onPressed: () async {
                final player = await mp.futurePlayer;
                if (playing) {
                  player.pause();
                } else {
                  player.play();
                }
              },
              icon: Icon(
                playing ? Icons.play_arrow : Icons.pause,
                color: Theme.of(context).colorScheme.onPrimary,
              )),
        ),
        IconButton(
            onPressed: () async {
              final player = await mp.futurePlayer;
              player.skipToNext();
            },
            icon: const Icon(Icons.skip_next)),
      ],
    );
    text.child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          current.title,
          maxLines: 1,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          current.artist ?? "",
          maxLines: 1,
          style: Theme.of(context).textTheme.bodyLarge,
        )
      ],
    );
    progressBar.child = Column(
      children: [
        SizedBox(
          height: 35,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _playbackProgressBar(context),
          ),
        ),
        Row(
          children: [
            Text(printDuration(pos)),
            const Spacer(
              flex: 3,
            ),
            Text(printDuration(duration - pos))
          ],
        )
      ],
    );
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        alignment: AlignmentDirectional.bottomCenter,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (!animationEnded) {
                return;
              }
              if (!opened) {
                calculateObjectsPosition(constraints);

                _controller.stop();
                setState(() {
                  animationEnded = false;
                  dragFinish = false;
                });
                _controller.duration = speed;
                progress = 0;
                listener() {
                  progress = _animation.value;
                }

                _animation.addListener(listener);

                _controller.forward().then((value) {
                  setState(() {
                    animationEnded = true;
                    dragFinish = true;
                    opened = true;
                    progress = 1;
                  });
                  open();
                  _animation.removeListener(listener);
                });
              }
              setState(() {
                _height = constraints.maxHeight;
              });
            },
            onVerticalDragEnd: (details) {
              setState(() {
                dragFinish = true;
                progress = 1.0;
                _controller.animateTo(progress);
              });
              final screen = constraints.maxHeight;
              if (opened && _offset < 20 && _offset > -20) {
                return;
              } else if (!opened &&
                  (details.velocity.pixelsPerSecond.dy < -1500 ||
                      (_height ?? 0) > constraints.maxHeight / 4)) {
                ///if dragging up and over threshold
                open();
                opened = true;
              } else if (_original > screen / 4 * 3) {
                ///if dragging up and under threshold
              } else if (opened &&
                  (details.velocity.pixelsPerSecond.dy > 1200 ||
                      (_height ?? 0) < (constraints.maxHeight / 5) * 4)) {
                ///if dragging down and over threshold
                Navigator.of(context).pop();
                opened = false;
              } else {
                opened = true;
              }

              ///if dragging down and under threshold

              if (opened) {
                setState(() {
                  _height = constraints.maxHeight;
                });
              } else {
                setState(() {
                  _height = 60;
                });
              }
            },
            onVerticalDragStart: (details) {
              if (!opened) {
                //if not opened request the latest position of the image
                /// the new position will be updated once widget created
                /// so there is no need for update on closing
                calculateObjectsPosition(constraints);
              }
              //prepare image
              if (opened) {
                _controller.reverse();
              } else {
                _controller.forward();
              }
              animationEnded = false;
              setState(() {
                dragFinish = false;
              });
              _original = details.globalPosition.dy;
              _old = _height ?? constraints.maxHeight;
            },
            onVerticalDragUpdate: (details) {
              _offset = _original - details.globalPosition.dy;
              setState(() {
                _height = min(max(60, _old + _offset), constraints.maxHeight);
                progress = (_height! - 60) / (constraints.maxHeight - 60);
              });
            },
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                if (!dragFinish || opened)
                  FractionallySizedBox(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Container(
                      color: Theme.of(context)
                          .colorScheme
                          .background
                          .withOpacity(max(0.4, progress)),
                    ),
                  ),
                //bottomsheet body
                if ((!opened && !dragFinish) || (opened && dragFinish))
                  WillPopScope(
                    onWillPop: () async {
                      Navigator.of(context).pop();
                      return true;
                    },
                    //fullscreen mode
                    child: Opacity(
                      opacity: dragFinish ? 1 : 0,
                      child: Center(
                        child: FractionallySizedBox(
                          widthFactor: 0.9,
                          child: (constraints.maxWidth > breakpointM)
                              ? Column(
                                  children: [
                                    Expanded(
                                        child: Row(
                                      children: [
                                        FloatingActionButton(
                                            onPressed: close,
                                            child: const Icon(Icons.close))
                                      ],
                                    )),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          AspectRatio(
                                              aspectRatio: 1,
                                              child: Center(
                                                child: AfterLayout(
                                                    callback: (value) {
                                                      setState(() {
                                                        coverImage.transition
                                                                .endPoint =
                                                            _getRect(value);
                                                      });
                                                    },
                                                    child: coverImage.child),
                                              )),
                                          const Spacer(),
                                          Expanded(
                                            flex: 4,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 20.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      AfterLayout(
                                                          callback: (value) {
                                                            text.transition
                                                                    .endPoint =
                                                                _getRect(value);
                                                          },
                                                          child: text.child!)
                                                    ],
                                                  ),
                                                  const Spacer(),
                                                  //media control on full screen
                                                  playbackControlButton,
                                                  //progress bar
                                                  AfterLayout(
                                                      callback: (value) {
                                                        progressBar.transition
                                                                .endPoint =
                                                            _getRect(value);
                                                      },
                                                      child:
                                                          progressBar.child!),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        children: const [],
                                      ),
                                    )
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Row(
                                          children: [
                                            FloatingActionButton(
                                                onPressed: close,
                                                child: const Icon(Icons.close))
                                          ],
                                        ),
                                      ),
                                      Spacer(
                                        flex: 1,
                                      ),
                                      AspectRatio(
                                          aspectRatio: 1,
                                          child: Center(
                                            child: AfterLayout(
                                                callback: (value) {
                                                  setState(() {
                                                    coverImage.transition
                                                            .endPoint =
                                                        _getRect(value);
                                                  });
                                                },
                                                child: coverImage.child),
                                          )),
                                      AfterLayout(
                                          callback: (value) {
                                            text.transition.endPoint =
                                                _getRect(value);
                                          },
                                          child: text.child!),
                                      Spacer(
                                        flex: 4,
                                      ),
                                      playbackControlButton,
                                      AfterLayout(
                                          callback: (value) {
                                            progressBar.transition.endPoint =
                                                _getRect(value);
                                          },
                                          child: progressBar.child!),
                                      Spacer(),
                                    ]),
                        ),
                      ),
                    ),
                  )
                else
                  Opacity(
                    opacity: dragFinish ? 1 : 0,
                    //opacity: 1,
                    child: Container(
                      color: Theme.of(context).colorScheme.background,
                      child: (constraints.maxWidth > breakpointM)
                          ? Padding(
                              padding:
                                  const EdgeInsets.only(left: 10, right: 10),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    maxHeight: 60,
                                    maxWidth:
                                        MediaQuery.of(context).size.width),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 8, bottom: 8, right: 8),
                                      child:
                                          //Cover Image

                                          AfterLayout(
                                              callback: (value) {
                                                coverImage.transition.startObj =
                                                    value;

                                                ///trigger refresh position when exit from fulscreen
                                                coverImage
                                                        .transition.startPoint =
                                                    _getRect(value);
                                              },
                                              child: AspectRatio(
                                                  aspectRatio: 1,
                                                  child: Hero(
                                                      tag: "ccc",
                                                      child: coverImage.child ??
                                                          Container()))),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: AfterLayout(
                                        callback: (value) {
                                          text.transition.startObj = value;
                                          text.transition.startPoint =
                                              _getRect(value);
                                        },
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            TextScroll(
                                              current.title,
                                              pauseBetween:
                                                  const Duration(seconds: 5),
                                              velocity: const Velocity(
                                                  pixelsPerSecond:
                                                      Offset(20, 0)),
                                            ),
                                            TextScroll(
                                              current.artist ?? "",
                                              pauseBetween:
                                                  const Duration(seconds: 5),
                                              velocity: const Velocity(
                                                  pixelsPerSecond:
                                                      Offset(20, 0)),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 15,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 8.0, right: 8),
                                        child: AfterLayout(
                                            callback: (value) {
                                              progressBar.transition.startObj =
                                                  value;
                                              progressBar.transition
                                                  .startPoint = _getRect(value);
                                            },
                                            child: progressBar.child),
                                      ),
                                    ),
                                    playbackControlButton,
                                  ],
                                ),
                              ),
                            )
                          : ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxHeight: 62,
                                  maxWidth: MediaQuery.of(context).size.width),
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: AfterLayout(
                                        callback: (value) {
                                          progressBar.transition.startObj =
                                              value;
                                          progressBar.transition.startPoint =
                                              _getRect(value);
                                        },
                                        child: _playbackProgressBar(context)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 10, right: 10),
                                    child: Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 10, bottom: 8, right: 8),
                                          child:
                                              //Cover Image

                                              AfterLayout(
                                                  callback: (value) {
                                                    coverImage.transition
                                                        .startObj = value;

                                                    ///trigger refresh position when exit from fulscreen
                                                    coverImage.transition
                                                            .startPoint =
                                                        _getRect(value);
                                                  },
                                                  child: AspectRatio(
                                                      aspectRatio: 1,
                                                      child: Hero(
                                                          tag: "ccc",
                                                          child: coverImage
                                                                  .child ??
                                                              Container()))),
                                        ),
                                        Expanded(
                                          flex: 18,
                                          child: AfterLayout(
                                            callback: (value) {
                                              text.transition.startObj = value;
                                              text.transition.startPoint =
                                                  _getRect(value);
                                            },
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                TextScroll(
                                                  current.title,
                                                  pauseBetween: const Duration(
                                                      seconds: 5),
                                                  velocity: const Velocity(
                                                      pixelsPerSecond:
                                                          Offset(20, 0)),
                                                ),
                                                TextScroll(
                                                  current.artist ?? "",
                                                  pauseBetween: const Duration(
                                                      seconds: 5),
                                                  velocity: const Velocity(
                                                      pixelsPerSecond:
                                                          Offset(20, 0)),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        playbackControlButton,
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),

          //pre-render layout to calculate position for transit

          //transit position
          if (!dragFinish)
            IgnorePointer(
              child: Center(
                child: Stack(
                  children: [
                    //cover image while transit
                    AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          //求出 rect 插值
                          // 通过 Positioned 设置组件大小和位置
                          return Positioned.fromRect(
                              rect: coverImage.transition
                                  .position(progress: progress)!,
                              child: child!);
                        },
                        child: coverImage.child),
                    //progress bar

                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Positioned.fromRect(
                            rect: progressBar.transition
                                .position(progress: progress)!,
                            child: progressBar.child!);
                      },
                      child: _playbackProgressBar(context),
                    ),
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Positioned.fromRect(
                            rect: text.transition.position(progress: progress)!,
                            child: text.child!);
                      },
                      child: _playbackProgressBar(context),
                    )
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }

  void calculateObjectsPosition(BoxConstraints constraints) {
    coverImage.transition.startPoint =
        _getRect(coverImage.transition.startObj!);
    coverImage.transition.startPointFlipY(constraints.maxHeight);

    progressBar.transition.startPoint =
        _getRect(progressBar.transition.startObj!);
    progressBar.transition.startPointFlipY(constraints.maxHeight);

    text.transition.startPoint = _getRect(text.transition.startObj!);
    text.transition.startPointFlipY(constraints.maxHeight);
  }

  void close() {
    Navigator.of(Navi!.currentContext!).pop();
    _controller.stop();
    setState(() {
      animationEnded = false;
      dragFinish = false;
    });
    _controller.duration = speed;
    progress = 0;
    listener() {
      progress = _animation.value;
    }

    _animation.addListener(listener);

    _controller.reverse().then((value) {
      setState(() {
        animationEnded = true;
        dragFinish = true;
        opened = false;
        _height = 60;
      });
      _animation.removeListener(listener);
    });
  }

  //TODO: calculate a progress for how much to finish fading background and pos transit

  SliderTheme _playbackProgressBar(BuildContext context) {
    return SliderTheme(
        data: SliderThemeData(
            minThumbSeparation: 0,
            overlayColor: Colors.transparent,
            overlayShape: SliderComponentShape.noOverlay,
            activeTrackColor: Theme.of(context).primaryColorLight,
            thumbShape: SliderComponentShape.noThumb),
        child: Slider(
          value: min(pos.inMilliseconds.toDouble(),
              duration.inMilliseconds.toDouble()),
          label: printDuration(pos),
          onChanged: (value) {},
          min: 0,
          max: duration.inMilliseconds.toDouble(),
        ));
  }

  Rect _getRect(RenderAfterLayout renderAfterLayout) {
    //我们需要获取的是AfterLayout子组件相对于Stack的Rect

    return renderAfterLayout.localToGlobal(
          Offset.zero,
          //找到Stack对应的 RenderObject 对象
          ancestor: context.findRenderObject(),
        ) &
        renderAfterLayout.size;
  }
}

class TransitionPosition {
  Rect? startPoint;
  Rect? endPoint;
  RenderAfterLayout? startObj;

  Rect? position({double? progress}) {
    return Rect.lerp(startPoint, endPoint, progress ?? 1);
  }

  void startPointFlipY(double height) {
    startPoint =
        startPoint?.translate(0, height - startPoint!.top - startPoint!.bottom);
  }
}

class WidgetWithTransition {
  Widget? child;
  TransitionPosition transition = TransitionPosition();
}
