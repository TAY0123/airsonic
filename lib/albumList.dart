import 'dart:async';

import 'package:airsonic/albumInfo.dart';
import 'package:airsonic/airsonicConnection.dart';
import 'package:airsonic/search.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

import 'card.dart';

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

  Object? error;

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

    result.stream.listen((event) {
      if (event == null) {
        _dataController.add(albums);
        return;
      }
      _dataController.add(event.albums);
      setState(() {
        ended = true;
      });
    });
    fetchUntilScrollable();
  }

  void fetchUntilScrollable() async {
    completer = Completer();
    await fetchAlbums();
    while ((!_scrollController.hasClients ||
            _scrollController.position.maxScrollExtent == 0.0) &&
        error == null &&
        !ended) {
      await fetchAlbums();
    }
    completer.complete();
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
    late List<Album> result;
    try {
      result = (await mp.fetchAlbumList(offset: offset)).albums;
    } catch (e) {
      error = e;
      _dataController.add([]); //trigger redraw from streambuilder
      return true;
    }

    if (result.isEmpty) {
      setState(() {
        ended = true;
      });
      return true;
    }

    albums.addAll(result);
    _dataController.add(albums);
    offset += result.length;

    return true;
  }

  final ScrollController _scrollController = ScrollController();

  final StreamController<AirSonicResult?> result = StreamController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [SearchingBar(result)],
      ),
      body: NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (notification) {
          () async {
            await completer.future;

            completer = Completer();
            while ((!_scrollController.hasClients ||
                    _scrollController.position.maxScrollExtent == 0.0) &&
                error == null &&
                !ended) {
              await fetchAlbums();
            }
            completer.complete();
          }();

          return true;
        },
        child: SizeChangedLayoutNotifier(
          child: LayoutBuilder(builder: (context, constraints) {
            return StreamBuilder(
                stream: _dataController.stream,
                builder: ((context, snapshot) {
                  if (snapshot.hasData) {
                    if (error != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(error.toString()),
                            FloatingActionButton.small(
                                child: const Icon(Icons.refresh),
                                onPressed: () {
                                  error = null;
                                  fetchUntilScrollable();
                                })
                          ],
                        ),
                      );
                    }
                    return CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        SliverGrid.builder(
                            itemCount: snapshot.data!.length,
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                    childAspectRatio: 0.75,
                                    maxCrossAxisExtent: 250,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16),
                            itemBuilder: ((context, index) {
                              final album = snapshot.data![index];
                              return AlbumCard(album);
                            })),
                        SliverFixedExtentList(
                            delegate: SliverChildListDelegate([
                              Center(
                                  child: ended
                                      ? Text(
                                          "Total Album: ${snapshot.data!.length}",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                        )
                                      : CircularProgressIndicator())
                            ]),
                            itemExtent: 100),
                      ],
                    );

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
          }),
        ),
      ),
    );
  }
}
