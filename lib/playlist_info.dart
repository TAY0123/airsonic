import 'package:airsonic/airsonic_connection.dart';
import 'package:airsonic/album_info.dart';
import 'package:airsonic/card.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class PlayListInfo extends StatelessWidget {
  PlayListInfo({super.key, required this.playlist});

  final Playlist playlist;
  final mp = MediaPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  playlist.name ?? "",
                  style: Theme.of(context).textTheme.headlineMedium,
                )
              ],
            ),
            Flexible(
              child: Row(
                children: [
                  CoverImage(
                    playlist.coverArt ?? "",
                    topRight: Radius.zero,
                    bottomLeft: Radius.zero,
                  ),
                  const Spacer()
                ],
              ),
            ),
            Flexible(
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FutureBuilder(
                      future: playlist.getInfo(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Column(
                            children: [
                              const ListTile(
                                title: Text("Song"),
                                trailing: Text("Duration"),
                              ),
                              Flexible(
                                child: ListView(
                                    children: playlist.entries
                                            ?.mapIndexed((index, e) => ListTile(
                                                  title: Text(e.title),
                                                  onTap: () {
                                                    mp.playPlaylist(
                                                        playlist.entries!,
                                                        index: index);
                                                  },
                                                  trailing: Text(printDuration(
                                                      Duration(
                                                          seconds:
                                                              e.duration))),
                                                  subtitle: Text(
                                                      e.artist?.name ?? ""),
                                                ))
                                            .toList() ??
                                        []),
                              )
                            ],
                          );
                        } else {
                          return Center(
                            child: Column(
                              children: const [CircularProgressIndicator()],
                            ),
                          );
                        }
                      },
                    )))
          ],
        ),
      ),
    );
  }
}
