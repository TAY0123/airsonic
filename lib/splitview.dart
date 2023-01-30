import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:airsonic/const.dart';
import 'package:airsonic/login.dart';
import 'package:airsonic/playerControl.dart';
import 'package:airsonic/search.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:window_manager/window_manager.dart';

import 'navigation.dart';
import 'route.dart';

class SplitView extends StatelessWidget {
  final Widget content;

  final bool _mac = Platform.isMacOS;

  bool _maximize = false;

  final bool hideNavigator;

  SplitView(
    this.content, {
    super.key,
    this.hideNavigator = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (desktop || constraints.maxWidth > breakpointM) {
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
                        if (!hideNavigator)
                          NavRail(
                            extended: (constraints.maxWidth > breakpointL)
                                ? true
                                : false,
                          ),

                        // use SizedBox to constrain the AppMenu to a fixed width
                        // vertical black line as separator
                        // use Expanded to take up the remaining horizontal space
                        Expanded(
                            child: Scaffold(
                          bottomSheet: PlayBackControl(),
                          body: Padding(
                            padding: const EdgeInsets.only(bottom: 60.0),
                            child: content,
                          ),
                        ))
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
                child: Scaffold(
                    appBar: AppBar(
                      backgroundColor: Colors.transparent,
                    ),
                    body: content),
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
