import 'dart:async';

import 'package:airsonic/airsonic_connection.dart';
import 'package:airsonic/search.dart';
import 'package:flutter/material.dart';

import 'album_info.dart';
import 'animatedwave.dart';
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

  var _defaultController = MediaPlayer.instance.fetchAlbumList();

  late Completer completer = Completer();

  Object? error;

  final GlobalKey<NavigatorState> localNavigator = GlobalKey();

  late ValueNotifier<AirSonicResult> _listController;
  final ScrollController _scrollController = ScrollController();
  final StreamController<AirSonicResult?> result = StreamController();

  var _currentType = AlbumListType.recent;

  ValueNotifier<String> _index = ValueNotifier("");

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

    _index.addListener(
      () => Navigator.of(localNavigator.currentContext!)
          .pushNamedAndRemoveUntil("/album/${_index.value}", (route) => false,
              arguments: _listController.value.album?.albums
                  .firstWhere((element) => element.id == _index.value)),
    );
    fetchUntilScrollable();
  }

  void fetchUntilScrollable() async {
    final local_completer = Completer();
    completer = local_completer;
    await fetchAlbums();
    while ((!_scrollController.hasClients ||
            _scrollController.position.maxScrollExtent == 0.0) &&
        error == null &&
        !(_listController.value.album?.finished ?? true)) {
      await fetchAlbums();
    }
    local_completer.complete();
  }

  @override
  void dispose() {
    _controller.dispose();
    _listController.dispose();
    _scrollController.dispose();
    _index.dispose();
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
      body: SafeArea(
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

                    final List<PopupMenuEntry<AlbumListType>> b = chipss.entries
                        .map((element) => PopupMenuItem<AlbumListType>(
                              value: element.value,
                              child: Text(element.key),
                            ))
                        .toList();
                    return Padding(
                        padding: const EdgeInsets.only(
                            top: 4, left: 8.0, right: 8.0),
                        child: Column(
                          children: [
                            SearchingBar(result),
                            Padding(padding: EdgeInsets.only(bottom: 8)),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CustomScrollView(
                                  controller: _scrollController,
                                  slivers: [
                                    SliverList(
                                        delegate: SliverChildListDelegate([
                                      Row(
                                        children: [
                                          Spacer(),
                                          PopupMenuButton(
                                              tooltip: "sorting",
                                              initialValue: _currentType,
                                              icon: Icon(Icons.filter_list),
                                              itemBuilder: (context) => b,
                                              onSelected: (value) {
                                                if (_currentType == value)
                                                  return;
                                                setState(() {
                                                  _currentType = value;
                                                  _defaultController =
                                                      mp.fetchAlbumList(
                                                          type: value);
                                                });
                                                _listController.value =
                                                    _defaultController;
                                              }),
                                        ],
                                      ),
                                      Padding(
                                          padding: EdgeInsets.only(bottom: 30))
                                    ])),
                                    SliverList(
                                        delegate: SliverChildListDelegate(
                                      a.albums
                                          .map((e) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 8.0),
                                                child: AlbumTile(
                                                  e,
                                                  index: _index,
                                                ),
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
                                ),
                              ),
                            ),
                          ],
                        ));
                  }),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Navigator(
                key: localNavigator,
                initialRoute: "/",
                onGenerateRoute: (settings) {
                  print(settings.name);
                  Widget page = LayoutBuilder(builder: (context, constraints) {
                    return Column(
                      children: [
                        Spacer(),
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            AnimatedWave(
                              height: constraints.maxHeight / 4,
                              speed: 0.3,
                              color: Theme.of(context).primaryColor,
                            ),
                            AnimatedWave(
                                height: constraints.maxHeight / 4,
                                speed: 0.2,
                                color: Theme.of(context).colorScheme.surface),
                            AnimatedWave(
                                height: constraints.maxHeight / 4,
                                speed: 0.4,
                                color: Theme.of(context).primaryColorLight),
                          ],
                        ),
                      ],
                    );
                  });
                  Object? err;
                  Uri? uri;
                  try {
                    uri = Uri.parse(settings.name ?? "");
                  } catch (e) {
                    err = e;
                  }
                  if (err == null && (uri?.pathSegments.isNotEmpty ?? false)) {
                    switch (uri?.pathSegments.first) {
                      case "album":
                        if (uri?.pathSegments.length == 2) {
                          var id = uri?.pathSegments[1];
                          if (settings.arguments != null) {
                            page = Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: AlbumInfo(settings.arguments as Album),
                            );
                          } else {
                            page = Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: AlbumInfo(Album(id!, "", "")),
                            );
                          }
                        }
                        break;
                      default:
                        print("defauklt");

                        break;
                    }
                  }
                  // Handle '/album/:id'
                  /*
                  if (uri.pathSegments.length == 2 &&
                      uri.pathSegments.first == 'album') {
                   
                  }
                  */

                  return PageRouteBuilder(
                    transitionDuration: Duration(milliseconds: 250),
                    settings: settings,
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        Scaffold(
                      body: Card(child: page),
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
            )
          ],
        ),
      ),
    );
  }
}

var chipss = <String, AlbumListType>{
  "Recent": AlbumListType.recent,
  "Random": AlbumListType.random,
  "Newest": AlbumListType.newest,
  "Frequent": AlbumListType.frequent,
  "Starred": AlbumListType.starred,
  "By Name": AlbumListType.alphabeticalByName,
  "By Artist": AlbumListType.alphabeticalByArtist,
  /* support on 1.10.1 */
  //"By Year": AlbumListType.byYear,
  //"Genre": AlbumListType.byGenre
};
