import 'dart:async';

import 'package:airsonic/utils/airsonic_connection.dart';
import 'package:airsonic/utils/utils.dart';
import 'package:airsonic/widgets/card.dart';
import 'package:airsonic/layout.dart';
import 'package:airsonic/main.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

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
      return await widget.album.fetchInfo();
    }();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final albumCover = Hero(
        tag: "${widget.album.id}-Cover}",
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: widget.album.image != null
                ? CoverImage.fromAlbum(
                    widget.album,
                    fit: BoxFit.contain,
                    size: ImageSize.original,
                  )
                : FutureBuilder(
                    future: albumFetchStatus,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final currentAlbum = widget.album;
                        return CoverImage.fromAlbum(
                          currentAlbum,
                          fit: BoxFit.contain,
                          size: ImageSize.original,
                        );
                      } else {
                        return Container(
                          color: Colors.transparent,
                        );
                      }
                    },
                  ),
          ),
        ));
    final artistButton = FilledButton.tonalIcon(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: widget.album.artist?.name ?? ""));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            "Copied to Clipboard",
          ),
        ));
      },
      onPressed: () {
        rootNavigatorKey?.currentState?.pushReplacementNamed(
          "/artist/${widget.album.artist?.id ?? ""}",
        );
      },
      label: const Icon(Icons.arrow_circle_right),
      icon: Flexible(
        fit: FlexFit.loose,
        child: Hero(
          tag: "${widget.album.id}-Artist}",
          child: widget.album.image != null
              ? Text(
                  widget.album.artist?.name ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge,
                )
              : FutureBuilder(
                  future: albumFetchStatus,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final currentAlbum = widget.album;
                      return Text(
                        currentAlbum.artist?.name ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge,
                      );
                    } else {
                      return const Text("");
                    }
                  },
                ),
        ),
      ),
    );
    final albumTitle = Hero(
      tag: "${widget.album.id}-Title}",
      child: widget.album.image != null
          ? GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: widget.album.name));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Copied to Clipboard"),
                ));
              },
              child: Text(
                widget.album.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium,
              ))
          : FutureBuilder(
              future: albumFetchStatus,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final currentAlbum = widget.album;
                  return GestureDetector(
                      onLongPress: () {
                        Clipboard.setData(
                            ClipboardData(text: currentAlbum.name));
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text("Copied to Clipboard"),
                        ));
                      },
                      child: Text(
                        currentAlbum.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ));
                } else {
                  return const Text("");
                }
              },
            ),
    );
    final loadingPlaceholder = const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text("fetching songs ..."),
          )
        ],
      ),
    );

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return true;
      },
      child: ResponsiveLayout(
        tablet: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
            ),
            child: ScaffoldMessenger(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  actions: [
                    IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
                  ],
                  surfaceTintColor: Colors.transparent,
                ),
                body: Column(
                  children: [
                    const Padding(padding: EdgeInsets.only(bottom: 8)),
                    Expanded(
                      flex: 7,
                      child: Row(
                        children: [
                          albumCover,
                          const Padding(
                            padding: EdgeInsets.only(left: 16),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Spacer(),
                                albumTitle,
                                artistButton,
                                const Padding(
                                    padding: EdgeInsets.only(bottom: 8)),
                                FutureBuilder(
                                  future: albumFetchStatus,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      if (!snapshot.requireData) {
                                        return const Text("No album found");
                                      } else {
                                        final currentAlbum = widget.album;
                                        var total = Duration.zero;
                                        for (final i in currentAlbum.songs ??
                                            List<Song>.empty()) {
                                          total +=
                                              Duration(seconds: i.duration);
                                        }
                                        return FilledButton(
                                            onPressed: null,
                                            child: Text(
                                                "${currentAlbum.songs?.length ?? 0} Songs · Total: ${printDuration(total)}"));
                                      }
                                    } else {
                                      return const Text("Loading Album...");
                                    }
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 32.0),
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 4.0),
                                        child: FilledButton.icon(
                                          icon: const Icon(Icons.play_arrow),
                                          onPressed: () {
                                            mp.playPlaylist(
                                                widget.album.songs ?? []);
                                          },
                                          label: const Text("Play All"),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 4.0, right: 4.0),
                                        child: IconButton(
                                            onPressed: () {},
                                            icon: const Icon(Icons.favorite)),
                                      )
                                    ],
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
                    const Divider(),
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
                            return loadingPlaceholder;
                          }
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
        mobile: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Theme.of(context).colorScheme.background,
              ),
              body: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.9,
                    child: ListView(
                      padding: const EdgeInsets.all(10),
                      children: [
                        if (widget.close != null)
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
                        albumCover,
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                        ),
                        Align(
                            alignment: Alignment.centerLeft, child: albumTitle),
                        const Padding(padding: EdgeInsets.only(top: 10)),
                        Align(
                            alignment: Alignment.centerLeft,
                            child: artistButton),
                        const Padding(padding: EdgeInsets.only(top: 10)),
                        const Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Songs")),
                        FutureBuilder(
                          future: albumFetchStatus,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final currentAlbum = widget.album;

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
                              return loadingPlaceholder;
                            }
                          },
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AlbumInfoListTile extends StatefulWidget {
  final int index;
  final List<Song> songs;
  final String? artistName;
  const AlbumInfoListTile(this.index, this.songs, {super.key, this.artistName});

  @override
  State<AlbumInfoListTile> createState() => _AlbumInfoListTileState();
}

class _AlbumInfoListTileState extends State<AlbumInfoListTile> {
  bool selected = false;
  MediaPlayer mp = MediaPlayer.instance;
  ValueStream<MediaItem?>? current;
  late Future<void> task;
  StreamSubscription<MediaItem?>? subscribe;

  @override
  void initState() {
    super.initState();
    task = () async {
      current = await mp.currentItem;
      selected =
          widget.songs[widget.index].id == current?.value?.extras?["songId"];
      subscribe = current?.listen((event) {
        if (mounted) {
          setState(() {
            selected =
                widget.songs[widget.index].id == event?.extras?["songId"];
          });
        }
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
          onLongPress: () {
            Clipboard.setData(ClipboardData(
                text:
                    "${widget.songs[widget.index].title} - ${widget.songs[widget.index].artist?.name}"));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Copied to Clipboard"),
            ));
          },
          onTap: () async {
            if (widget.songs[widget.index].id ==
                current?.value?.extras?["songId"]) return;
            setState(() {
              selected = true;
            });
            () async {
              final c = await mp.queue;
              final currentQueue = c.value;
              final indexed = currentQueue.elementAtOrNull(widget.index);
              if (indexed != null &&
                  indexed.extras?["songId"] == widget.songs[widget.index].id) {
                if (currentQueue.length == widget.songs.length) {
                  bool equal = true;
                  for (var i = 0; i < currentQueue.length; i++) {
                    if (currentQueue[i].id != widget.songs[i].id) {
                      equal = false;
                      break;
                    }
                  }
                  if (equal) {
                    mp.skipToIndexed(widget.index);
                    return;
                  }
                }
              }
              mp.playPlaylist(widget.songs, index: widget.index);
            }();
          },
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              selected
                  ? const Icon(
                      Icons.play_arrow,
                    )
                  : const Icon(
                      Icons.play_arrow_outlined,
                    )
            ],
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
