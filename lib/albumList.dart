import 'dart:async';

import 'package:airsonic/albumInfo.dart';
import 'package:airsonic/player.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

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
            return const Center(child: CircularProgressIndicator());
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

  bool full = false;

  late Future<ImageProvider?> img;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    img = mp.fetchCover(widget.album.coverArt).onError(
          (error, stackTrace) => Future.value(null),
        );
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
        context.pushTransparentRoute(AlbumInfo(
          widget.album,
          img: await img,
        ));
        /*
        Navigator.pushNamed(context, "/album/${widget.album.id}",
            arguments: widget.album);
            */
      },
      child: Card(
        child: Column(
          children: [
            Hero(
              tag: "${widget.album.id}-Cover}",
              child: AlbumImage(
                imgProvider: img,
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
                        child: Hero(
                          tag: "${widget.album.id}-Title}",
                          child: Text(
                            widget.album.name,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Hero(
                          tag: "${widget.album.id}-Artist}",
                          child: Text(
                            widget.album.artist?.name ?? "N.A",
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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

class AlbumImage extends StatelessWidget {
  final Future<ImageProvider?> imgProvider;

  const AlbumImage({
    super.key,
    required this.imgProvider,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          color: Theme.of(context).primaryColorDark,
          child: FutureBuilder(
            future: imgProvider,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.requireData != null) {
                return FadeInImage(
                  fadeInCurve: Curves.easeInCubic,
                  fadeInDuration: const Duration(milliseconds: 300),
                  placeholder: MemoryImage(kTransparentImage),
                  image: snapshot.requireData!,
                  fit: BoxFit.cover,
                  imageErrorBuilder: (context, error, stackTrace) =>
                      Container(),
                );
              } else {
                return Container();
              }
            },
          ),
        ),
      ),
    );
  }
}
