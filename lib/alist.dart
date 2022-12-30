import 'package:airsonic/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/animation/animation_controller.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/ticker_provider.dart';

class AlbumListView extends StatefulWidget {
  const AlbumListView({super.key});

  @override
  State<AlbumListView> createState() => _AlbumListViewState();
}

class _AlbumListViewState extends State<AlbumListView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  MediaPlayer mp = MediaPlayer.instance;
  List<Album> albums = [];
  int offset = 0;
  bool ended = false;
  Future<bool> _lock = Future.value(true);

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: Duration(milliseconds: 250), vsync: this);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<Album>> fetchAlbums() async {
    await _lock;
    if (ended) {
      return albums;
    }

    _lock = Future.delayed(Duration(seconds: 25)).then((value) => true);
    final result = (await mp.fetchAlbum(offset: offset)).albums;
    albums.addAll(result);
    if (result.isEmpty) {
      ended = true;
      print("ended: $offset");

      _lock.ignore();
      _lock = Future.value(true);
      return albums;
    }
    offset += result.length;

    _lock.ignore();
    _lock = Future.value(true);
    return albums;
  }

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: fetchAlbums(),
        builder: ((context, snapshot) {
          if (snapshot.hasData) {
            return GridView.builder(
                shrinkWrap: true,
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8.0),
                itemCount: snapshot.data?.length ?? 0,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    childAspectRatio: 0.75, maxCrossAxisExtent: 250),
                itemBuilder: ((context, index) {
                  final album = snapshot.data?[index] ?? Album("", "", "");
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Expanded(
                            flex: 8,
                            child: FutureBuilder(
                              future:
                                  Future.delayed(Duration(milliseconds: 250))
                                      .then((value) =>
                                          mp.fetchCover(album.coverArt)),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: Image(
                                        image: snapshot.requireData,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          color: Theme.of(context)
                                              .primaryColorDark,
                                        ),
                                      ));
                                }
                                return Container();
                              },
                            ),
                          ),
                          Spacer(),
                          Expanded(
                              flex: 3,
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
