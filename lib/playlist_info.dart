import 'package:airsonic/airsonic_connection.dart';
import 'package:airsonic/album_info.dart';
import 'package:airsonic/card.dart';
import 'package:flutter/material.dart';

class PlayListInfo extends StatelessWidget {
  const PlayListInfo({super.key, required this.playlist});

  final Playlist playlist;

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
                children: [CoverImage(playlist.coverArt ?? ""), Spacer()],
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
                              ListTile(
                                title: Text("Song"),
                                trailing: Text("Duration"),
                              ),
                              Flexible(
                                child: ListView(
                                    children: playlist.entries
                                            ?.map((e) => ListTile(
                                                  title: Text(e.title),
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
                              children: [CircularProgressIndicator()],
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
