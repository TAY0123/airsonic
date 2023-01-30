import 'dart:async';

import 'package:airsonic/search.dart';
import 'package:flutter/material.dart';
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
    List<Widget> content = [
      Text("Dashboard", style: Theme.of(context).textTheme.headlineLarge),
      Column(
        children: [
          SizedBox(
            height: 125 * 2 + 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 1,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Continue from last time",
                            style: Theme.of(context).textTheme.headlineMedium,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(padding: EdgeInsets.only(left: 16)),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text("Random"),
                      ),
                      Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Divider()),
                      Expanded(
                        child: GridView(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  mainAxisExtent: 125,
                                  mainAxisSpacing: 4,
                                  crossAxisSpacing: 4,
                                  crossAxisCount: 3),
                          children: List.generate(6, (index) => Card()),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      )
    ];

    root.addAll(content
        .map((e) => Padding(padding: const EdgeInsets.all(8.0), child: e)));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: root,
        ),
      ),
    );
  }
}
