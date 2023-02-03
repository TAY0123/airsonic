import 'dart:async';

import 'package:airsonic/card.dart';
import 'package:airsonic/const.dart';
import 'package:airsonic/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/src/animation/animation_controller.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/src/widgets/ticker_provider.dart';

import 'airsonic_connection.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  StreamController<AirSonicResult?> search = StreamController();

  MediaPlayer mp = MediaPlayer.instance;

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
    List<Widget> root = [
      SearchingBar(search),
      Padding(padding: EdgeInsets.only(bottom: 8)),
    ];
    List<Widget> rootM = [
      SearchingBar(search),
      Padding(padding: EdgeInsets.only(bottom: 8)),
    ];
    List<Widget> content = [
      Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dashboard", style: Theme.of(context).textTheme.headlineLarge),
            SizedBox(
              height: 125 * 2 + 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: 400, maxWidth: 550),
                      child: DashboardCoverCard(),
                    ),
                  ),
                  Padding(padding: EdgeInsets.only(left: 16)),
                  Flexible(child: DashBoardRandomGrtidView())
                ],
              ),
            ),
          ],
        ),
      )
    ];

    List<Widget> contentM = [
      Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dashboard", style: Theme.of(context).textTheme.headlineLarge),
            SizedBox(
              height: 125 * 2 + 40,
              child: DashboardCoverCard(),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 8),
              child: Text(
                "Random",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            SizedBox(height: 125 * 2 + 40, child: DashBoardRandomGrtidView()),
          ],
        ),
      )
    ];

    root.addAll(content
        .map((e) => Padding(padding: const EdgeInsets.all(8.0), child: e)));
    rootM.addAll(contentM
        .map((e) => Padding(padding: const EdgeInsets.all(8.0), child: e)));
    return SafeArea(
      child: LayoutBuilder(builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: constraints.maxWidth > breakpointM ? root : rootM,
          ),
        );
      }),
    );
  }
}

class DashBoardRandomGrtidView extends StatelessWidget {
  const DashBoardRandomGrtidView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8),
          child: Text(
            "Random",
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Flexible(
          child: GridView(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 450,
              mainAxisExtent: 125,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            children: List.generate(10, (index) => Card()),
          ),
        ),
      ],
    );
  }
}
