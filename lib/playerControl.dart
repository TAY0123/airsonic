import 'dart:math';

import 'package:flutter/material.dart';

class PlayBackControl extends StatefulWidget {
  const PlayBackControl({super.key});

  @override
  State<PlayBackControl> createState() => _PlayBackControlState();
}

class _PlayBackControlState extends State<PlayBackControl>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  var _height = 60.0;
  var _original = 60.0;
  var _offset = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: Duration(milliseconds: 3000));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      enableDrag: false,
      animationController: _controller,
      onClosing: () {},
      constraints: BoxConstraints.expand(height: _height),
      backgroundColor: Theme.of(context).primaryColorDark,
      builder: (context) {
        return GestureDetector(
          onVerticalDragEnd: (details) {
            final screen = MediaQuery.of(context).size.height;
            _controller.duration = const Duration(seconds: 3);
            if (_original > screen / 4 * 3 &&
                (-_offset > screen / 5 ||
                    details.velocity.pixelsPerSecond.dy < -1500)) {
              ///if dragging up and over threshold
              setState(() {
                _height = MediaQuery.of(context).size.height;
                if (_controller.isAnimating) _controller.forward();
              });
              return;
            }
            if (_original > screen / 4 * 3) {
              ///if dragging up and under threshold
              setState(() {
                if (_controller.isAnimating) _controller.forward();
                _height = 60;
              });
              return;
            }
            if (_original < screen / 4 &&
                (_offset > screen / 5 ||
                    details.velocity.pixelsPerSecond.dy > 1200)) {
              ///if dragging down and over threshold
              setState(() {
                _height = 60;
              });
              return;
            }

            ///if dragging down and under threshold
            setState(() {
              _height = screen;
            });
          },
          onVerticalDragStart: (details) {
            _original = MediaQuery.of(context).size.height - _height;
          },
          onVerticalDragUpdate: (details) {
            _offset = details.localPosition.dy;

            setState(() {
              _height = max(
                  60,
                  MediaQuery.of(context).size.height -
                      details.globalPosition.dy);
            });
          },
        );
      },
    );
  }
}
