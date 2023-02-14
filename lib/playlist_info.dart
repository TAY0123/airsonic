import 'package:airsonic/airsonic_connection.dart';
import 'package:airsonic/card.dart';
import 'package:flutter/material.dart';

class PlayListInfo extends StatelessWidget {
  const PlayListInfo({super.key, required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Row(
            children: [Text(playlist.name ?? "")],
          ),
          Row(
            children: [CoverImage(playlist.coverArt ?? "")],
          ),
        ],
      ),
    );
  }
}
