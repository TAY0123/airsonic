import 'dart:async';

import 'package:airsonic/airsonic_connection.dart';
import 'package:airsonic/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/animation/animation_controller.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/src/widgets/ticker_provider.dart';

import 'card.dart';

class PlayListView extends StatefulWidget {
  const PlayListView({super.key});

  @override
  State<PlayListView> createState() => _PlayListViewState();
}

class _PlayListViewState extends State<PlayListView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  StreamController<AirSonicResult?> result = StreamController();

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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder(
          future: mp.fetchPlaylists(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return CustomScrollView(
                slivers: [
                  SliverList(
                      delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: SearchingBar(result),
                    )
                  ])),
                  SliverGrid.builder(
                    itemCount: snapshot.requireData.playlists.length,
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 500, childAspectRatio: 1.5),
                    itemBuilder: (context, index) {
                      final playlist = snapshot.requireData.playlists[index];
                      return CardSwipeAction(
                          child: PlayListCard(playlist: playlist));
                    },
                  )
                ],
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          }),
    );
  }
}
