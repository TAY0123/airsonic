import 'dart:async';

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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double? _height = 60.0;
  var _original = 60.0;
  var _offset = 0.0;
  var _old = 60.0;

  bool opened = false;
  bool playing = false;

  final mp = MediaPlayer.instance;

  Duration pos = Duration.zero;
  Duration duration = Duration.zero;

  ValueStream<MediaItem?>? currentItemSubscriber;
  late StreamSubscription<Duration> currentItemPosition;
  late StreamSubscription<PlaybackState> currentStatusSubscriber;

  late Animation _animation;
  bool _animating = false;

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

  Future<void> init() async {
    currentItemSubscriber = (await mp.currentItem);
  }

  void _listenToPlayerStatus() async {
    currentStatusSubscriber = (await mp.playerStatus).listen((event) {
      setState(() {
        playing = event.playing;
      });
    });
  }

  void _listenToChangesInSong() async {}

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
    currentItemPosition.cancel();
    currentStatusSubscriber.cancel();
    _controller.dispose();
    super.dispose();
  }

  var animationEnded = true;
  var curves = Curves.linear;
  var dragFinish = true;
  double progress = 0.0;

  @override
  Widget build(BuildContext context) {
    final bar = Column(
      children: [
        Divider(
          height: 5,
          thickness: 3,
        ),
        Flexible(
          child: Row(
            children: [
              StreamBuilder(
                stream: currentItemSubscriber,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.requireData != null) {
                    final current = snapshot.requireData!;
                    return AnimatedSwitcher(
                      duration: Duration(milliseconds: 500),
                      child: CoverImage(
                        current.extras?["coverArt"] ?? "",
                        size: ImageSize.avatar,
                      ),
                    );
                  } else {
                    return Container();
                  }
                },
              ),
              Column(
                children: [],
              ),
              Spacer()
            ],
          ),
        )
      ],
    );

    return FutureBuilder(
      future: init(),
      builder: (context, snapshot) => SizedBox(
        height: 60,
        child: ResponsiveLayout(
          tablet: (context, constraints) {
            return bar;
          },
          mobile: (context, constraints) {
            return bar;
          },
        ),
      ),
    );
  }
}
