import 'dart:async';

import 'package:airsonic/airsonic_connection.dart';
import 'package:airsonic/card.dart';
import 'package:airsonic/main.dart';
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
  late Future<bool> albumFetchStatus;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    albumFetchStatus = () async {
      return await widget.album.fetchInfo(combine: true);
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
          return Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                actions: [
                  IconButton(onPressed: () {}, icon: Icon(Icons.add)),
                  Tooltip(
                    message: "combine same Album with different artist",
                    child: Row(children: [
                      Icon(Icons.collections),
                      SizedBox(
                          width: 50,
                          height: 34,
                          child: FittedBox(
                            fit: BoxFit.fill,
                            child: Switch(
                              value: true,
                              onChanged: (value) {},
                            ),
                          ))
                    ]),
                  )
                ],
                surfaceTintColor: Colors.transparent,
              ),
              body: Column(
                children: [
                  Padding(padding: EdgeInsets.only(bottom: 8)),
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
                                      future: albumFetchStatus,
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          final currentAlbum = widget.album;
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
                          padding: EdgeInsets.only(left: 16),
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
                                        future: albumFetchStatus,
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            final currentAlbum = widget.album;
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
                              FilledButton.tonalIcon(
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
                                onPressed: () {
                                  Navi?.currentState?.pushReplacementNamed(
                                    "/artist/${widget.album.artist?.id ?? ""}",
                                  );
                                },
                                label: Icon(Icons.arrow_circle_right),
                                icon: Flexible(
                                  fit: FlexFit.loose,
                                  child: Hero(
                                    tag: "${widget.album.id}-Artist}",
                                    child: widget.album.img != null
                                        ? Text(
                                            widget.album.artist?.name ?? "",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                          )
                                        : FutureBuilder(
                                            future: albumFetchStatus,
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                final currentAlbum =
                                                    widget.album;
                                                return Text(
                                                  currentAlbum.artist?.name ??
                                                      "",
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                              ),
                              Padding(padding: EdgeInsets.only(bottom: 8)),
                              FutureBuilder(
                                future: albumFetchStatus,
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    if (!snapshot.requireData) {
                                      return Text("No album found");
                                    } else {
                                      final currentAlbum = widget.album;
                                      var total = Duration.zero;
                                      for (final i in currentAlbum.songs ??
                                          List<Song>.empty()) {
                                        total += Duration(seconds: i.duration);
                                      }
                                      return FilledButton(
                                          onPressed: null,
                                          child: Text(
                                              "${currentAlbum.songs?.length ?? 0} Songs · Total: ${printDuration(total)}"));
                                    }
                                  } else {
                                    return Text("Loading Album...");
                                  }
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 32.0),
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
                  Divider(),
                  Expanded(
                    flex: 7,
                    child: FutureBuilder(
                      future: albumFetchStatus,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final currentAlbum = widget.album;
                          int count = currentAlbum.songs?.length ?? 0;

                          List<Song> songs = [];
                          songs.addAll(currentAlbum.songs ?? []);
                          return ListView.separated(
                            itemCount: count,
                            separatorBuilder: (context, index) {
                              return const Divider();
                            },
                            itemBuilder: (context, index) {
                              return AlbumInfoListTile(
                                index,
                                songs,
                                artistName: currentAlbum.artist?.name,
                              );
                            },
                          );
                        } else {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                      },
                    ),
                  )
                ],
              ),
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
                    child: widget.album.img != null
                        ? AlbumImage(
                            album: widget.album,
                            fit: BoxFit.contain,
                          )
                        : FutureBuilder(
                            future: albumFetchStatus,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return AlbumImage(
                                  album: widget.album,
                                  fit: BoxFit.contain,
                                );
                              } else {
                                return Container(
                                  color: Colors.black,
                                );
                              }
                            },
                          ),
                  ),
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
                  const Padding(padding: EdgeInsets.only(top: 10)),
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
                            content: new Text("Artist Copied to Clipboard"),
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
                    future: albumFetchStatus,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final currentAlbum = widget.album;

                        int count = currentAlbum.songs?.length ?? 0;

                        List<Song> songs = [];
                        songs.addAll(currentAlbum.songs ?? []);
                        return Column(
                          children: songs
                              .mapIndexed(((i, song) {
                                return AlbumInfoListTile(
                                  i,
                                  songs,
                                  artistName: currentAlbum.artist?.name,
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

class AlbumInfoListTile extends StatefulWidget {
  final int index;
  final List<Song> songs;
  final String? artistName;
  const AlbumInfoListTile(int this.index, this.songs,
      {super.key, this.artistName});

  @override
  State<AlbumInfoListTile> createState() => _AlbumInfoListTileState();
}

class _AlbumInfoListTileState extends State<AlbumInfoListTile> {
  bool selected = false;
  MediaPlayer mp = MediaPlayer.instance;
  ValueStream<MediaItem?>? current;
  late Future<Null> task;
  late StreamSubscription<MediaItem?>? subscribe;

  @override
  void initState() {
    super.initState();
    task = () async {
      current = await mp.currentItem;
      selected = widget.songs[widget.index].id == current?.value?.id;
      subscribe = current?.listen((event) {
        setState(() {
          selected = widget.songs[widget.index].id == event?.id;
        });
      });
    }();
  }

  @override
  void dispose() {
    subscribe?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: task,
      builder: (context, snapshot) {
        return ListTile(
          selected: selected,
          onTap: () {
            setState(() {
              selected = true;
            });
            mp.playPlaylist(widget.songs, index: widget.index);
          },
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [Icon(Icons.play_arrow_rounded)],
          ),
          trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(printDuration(
                    Duration(seconds: widget.songs[widget.index].duration)))
              ]),
          title: Text(
            widget.songs[widget.index].title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            widget.songs[widget.index].artist?.name ??
                widget.artistName ??
                "Unknown",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}
