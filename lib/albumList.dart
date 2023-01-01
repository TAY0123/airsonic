import 'dart:async';
import 'dart:convert';

import 'package:airsonic/albumInfo.dart';
import 'package:airsonic/player.dart';
import 'package:flutter/material.dart';

class AlbumListView extends StatefulWidget {
  const AlbumListView({super.key});

  @override
  State<AlbumListView> createState() => _AlbumListViewState();
}

class _AlbumListViewState extends State<AlbumListView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  MediaPlayer mp = MediaPlayer.instance;
  final StreamController<List<Album>> _dataController = StreamController();

  int offset = 0;
  bool ended = false;
  List<Album> albums = [];

  Completer completer = Completer();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 250), vsync: this);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent) {
        if (completer.isCompleted) {
          completer = Completer();
          fetchAlbums().then((value) {
            completer.complete();
            return value;
          });
        }
      }
    });
    () async {
      await fetchAlbums();
      while (!_scrollController.hasClients ||
          _scrollController.position.maxScrollExtent == 0.0) {
        await fetchAlbums();
      }
      completer.complete();
    }();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> fetchAlbums() async {
    if (ended) {
      return true;
    }

    final result = (await mp.fetchAlbum(offset: offset)).albums;
    if (result.isEmpty) {
      ended = true;
      return true;
    }

    _dataController.add(result);
    offset += result.length;

    return true;
  }

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _dataController.stream,
        builder: ((context, snapshot) {
          if (snapshot.hasData) {
            albums.addAll(snapshot.data ?? []);
            return GridView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: albums.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    childAspectRatio: 0.75, maxCrossAxisExtent: 250),
                itemBuilder: ((context, index) {
                  final album = albums[index];
                  return GestureDetector(
                    onTap: () async {
                      print("tapped");
                      showDialog(
                          context: context,
                          builder: ((context) => SimpleDialog(
                                title: Text(album.name),
                                children: [AlbumInfo(album)],
                              )));
                    },
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Expanded(
                              flex: 19,
                              child: Center(
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
                                  child: FutureBuilder(
                                    future: Future.delayed(
                                            const Duration(milliseconds: 400))
                                        .then((value) =>
                                            mp.fetchCover(album.coverArt)),
                                    builder: (context, imgsnapshot) {
                                      Widget child;
                                      if (imgsnapshot.hasData) {
                                        child = Image(
                                          image: imgsnapshot.requireData,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            color: Theme.of(context)
                                                .primaryColorDark,
                                          ),
                                        );
                                      } else {
                                        child = Container(
                                          color: Theme.of(context)
                                              .primaryColorDark,
                                        );
                                      }
                                      return AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 250),
                                          child: child);
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Expanded(
                                flex: 6,
                                child: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        album.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        album.artist?.name ?? "N.A",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ))
                          ],
                        ),
                      ),
                    ),
                  );
                }));

            /*
            ListView(
                children: snapshot.data?.albums.map((e) {
                      print(e.name);
                      return Text(e.name);
                    }).toList() ??
                    []);
                    */
          } else {
            return const CircularProgressIndicator();
          }
        }));
  }
}
