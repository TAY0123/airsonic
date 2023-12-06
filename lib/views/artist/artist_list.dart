import 'dart:async';

import 'package:airsonic/utils/airsonic_connection.dart';
import 'package:airsonic/widgets/animatedwave.dart';
import 'package:airsonic/widgets/search.dart';
import 'package:flutter/material.dart';

import '../../widgets/card.dart';
import '../albums/layout/albums_list.dart';
import 'artist_info.dart';

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

  var _defaultController = MediaPlayer.instance.getArtists();

  late Completer completer = Completer();

  Object? error;

  final GlobalKey<NavigatorState> localNavigator = GlobalKey();

  late ValueNotifier<AirSonicResult> _listController;
  final ScrollController _scrollController = ScrollController();
  final StreamController<AirSonicResult?> result = StreamController();

  var _currentType = AlbumListType.recent;

  final ValueNotifier<String> _index = ValueNotifier("-1");

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
    final localCompleter = Completer();
    completer = localCompleter;
    await fetchAlbums();
    while ((!_scrollController.hasClients ||
            _scrollController.position.maxScrollExtent == 0.0) &&
        error == null &&
        !(_listController.value.artist?.finished ?? true)) {
      await fetchAlbums();
    }
    localCompleter.complete();
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
    if ((_listController.value.artist?.finished ?? false) && mounted) {
      setState(() {});
      return true;
    }
    await _listController.value.artist?.fetchNext();
    if (mounted) setState(() {});
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
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

                      final List<PopupMenuEntry<AlbumListType>> b =
                          chipss.entries
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
                              const Padding(
                                  padding: EdgeInsets.only(bottom: 8)),
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
                                            const Spacer(),
                                            PopupMenuButton(
                                                tooltip: "sorting",
                                                initialValue: _currentType,
                                                icon: const Icon(
                                                    Icons.filter_list),
                                                itemBuilder: (context) => b,
                                                onSelected: (value) {
                                                  if (_currentType == value) {
                                                    return;
                                                  }
                                                  setState(() {
                                                    _currentType = value;
                                                    _defaultController =
                                                        mp.getAlbumList2(
                                                            type: value);
                                                  });
                                                  _listController.value =
                                                      _defaultController;
                                                }),
                                          ],
                                        ),
                                        const Padding(
                                            padding:
                                                EdgeInsets.only(bottom: 30))
                                      ])),
                                      SliverList(
                                          delegate: SliverChildListDelegate(
                                        a.artists
                                            .map((e) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
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
                                                    : const CircularProgressIndicator())
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
                      Widget page =
                          LayoutBuilder(builder: (context, constraints) {
                        return Column(
                          children: [
                            const Spacer(),
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
                      Object? err;
                      Uri? uri;
                      try {
                        uri = Uri.parse(settings.name ?? "");
                      } catch (e) {
                        err = e;
                      }
                      if (err == null &&
                          (uri?.pathSegments.isNotEmpty ?? false)) {
                        switch (uri?.pathSegments.first) {
                          case "artist":
                            if (uri?.pathSegments.length == 2) {
                              if (settings.arguments != null) {
                                page = Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: ArtistInfo(
                                      artist: settings.arguments as Artist),
                                );
                              } else {
                                var id = uri?.pathSegments[1] ?? "";
                                page = Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: ArtistInfo(
                                    artist: Artist(id, ""),
                                  ),
                                );
                              }
                            }
                            break;
                          default:
                            debugPrint("default");

                            break;
                        }
                      }

                      return PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 250),
                        settings: settings,
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            Card(child: page),
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
      ),
    );
  }
}
