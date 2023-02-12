import 'dart:async';
import 'dart:math';

import 'package:airsonic/card.dart';
import 'package:airsonic/const.dart';
import 'package:airsonic/search.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/src/animation/animation_controller.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/src/widgets/ticker_provider.dart';

import 'airsonic_connection.dart';
import 'album_info.dart';

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
    final covercard = DashboardCoverCard();
    final randomGrid = DashBoardRandomGrtidView();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LayoutBuilder(builder: (context, constraints) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: SearchingBar(search),
            ),
            Flexible(
              child: CustomScrollView(
                slivers: [
                  SliverList(
                      delegate: SliverChildListDelegate([
                    /* Text("Dashboard",
                        style: Theme.of(context).textTheme.headlineLarge), */
                    constraints.maxWidth > breakpointM
                        ? Center(
                            child: SizedBox(
                              height: 125 * 2 + 40,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    width: min(
                                        max(450, constraints.maxWidth / 3),
                                        550),
                                    //constraints: BoxConstraints(
                                    //    minWidth: 400, maxWidth: 550),
                                    child: Expanded(child: covercard),
                                  ),
                                  Padding(padding: EdgeInsets.only(left: 16)),
                                  Flexible(
                                      child: SizedBox.expand(child: randomGrid))
                                ],
                              ),
                            ),
                          )
                        : Center(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 125 * 2 + 40,
                                  child: covercard,
                                ),
                                SizedBox(
                                    height: 125 * 4 + 40, child: randomGrid),
                              ],
                            ),
                          ),
                  ]))
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class DashBoardRandomGrtidView extends StatefulWidget {
  DashBoardRandomGrtidView({super.key});

  @override
  State<DashBoardRandomGrtidView> createState() =>
      _DashBoardRandomGrtidViewState();
}

class _DashBoardRandomGrtidViewState extends State<DashBoardRandomGrtidView> {
  final AirSonicResult albums =
      MediaPlayer.instance.fetchAlbumList(type: AlbumListType.random);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Random",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.arrow_forward),
                  label: Text("more"))
            ],
          ),
        ),
        Flexible(
          child: FutureBuilder(
              future: albums.album!.fetchNext(),
              builder: (context, snapshot) {
                if (albums.album != null && albums.album!.albums.isNotEmpty) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      int row = (constraints.maxWidth / (450 + 4))
                          .floor(); //max width should be 750 + padding
                      if (row <= 0) {
                        row = 1;
                      }
                      int col = (constraints.maxHeight / (120 + 4)).floor();
                      if (col <= 0) {
                        col = 1;
                      }
                      List<Widget> child = [];
                      for (var i = 0; i < col; i++) {
                        List<Widget> currentRowChild = [];
                        for (var x = 0; x < row; x++) {
                          final currentAlbum =
                              albums.album?.albums.elementAtOrNull(i * row + x);
                          if (currentAlbum == null) break;
                          currentRowChild.add(tiles(currentAlbum));
                        }
                        child.add(Row(
                          children: currentRowChild,
                        ));
                      }
                      return Column(
                        children: child,
                      );
                    },
                  );
                } else {
                  return Container(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
              }),
        ),
      ],
    );
  }

  Flexible tiles(Album currentAlbum) {
    return Flexible(
      child: AlbumTile(
        currentAlbum,
        selectable: false,
        onTap: (album) {
          showDialog(
              context: context,
              builder: (context) => Dialog(
                    alignment: Alignment.center,
                    child: FractionallySizedBox(
                      heightFactor: 0.95,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: AlbumInfo(album),
                      ),
                    ),
                  ));
        },
      ),
    );
  }
}
