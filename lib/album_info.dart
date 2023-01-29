import 'package:airsonic/airsonic_connection.dart';
import 'package:airsonic/card.dart';
import 'package:airsonic/route.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

import 'const.dart';

///although it accept an album but a empty album with only id inside should work
class AlbumInfo extends StatefulWidget {
  final Album album;
  final String pageRoute;

  final VoidCallback? close;

  const AlbumInfo(this.album, {this.close, this.pageRoute = "", super.key});

  @override
  State<AlbumInfo> createState() => _AlbumInfoState();
}

class _AlbumInfoState extends State<AlbumInfo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final mp = MediaPlayer.instance;
  late Future<XMLResult> album;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    album = () async {
      return (await mp.fetchAlbumInfo(widget.album.id));
    }();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return true;
      },
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth > breakpointM) {
          return Container(
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                Row(
                  children: [
                    if (Navigator.canPop(context))
                      FloatingActionButton(
                        child: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                  ],
                ),
                Expanded(
                  flex: 7,
                  child: Row(
                    children: [
                      Hero(
                          tag: "${widget.album.id}-Cover}",
                          child: Center(
                            child: widget.album.img != null
                                ? AlbumImage(
                                    album: widget.album,
                                    fit: BoxFit.contain,
                                  )
                                : FutureBuilder(
                                    future: album,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        final currentAlbum =
                                            snapshot.requireData.albums[0];
                                        return AlbumImage(
                                          album: currentAlbum,
                                          fit: BoxFit.contain,
                                        );
                                      } else {
                                        return Container(
                                          color: Colors.black,
                                        );
                                      }
                                    },
                                  ),
                          )),
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Spacer(),
                            Hero(
                              tag: "${widget.album.id}-Title}",
                              child: widget.album.img != null
                                  ? Text(
                                      widget.album.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium,
                                    )
                                  : FutureBuilder(
                                      future: album,
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          final currentAlbum =
                                              snapshot.requireData.albums[0];
                                          return Text(
                                            currentAlbum.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineMedium,
                                          );
                                        } else {
                                          return Text("");
                                        }
                                      },
                                    ),
                            ),
                            Hero(
                              tag: "${widget.album.id}-Artist}",
                              child: GestureDetector(
                                onLongPress: () {
                                  Clipboard.setData(new ClipboardData(
                                      text: widget.album.artist?.name ?? ""));
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(new SnackBar(
                                    content: new Text(
                                      "Copied to Clipboard",
                                    ),
                                  ));
                                },
                                child: widget.album.img != null
                                    ? Text(
                                        widget.album.artist?.name ?? "",
                                        maxLines: 2,
                                        overflow: TextOverflow.fade,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      )
                                    : FutureBuilder(
                                        future: album,
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            final currentAlbum =
                                                snapshot.requireData.albums[0];
                                            return Text(
                                              currentAlbum.artist?.name ?? "",
                                              maxLines: 2,
                                              overflow: TextOverflow.fade,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge,
                                            );
                                          } else {
                                            return Text("");
                                          }
                                        },
                                      ),
                              ),
                            ),
                            FutureBuilder(
                              future: album,
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  if (snapshot.requireData.albums.isEmpty) {
                                    return Text("No album found");
                                  } else {
                                    final currentAlbum =
                                        snapshot.requireData.albums[0] ??
                                            Album("", "", "");
                                    var total = Duration.zero;
                                    for (final i in currentAlbum.songs ??
                                        List<Song>.empty()) {
                                      total += Duration(seconds: i.duration);
                                    }
                                    return Text(
                                        "${currentAlbum.songs?.length ?? 0} songs - Total: ${printDuration(total)}");
                                  }
                                } else {
                                  return Text("Loading Album...");
                                }
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: FilledButton.icon(
                                icon: Icon(Icons.play_arrow),
                                onPressed: () {},
                                label: Text("Play All"),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Align(
                    alignment: Alignment.centerLeft, child: Text("Songs")),
                Expanded(
                  flex: 7,
                  child: FutureBuilder(
                    future: Future.wait([album, mp.currentItem]),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final currentAlbum =
                            snapshot.requireData[0] as XMLResult;
                        final currentPlaying =
                            snapshot.requireData[1] as ValueStream<MediaItem?>;
                        int count = currentAlbum.albums
                            .map((e) => e.songs?.length ?? 0)
                            .sum;
                        List<Song> songs = [];
                        songs.addAll(currentAlbum.albums
                            .map((e) => e.songs ?? [])
                            .flattened);
                        songs.addAll(currentAlbum.songs.map((e) => e));
                        return ListView.separated(
                          itemCount: count,
                          separatorBuilder: (context, index) {
                            return const Divider();
                          },
                          itemBuilder: (context, index) {
                            final song = songs[index];
                            var selected = song.id == currentPlaying.value?.id;
                            return ListTile(
                              selected: selected,
                              onTap: () {
                                setState(() {
                                  selected = true;
                                });
                                mp.playPlaylist(songs, index: index);
                              },
                              leading: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.play_arrow_rounded)
                                ],
                              ),
                              title: Text(song.title),
                              subtitle: Text(song.artist?.name ??
                                  currentAlbum.albums[0].artist?.name ??
                                  "Unknown"),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(printDuration(
                                      Duration(seconds: song.duration)))
                                ],
                              ),
                            );
                          },
                        );
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                )
              ],
            ),
          );
        } else {
          return Container(
            color: Theme.of(context).cardColor,
            child: FractionallySizedBox(
              widthFactor: 0.9,
              child: ListView(
                padding: const EdgeInsets.all(10),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8),
                    child: Row(
                      children: [
                        FloatingActionButton(
                          child: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  ),
                  Hero(
                      tag: "${widget.album.id}-Cover}",
                      child: AlbumImage(
                        album: widget.album,
                        fit: BoxFit.contain,
                      )),
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Hero(
                      tag: "${widget.album.id}-Title}",
                      child: Text(
                        widget.album.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Hero(
                      tag: "${widget.album.id}-Artist}",
                      child: GestureDetector(
                        onLongPress: () {
                          Clipboard.setData(new ClipboardData(
                              text: widget.album.artist?.name ?? ""));
                          ScaffoldMessenger.of(context)
                              .showSnackBar(new SnackBar(
                            content: new Text("Copied to Clipboard"),
                          ));
                        },
                        child: Text(
                          widget.album.artist?.name ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.only(top: 10)),
                  const Align(
                      alignment: Alignment.centerLeft, child: Text("Songs")),
                  FutureBuilder(
                    future: Future.wait([album, mp.currentItem]),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final currentAlbum =
                            snapshot.requireData[0] as XMLResult;
                        final currentPlaying =
                            snapshot.requireData[1] as ValueStream<MediaItem?>;

                        int count = currentAlbum.albums
                            .map((e) => e.songs?.length ?? 0)
                            .sum;
                        List<Song> songs = [];
                        songs.addAll(currentAlbum.albums
                            .map((e) => e.songs ?? [])
                            .flattened);
                        songs.addAll(currentAlbum.songs.map((e) => e));
                        return Column(
                          children: songs
                              .mapIndexed(((i, song) {
                                return Builder(
                                  builder: (context) {
                                    var selected =
                                        song.id == currentPlaying.value?.id;
                                    return ListTile(
                                      selected: selected,
                                      onTap: () {
                                        setState(() {
                                          selected = true;
                                        });
                                        mp.playPlaylist(songs, index: i);
                                      },
                                      leading: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.play_arrow_rounded)
                                        ],
                                      ),
                                      trailing: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(printDuration(Duration(
                                                seconds: song.duration)))
                                          ]),
                                      title: Text(
                                        song.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        song.artist?.name ??
                                            currentAlbum
                                                .albums[0].artist?.name ??
                                            "Unknown",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  },
                                );
                              }))
                              .expand<Widget>((e) sync* {
                                yield e;
                                yield const Divider();
                              })
                              .take(songs.length * 2 - 1)
                              .toList(),
                        );
                      } else {
                        return Column(
                          children: const [
                            CircularProgressIndicator(),
                          ],
                        );
                      }
                    },
                  )
                ],
              ),
            ),
          );
        }
      }),
    );
  }
}

String printDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  if (duration.inHours > 0) {
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  } else {
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
