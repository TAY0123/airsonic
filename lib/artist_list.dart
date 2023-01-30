import 'dart:async';

import 'package:airsonic/airsonic_connection.dart';
import 'package:airsonic/animatedwave.dart';
import 'package:airsonic/artist_info.dart';
import 'package:airsonic/search.dart';
import 'package:flutter/material.dart';

import 'albums_list.dart';
import 'card.dart';

class ArtistViewList extends StatefulWidget {
  const ArtistViewList({super.key, this.artist});
  final Artist? artist;
  @override
  State<ArtistViewList> createState() => _ArtistViewListState();
}

class _ArtistViewListState extends State<ArtistViewList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  MediaPlayer mp = MediaPlayer.instance;

  bool ended = false;

  var _defaultController = MediaPlayer.instance.fetchArtistList();

  late Completer completer = Completer();

  Object? error;

  final GlobalKey<NavigatorState> localNavigator = GlobalKey();

  late ValueNotifier<AirSonicResult> _listController;
  final ScrollController _scrollController = ScrollController();
  final StreamController<AirSonicResult?> result = StreamController();

  var _currentType = AlbumListType.recent;

  ValueNotifier<String> _index = ValueNotifier("-1");

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
        //_dataController.add(artists);
        return;
      } else {
        _listController.value = event;
      }
      //_dataController.add(event.artists);
    });

    _listController.addListener(
      () {
        fetchUntilScrollable();
      },
    );

    _index.addListener(
      () =>
          Navigator.of(localNavigator.currentContext!).pushNamedAndRemoveUntil(
        "/artist/${_index.value}",
        (route) => false,
      ),
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
        !(_listController.value.artist?.finished ?? true)) {
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
    if (_listController.value.artist?.finished ?? false) {
      setState(() {});
      return true;
    }
    await _listController.value.artist?.fetchNext();
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
                        !(_listController.value.artist?.finished ?? true)) {
                      await fetchAlbums();
                    }
                    completer.complete();
                  }();

                  return true;
                },
                child: SizeChangedLayoutNotifier(
                  child: LayoutBuilder(builder: (context, constraints) {
                    final a = _listController.value.artist!;

                    final List<PopupMenuEntry<AlbumListType>> b = chipss.entries
                        .map((element) => PopupMenuItem<AlbumListType>(
                              value: element.value,
                              child: Text(element.key),
                            ))
                        .toList();
                    return Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
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
                                      a.artists
                                          .map((e) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 8.0),
                                                child: ArtistTile(
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
                                                      "Total Artist: ${a.artists.length}",
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
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Navigator(
                  key: localNavigator,
                  initialRoute: widget.artist != null
                      ? "/artist/${widget.artist?.id ?? ""}"
                      : "/",
                  onGenerateRoute: (settings) {
                    print(settings.name);
                    Widget page = Center(
                      child: Text("Page not found :("),
                    );

                    if (settings.name == "/") {
                      page = LayoutBuilder(builder: (context, constraints) {
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
                                    color:
                                        Theme.of(context).colorScheme.surface),
                                AnimatedWave(
                                    height: constraints.maxHeight / 4,
                                    speed: 0.4,
                                    color: Theme.of(context).primaryColorLight),
                              ],
                            ),
                          ],
                        );
                      });
                    }

                    // Handle '/artist/:id'
                    var uri = Uri.parse(settings.name ?? "");
                    if (uri.pathSegments.length == 2 &&
                        uri.pathSegments.first == 'artist') {
                      var id = uri.pathSegments[1];

                      if (settings.arguments != null) {
                        print((settings.arguments as Album).name);
                        page = ArtistInfo(artist: settings.arguments as Artist);
                      } else {
                        page = ArtistInfo(
                          artist: Artist(id, ""),
                        );
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
