import 'dart:async';

import 'package:airsonic/airsonic_connection.dart';
import 'package:airsonic/search.dart';
import 'package:flutter/material.dart';

import 'card.dart';

class ArtistListView extends StatefulWidget {
  const ArtistListView({super.key});

  @override
  State<ArtistListView> createState() => _ArtistListViewState();
}

class _ArtistListViewState extends State<ArtistListView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  MediaPlayer mp = MediaPlayer.instance;

  bool ended = false;

  final _defaultController = MediaPlayer.instance.fetchAlbumList();

  late Completer completer = Completer();

  Object? error;

  late ValueNotifier<AirSonicResult> _listController;
  final ScrollController _scrollController = ScrollController();
  final StreamController<AirSonicResult?> result = StreamController();

  @override
  void initState() {
    super.initState();

    _listController = ValueNotifier<AirSonicResult>(_defaultController);

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
        _listController.value = _defaultController;
        //_dataController.add(albums);
        return;
      } else {
        _listController.value = event;
      }
      //_dataController.add(event.albums);
    });

    _listController.addListener(
      () {
        fetchUntilScrollable();
      },
    );
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
    _listController.dispose();
    _scrollController.dispose();
    result.close();
    super.dispose();
  }

  Future<bool> fetchAlbums() async {
    if (_listController.value.album!.finished) {
      setState(() {});
      return true;
    }
    await _listController.value.album?.fetchNext();
    setState(() {});
    return true;
  }

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
            final a = _listController.value.album!;
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverGrid.builder(
                    itemCount: a.albums.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                            childAspectRatio: 0.75,
                            maxCrossAxisExtent: 250,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16),
                    itemBuilder: ((context, index) {
                      final album = a.albums[index];
                      return AlbumCard(album);
                    })),
                SliverFixedExtentList(
                    delegate: SliverChildListDelegate([
                      Center(
                          child: a.finished
                              ? Text(
                                  "Total Album: ${a.albums.length}",
                                  style: Theme.of(context).textTheme.bodyLarge,
                                )
                              : CircularProgressIndicator())
                    ]),
                    itemExtent: 100),
              ],
            );
          }),
        ),
      ),
    );
  }
}
