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
                  return AlbumCard(album);
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

class AlbumCard extends StatefulWidget {
  final Album album;

  const AlbumCard(this.album, {super.key});

  @override
  State<AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<AlbumCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final MediaPlayer mp = MediaPlayer.instance;

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
    return GestureDetector(
      onTap: () async {
        print("tapped");
      },
      child: AnimatedContainer(
        margin: EdgeInsets.all(5),
        decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                  color: Theme.of(context).shadowColor,
                  spreadRadius: 0,
                  blurRadius: 1)
            ],
            borderRadius: BorderRadius.circular(12.0),
            color: Theme.of(context).secondaryHeaderColor),
        duration: Duration(milliseconds: 750),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: FutureBuilder(
                future: Future.delayed(const Duration(milliseconds: 400))
                    .then((value) => mp.fetchCover(widget.album.coverArt)),
                builder: (context, imgsnapshot) {
                  Widget child;
                  if (imgsnapshot.hasData) {
                    print(widget.album.coverArt);

                    child = Image(
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                        return AspectRatio(aspectRatio: 1, child: child);
                      },
                      fit: BoxFit.cover,
                      image: imgsnapshot.requireData,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Theme.of(context).primaryColorDark,
                      ),
                    );
                  } else {
                    child = AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          color: Theme.of(context).primaryColorDark,
                        ));
                  }
                  return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: child);
                },
              ),
            ),
            Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, top: 5),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.album.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.album.artist?.name ?? "N.A",
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ))
          ],
        ),
      ),
    );
  }
}
