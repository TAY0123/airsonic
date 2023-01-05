import 'dart:math';

import 'package:airsonic/playerControl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

import 'navigation.dart';
import 'route.dart';

class SplitView extends StatefulWidget {
  final Widget content;
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > breakpoint) {
        // widescreen: menu on the left, content on the right
        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Row(
            children: [
              AnimatedContainer(
                curve: Curves.easeInOutCubicEmphasized,
                duration: const Duration(milliseconds: 600),
                child: const NavRail(),
              ),
              // use SizedBox to constrain the AppMenu to a fixed width
              // vertical black line as separator
              // use Expanded to take up the remaining horizontal space
              Expanded(
                // TODO: make this configurable
                child: Scaffold(
                  body: Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.975,
                      child: widget.content,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // narrow screen: show content, menu inside drawer
        return Scaffold(
          bottomNavigationBar: NavBar(),
          body: Center(
            child: FractionallySizedBox(
              widthFactor: 0.975,
              child: widget.content,
            ),
          ),
          // use SizedBox to contrain the AppMenu to a fixed width
          drawer: NavDrawer(),
        );
      }
    });
  }
}
