import 'dart:async';
import 'dart:math';

import 'package:airsonic/pages/splitview.dart';
import 'package:airsonic/utils/airsonic_connection.dart';
import 'package:airsonic/utils/localdiscovery.dart';
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
  late AnimationController _playBtnController;

  bool playing = false;

  final mp = MediaPlayer.instance;

  ValueStream<MediaItem?>? currentItemSubscriber;
  Stream<Duration>? currentItemPosition;
  late StreamSubscription<PlaybackState> currentStatusSubscriber;

  final speed = const Duration(milliseconds: 250);

  late AnimationController _barController;

  final ValueNotifier<bool> _dragging = ValueNotifier(false);

  Duration seekTo = Duration.zero;

  late Animation<double> _playBtn;
  late Animation<double> _playbackBar;

  @override
  void initState() {
    super.initState();
    _listenToChangesInSong();
    _listenToChangeInPosition();
    _listenToPlayerStatus();

    _playBtnController = AnimationController(vsync: this, duration: speed);
    _dragging.value = false;

    final playBtnanimation = CurvedAnimation(
      parent: _playBtnController,
      curve: Curves.easeInOutCubic,
    );

    _playBtn = playBtnanimation.drive(Tween(begin: 1, end: 0));

    _barController = AnimationController(vsync: this);
    _playbackBar = _barController.drive(Tween(begin: 0, end: 1));
  }

  @override
  void dispose() {
    currentStatusSubscriber.cancel();
    _playBtnController.dispose();
    _barController.dispose();
    _dragging.dispose();
    super.dispose();
  }

  void updateProgressBar() async {
    if (_dragging.value) {
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
        _playBtnController.reverse();
        //start animation
        updateProgressBar();
      } else {
        _playBtnController.forward();
        _barController.stop();
      }
    });
  }

  void _listenToChangesInSong() async {}

  void _listenToChangeInPosition() async {}

  var animationEnded = true;
  var curves = Curves.linear;
  var dragFinish = true;
  double progress = 0.0;
  double pos = 0.0;

  //param
  var startPt = 0.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder(
        future: init(),
        builder: (context, snapshot) => SizedBox(
            height: bottomHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  //horizontal gesture
                  onHorizontalDragStart: (details) {
                    startPt = constraints.maxWidth * _barController.value;
                    _barController.stop();
                    _dragging.value = true;

                    pos = details.localPosition.dx;
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
                  onHorizontalDragCancel: () {
                    _dragging.value = false;
                    updateProgressBar();
                  },
                  onHorizontalDragUpdate: (details) {
                    pos = details.localPosition.dx;
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
                    _dragging.value = false;
                    if (pos - startPt > 2 || pos - startPt < -2) {
                      final p = await mp.futurePlayer;
                      p.seek(seekTo);
                    } else {
                      return;
                    }

                    updateProgressBar();
                  },
                  //vertical gesture
                  onVerticalDragEnd: (details) async {
                    if (details.velocity.pixelsPerSecond.dy < -10) {
                      final p = await mp.futurePlayer;
                      p.skipToNext();
                    } else if (details.velocity.pixelsPerSecond.dy > 10) {
                      final p = await mp.futurePlayer;
                      p.skipToPrevious();
                    }
                  },
                  child: Stack(
                    children: [
                      AnimatedBuilder(
                        animation: _playbackBar,
                        builder: (context, child) => FractionallySizedBox(
                          widthFactor: _playbackBar.value,
                          child: Container(
                            color: colorScheme.primaryContainer,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 8, right: 8, top: 4.0, bottom: 4),
                        child: StreamBuilder(
                          stream: currentItemSubscriber,
                          builder: (context, snapshot) {
                            if (snapshot.hasData &&
                                snapshot.requireData != null) {
                              final current = snapshot.requireData!;
                              final info1 = current.album ?? "";
                              final info2 = current.extras?["format"] ?? "";
                              final info4 =
                                  "${current.extras?["sampleRate"] ?? ""}";
                              String cinfo = info1;
                              var dinfo = current.artist ?? "";

                              switchlayout(Widget? currentChild,
                                  List<Widget> previousChildren) {
                                final prev = previousChildren
                                    .map(
                                      (e) => Align(
                                        alignment: Alignment.centerLeft,
                                        child: e,
                                      ),
                                    )
                                    .toList();
                                prev.add(Align(
                                  alignment: Alignment.centerLeft,
                                  child: currentChild,
                                ));
                                return Stack(
                                  children: prev,
                                );
                              }

                              return Row(
                                children: [
                                  CoverImage(
                                    current.extras?["coverArt"] ?? "",
                                    size: ImageSize.avatar,
                                    topLeft: const Radius.circular(5),
                                    topRight: const Radius.circular(5),
                                    bottomLeft: const Radius.circular(5),
                                    bottomRight: const Radius.circular(5),
                                  ),
                                  Flexible(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 4.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          AnimatedSwitcher(
                                            layoutBuilder: switchlayout,
                                            duration: const Duration(
                                                milliseconds: 250),
                                            child: Text(
                                              current.title,
                                              key: ValueKey<String>(
                                                  current.title),
                                              style: textTheme.bodyMedium,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          AnimatedSwitcher(
                                            layoutBuilder: switchlayout,
                                            duration: const Duration(
                                                milliseconds: 250),
                                            child: Text(
                                              cinfo,
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                      color: colorScheme
                                                          .onPrimaryContainer),
                                              key: ValueKey<String>(cinfo),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          AnimatedSwitcher(
                                            layoutBuilder: switchlayout,
                                            duration: const Duration(
                                                milliseconds: 250),
                                            child: Text(
                                              dinfo,
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                      color: colorScheme
                                                          .onPrimaryContainer),
                                              key: ValueKey<String>(dinfo),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: IconButton(
                                        onPressed: () {
                                          final c = LocalDiscovery.instance;
                                          c.scan();
                                          showDialog(
                                            context: context,
                                            barrierColor: Colors.transparent,
                                            builder: (context) {
                                              return Dialog(
                                                alignment: AlignmentDirectional
                                                    .bottomEnd,
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 240,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        ListTile(
                                                          title:
                                                              Text("Devices:"),
                                                        ),
                                                        Flexible(
                                                          child: StreamBuilder(
                                                            stream: c
                                                                .devices.stream,
                                                            builder: (context,
                                                                snapshot) {
                                                              if (snapshot
                                                                  .hasData) {
                                                                return ListView(
                                                                  children: snapshot
                                                                      .requireData
                                                                      .map((e) =>
                                                                          ListTile(
                                                                            title:
                                                                                Text(e.name ?? ""),
                                                                            onTap:
                                                                                () {
                                                                              c.send(current, e);
                                                                            },
                                                                          ))
                                                                      .toList(),
                                                                );
                                                              } else {
                                                                return Placeholder();
                                                              }
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                        icon: Icon(Icons.share)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: IconButton(
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
                                  ),
                                  const Padding(padding: EdgeInsets.all(4)),
                                ],
                              );
                            } else {
                              return Container();
                            }
                          },
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _dragging,
                        builder: (context, child) {
                          if (_dragging.value) {
                            return child!;
                          } else {
                            return const Center();
                          }
                        },
                        child: Center(
                            child: Opacity(
                          opacity: 0.75,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(printDuration(seekTo)),
                            ),
                          ),
                        )),
                      ),
                    ],
                  ),
                );
              },
            )));
  }
}
