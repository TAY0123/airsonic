import 'dart:async';

import 'package:airsonic/pages/albums/layout/albums_grid.dart';
import 'package:airsonic/utils/airsonic_connection.dart';
import 'package:airsonic/layout.dart';
import 'package:airsonic/widgets/animatedwave.dart';
import 'package:airsonic/widgets/card.dart';
import 'package:airsonic/widgets/search.dart';
import 'package:flutter/material.dart';

import '../album_info.dart';

class AlbumViewList extends StatefulWidget {
  const AlbumViewList({super.key, this.display});

  final Album? display;
  @override
  State<AlbumViewList> createState() => _AlbumViewListState();
}

class _AlbumViewListState extends State<AlbumViewList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  MediaPlayer mp = MediaPlayer.instance;

  bool ended = false;

  var _defaultController = MediaPlayer.instance.getAlbumList2();

  late Completer completer = Completer();

  Object? error;

  final GlobalKey<NavigatorState> localNavigator = GlobalKey();

  late ValueNotifier<AirSonicResult> _listController;
  final ScrollController _scrollController = ScrollController();
  final StreamController<AirSonicResult?> result = StreamController();

  var _currentType = AlbumListType.recent;

  final ValueNotifier<String> _index = ValueNotifier("");

  late List<PopupMenuEntry<AlbumListType>> b;

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
      () {
        if (localNavigator.currentContext != null) {
          Navigator.of(localNavigator.currentContext!).pushNamedAndRemoveUntil(
              "/album/${_index.value}", (route) => false,
              arguments: _listController.value.album?.albums
                  .firstWhere((element) => element.id == _index.value));
        } else {
          Navigator.of(context).pushNamed("/album/${_index.value}",
              arguments: _listController.value.album?.albums
                  .firstWhere((element) => element.id == _index.value));
        }
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    _scrollController.dispose();
    _index.dispose();
    result.close();
    super.dispose();
  }

  Future<bool> fetchAlbums() async {
    if (_listController.value.album!.finished) {
      return true;
    }

    await _listController.value.album?.fetchNext(count: 300);
    if (mounted) {
      setState(() {});
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final a = _listController.value.album!;

    final changemodeBtn = IconButton(
        tooltip: "change mode",
        onPressed: () {
          Navigator.of(context).pushReplacement(PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return const AlbumViewGrid();
            },
          ));
        },
        icon: const Icon(Icons.list));
    final sortingMenu = PopupMenuButton(
        tooltip: "sorting",
        initialValue: _currentType,
        icon: const Icon(Icons.filter_list),
        itemBuilder: (context) => b,
        onSelected: (value) {
          if (_currentType == value) return;
          setState(() {
            _currentType = value;
            _defaultController = mp.getAlbumList2(type: value);
          });
          _listController.value = _defaultController;
        });
    final albumsList = Column(
      children: [
        SearchingBar(result),
        const Padding(padding: EdgeInsets.only(bottom: 8)),
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
                      changemodeBtn,
                      sortingMenu,
                    ],
                  ),
                ])),
                SliverList(
                    delegate: SliverChildListDelegate(
                  a.albums
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
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
                                  style: Theme.of(context).textTheme.bodyLarge,
                                )
                              : const CircularProgressIndicator())
                    ]),
                    itemExtent: 80),
              ],
            ),
          ),
        ),
      ],
    );
    return ResponsiveLayout(
      tablet: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Expanded(
                child: NotificationListener<SizeChangedLayoutNotification>(
                  onNotification: (notification) {
                    fetchUntilScrollable();

                    return true;
                  },
                  child: SizeChangedLayoutNotifier(
                    child: LayoutBuilder(builder: (context, constraints) {
                      return Padding(
                          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                          child: albumsList);
                    }),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Navigator(
                  key: localNavigator,
                  initialRoute: widget.display == null
                      ? "/"
                      : "/album/${widget.display?.id ?? ""}",
                  onGenerateRoute: (settings) {
                    print(settings.name);
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
                    if (err == null &&
                        (uri?.pathSegments.isNotEmpty ?? false)) {
                      switch (uri?.pathSegments.first) {
                        case "album":
                          if (uri?.pathSegments.length == 2) {
                            var id = uri?.pathSegments[1];
                            if (settings.arguments != null) {
                              final album = settings.arguments as Album;
                              page = AlbumInfo(album);
                            } else {
                              page = AlbumInfo(Album(id!));
                            }
                          }
                          break;
                        default:
                      }
                    }
                    // Handle '/album/:id'
                    /*
                if (uri.pathSegments.length == 2 &&
                    uri.pathSegments.first == 'album') {
                 
                }
                */

                    return PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 250),
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
        );
      },
      mobile: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: albumsList,
        );
      },
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
