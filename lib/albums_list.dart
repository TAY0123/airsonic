import 'dart:async';

import 'package:airsonic/airsonic_connection.dart';
import 'package:airsonic/search.dart';
import 'package:flutter/material.dart';

import 'album_info.dart';
import 'card.dart';

class AlbumViewList extends StatefulWidget {
  const AlbumViewList({super.key});

  @override
  State<AlbumViewList> createState() => _AlbumViewListState();
}

class _AlbumViewListState extends State<AlbumViewList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  MediaPlayer mp = MediaPlayer.instance;

  bool ended = false;

  final _defaultController = MediaPlayer.instance.fetchAlbumList();

  late Completer completer = Completer();

  Object? error;

  final GlobalKey<NavigatorState> localNavigator = GlobalKey();

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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: NotificationListener<SizeChangedLayoutNotification>(
                onNotification: (notification) {
                  () async {
                    await completer.future;

                    completer = Completer();
                    while ((!_scrollController.hasClients ||
                            _scrollController.position.maxScrollExtent ==
                                0.0) &&
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

                    final List<PopupMenuEntry<String>> b = chips
                        .map((e) => PopupMenuItem<String>(
                              value: e,
                              child: Text(e),
                            ))
                        .toList();
                    return Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                        child: CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            SliverList(
                                delegate: SliverChildListDelegate([
                              Row(
                                children: [
                                  Expanded(
                                    child: SearchingBar(result),
                                  ),
                                  PopupMenuButton(
                                    tooltip: "sorting",
                                    initialValue: "Starred",
                                    icon: Icon(Icons.filter_list),
                                    itemBuilder: (context) => b,
                                  )
                                ],
                              ),
                            ])),
                            SliverList(
                                delegate: SliverChildListDelegate(
                              a.albums
                                  .map((e) => AlbumTile(
                                        e,
                                        nav: localNavigator,
                                      ))
                                  .toList(),
                            )),
                            SliverFixedExtentList(
                                delegate: SliverChildListDelegate([
                                  Center(
                                      child: a.finished
                                          ? Text(
                                              "Total Album: ${a.albums.length}",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge,
                                            )
                                          : CircularProgressIndicator())
                                ]),
                                itemExtent: 80),
                          ],
                        ));
                  }),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Navigator(
                  key: localNavigator,
                  initialRoute: "/",
                  onGenerateRoute: (settings) {
                    print(settings.name);
                    late Widget page;

                    if (settings.name == "/") {
                      page = Container();
                    }

                    // Handle '/album/:id'
                    var uri = Uri.parse(settings.name ?? "");
                    if (uri.pathSegments.length == 2 &&
                        uri.pathSegments.first == 'album') {
                      var id = uri.pathSegments[1];
                      if (settings.arguments != null) {
                        print((settings.arguments as Album).name);
                        page = AlbumInfo(settings.arguments as Album);
                      } else {
                        page = AlbumInfo(Album(id, "", ""));
                      }
                    }

                    return PageRouteBuilder(
                      transitionDuration: Duration(milliseconds: 250),
                      settings: settings,
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          Scaffold(
                        body: page,
                      ),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                    );
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

var chips = [
  "Recent",
  "Random",
  "Newest",
  "Frequent",
  "Starred",
  "By Name",
  "By Artist",
  "By Year",
  "Genre"
];
