import 'dart:async';

import 'package:airsonic/airsonic_connection.dart';
import 'package:airsonic/search.dart';
import 'package:flutter/material.dart';

import 'card.dart';

class AlbumViewGrid extends StatefulWidget {
  final AirSonicResult? controller;
  final bool pushNamedNavigation;
  final bool searchBar;
  final bool listenOnly;
  const AlbumViewGrid(
      {super.key,
      this.controller,
      this.pushNamedNavigation = true,
      this.searchBar = true,
      this.listenOnly = false});

  @override
  State<AlbumViewGrid> createState() => _AlbumViewGridState();
}

class _AlbumViewGridState extends State<AlbumViewGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  MediaPlayer mp = MediaPlayer.instance;

  bool ended = false;

  late AirSonicResult _defaultController =
      widget.controller ?? MediaPlayer.instance.fetchAlbumList();

  late Completer completer = Completer();

  Object? error;

  late ValueNotifier<AirSonicResult> _listController;
  late final ScrollController _scrollController;
  final StreamController<AirSonicResult?> result = StreamController();

  @override
  void initState() {
    super.initState();

    _listController = ValueNotifier<AirSonicResult>(_defaultController);

    _controller = AnimationController(
        duration: const Duration(milliseconds: 250), vsync: this);

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
        !(_listController.value.album?.finished ?? true)) {
      await fetchAlbums();
    }
    completer.complete();
  }

  @override
  void dispose() {
    _controller.dispose();
    _listController.dispose();
    if (!widget.listenOnly) _scrollController.dispose();
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
  void didChangeDependencies() {
    _scrollController = widget.listenOnly
        ? PrimaryScrollController.of(context)
        : ScrollController();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (notification) {
          () async {
            await completer.future;

            completer = Completer();
            while ((!_scrollController.hasClients ||
                    _scrollController.position.maxScrollExtent == 0.0) &&
                error == null &&
                !(_listController.value.album?.finished ?? true)) {
              await fetchAlbums();
            }
            completer.complete();
          }();

          return true;
        },
        child: SizeChangedLayoutNotifier(
          child: LayoutBuilder(builder: (context, constraints) {
            final a = _listController.value.album!;
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: CustomScrollView(
                controller: !widget.listenOnly ? _scrollController : null,
                slivers: [
                  if (widget.searchBar)
                    SliverFixedExtentList(
                        delegate: SliverChildListDelegate([
                          Center(
                              child: Row(
                            children: [
                              Expanded(child: SearchingBar(result)),
                              IconButton(
                                  onPressed: () {},
                                  icon: Icon(Icons.filter_list))
                            ],
                          ))
                        ]),
                        itemExtent: 80),
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
                        return AlbumCard(album,
                            pushNamed: widget.pushNamedNavigation);
                      })),
                  SliverFixedExtentList(
                      delegate: SliverChildListDelegate([
                        Center(
                            child: a.finished
                                ? Text(
                                    "Total Album: ${a.albums.length}",
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  )
                                : CircularProgressIndicator())
                      ]),
                      itemExtent: 100),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
