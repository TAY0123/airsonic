import 'dart:async';

import 'package:airsonic/airsonic_connection.dart';
import 'package:airsonic/layout.dart';
import 'package:airsonic/search.dart';
import 'package:flutter/material.dart';

import 'album_info.dart';
import 'albums_list.dart';
import 'card.dart';

class AlbumViewGrid extends StatefulWidget {
  final AirSonicResult? controller;
  final bool pushNamedNavigation;
  final bool searchBar;
  final bool listenOnly;
  final Album? display;
  const AlbumViewGrid(
      {super.key,
      this.controller,
      this.pushNamedNavigation = true,
      this.searchBar = true,
      this.listenOnly = false,
      this.display});

  @override
  State<AlbumViewGrid> createState() => _AlbumViewGridState();
}

class _AlbumViewGridState extends State<AlbumViewGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  MediaPlayer mp = MediaPlayer.instance;

  bool ended = false;

  late AirSonicResult _defaultController =
      widget.controller ?? MediaPlayer.instance.getAlbumList2();

  late Completer completer = Completer();

  Object? error;

  late ValueNotifier<AirSonicResult> _listController;
  late final ScrollController _scrollController;
  final StreamController<AirSonicResult?> result = StreamController();

  var _currentType = AlbumListType.recent;
  late List<PopupMenuEntry<AlbumListType>> b;

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

    b = chipss.entries
        .map((element) => PopupMenuItem<AlbumListType>(
              value: element.value,
              child: Text(element.key),
            ))
        .toList();

    fetchUntilScrollable();
  }

  void fetchUntilScrollable() async {
    final localCompleter = Completer();
    completer = localCompleter;
    await fetchAlbums();
    while ((!_scrollController.hasClients ||
            _scrollController.position.maxScrollExtent == 0.0) &&
        error == null &&
        !(_listController.value.album?.finished ?? true) &&
        mounted) {
      await fetchAlbums();
    }
    localCompleter.complete();
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
      return true;
    }
    await _listController.value.album?.fetchNext(count: 300);
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
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (notification) {
        fetchUntilScrollable();
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
                  SliverList(
                    delegate: SliverChildListDelegate([
                      SearchingBar(result),
                      Padding(padding: EdgeInsets.only(bottom: 8)),
                      Row(
                        children: [
                          Spacer(),
                          IconButton(
                              tooltip: "change mode",
                              onPressed: () {
                                Navigator.of(context)
                                    .pushReplacement(PageRouteBuilder(
                                  pageBuilder:
                                      (context, animation, secondaryAnimation) {
                                    return AlbumViewList();
                                  },
                                ));
                              },
                              icon: Icon(Icons.list)),
                          PopupMenuButton(
                              tooltip: "sorting",
                              initialValue: _currentType,
                              icon: Icon(Icons.filter_list),
                              itemBuilder: (context) => b,
                              onSelected: (value) {
                                if (_currentType == value) return;
                                setState(() {
                                  _currentType = value;
                                  _defaultController =
                                      mp.getAlbumList2(type: value);
                                });
                                _listController.value = _defaultController;
                              }),
                        ],
                      ),
                    ]),
                  ),
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
                      return AlbumCard(
                        album: album,
                        onTap: (e) {
                          if (context.isMobile()) {
                            Navigator.of(context)
                                .pushNamed("/album/${e.id}", arguments: album);
                          } else {
                            showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                      alignment: Alignment.center,
                                      child: FractionallySizedBox(
                                        heightFactor: 0.95,
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: AlbumInfo(e),
                                        ),
                                      ),
                                    ));
                          }
                        },
                      );
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
            ),
          );
        }),
      ),
    );
  }
}
