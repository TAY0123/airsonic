import 'package:airsonic/main.dart';
import 'package:flutter/material.dart';

import 'navigationDrawer.dart';

class SplitView extends StatefulWidget {
  const SplitView({super.key});

  @override
  State<SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool displayDrawer = true;

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
    final screenWidth = MediaQuery.of(context).size.width;
    const breakpoint = 600.0;
    if (screenWidth >= breakpoint) {
      // widescreen: menu on the left, content on the right
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Row(
          children: [
            AnimatedContainer(
              curve: Curves.easeInOut,
              duration: Duration(milliseconds: 200),
              width: displayDrawer ? 240 : 0,
              child: NavDrawer(
                search: true,
              ),
            ),
            // use SizedBox to constrain the AppMenu to a fixed width
            // vertical black line as separator
            // use Expanded to take up the remaining horizontal space
            Expanded(
              // TODO: make this configurable
              child: Scaffold(
                  appBar: AppBar(
                    leading: IconButton(
                      icon: Icon(Icons.menu),
                      onPressed: () {
                        setState(() {
                          displayDrawer = !displayDrawer;
                        });
                      },
                    ),
                    // Here we take the value from the MyHomePage object that was created by
                    // the App.build method, and use it to set our appbar title.
                    title: const Text("Dashboard"),
                  ),
                  body: const HomePage()),
            ),
          ],
        ),
      );
    } else {
      // narrow screen: show content, menu inside drawer
      return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: const Text("Dashboard"),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {},
              ),
            ),
          ],
        ),
        body: const HomePage(),
        // use SizedBox to contrain the AppMenu to a fixed width
        drawer: SizedBox(
          width: 240,
          child: NavDrawer(),
        ),
      );
    }
  }
}
