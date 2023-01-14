import 'dart:io';
import 'dart:math';

import 'package:airsonic/const.dart';
import 'package:airsonic/login.dart';
import 'package:airsonic/playerControl.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'navigation.dart';
import 'route.dart';

class SplitView extends StatefulWidget {
  final Widget? content;
  const SplitView(this.content, {super.key});

  @override
  State<SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final bool _mac = Platform.isMacOS;

  bool _maximize = false;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (desktop || constraints.maxWidth > breakpoint) {
        // widescreen: menu on the left, content on the right
        return Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: LayoutBuilder(builder: (context, constraints) {
              return Column(
                children: [
                  if (_mac)
                    SizedBox(
                      width: constraints.maxWidth,
                      height: 25,
                      child: GestureDetector(
                        onDoubleTap: () {
                          if (_maximize) {
                            _maximize = false;
                            windowManager.unmaximize();
                          } else {
                            _maximize = true;
                            windowManager.maximize();
                          }
                        },
                      ),
                    ),
                  SizedBox(
                    width: constraints.maxWidth,
                    height:
                        _mac // reserve space for title bar gesture detection
                            ? constraints.maxHeight - 25
                            : constraints.maxHeight,
                    child: Row(
                      children: [
                        const NavRail(),

                        // use SizedBox to constrain the AppMenu to a fixed width
                        // vertical black line as separator
                        // use Expanded to take up the remaining horizontal space
                        Expanded(
                          child: Scaffold(
                            bottomSheet: const PlayBackControl(),
                            body: Padding(
                              padding: const EdgeInsets.only(bottom: 60),
                              child: Center(
                                child: FractionallySizedBox(
                                  widthFactor: 0.975,
                                  child: widget.content,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              );
            }));
      } else {
        // narrow screen: show content, menu inside drawer
        return Scaffold(
          bottomSheet: const PlayBackControl(),
          body: Padding(
            padding: Platform.isMacOS || Platform.isLinux || Platform.isWindows
                ? const EdgeInsets.only(top: 30, bottom: 60)
                : const EdgeInsets.only(bottom: 60),
            child: Center(
              child: FractionallySizedBox(
                widthFactor: 0.975,
                child: widget.content,
              ),
            ),
          ),
          // use SizedBox to contrain the AppMenu to a fixed width
          drawer: NavDrawer(),
        );
      }
    });
  }
}
