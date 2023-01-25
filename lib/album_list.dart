import 'dart:async';

import 'package:airsonic/airsonic_connection.dart';
import 'package:airsonic/search.dart';
import 'package:flutter/material.dart';

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

  bool ended = false;

  final _defaultController = MediaPlayer.instance.fetchAlbumList();

  late Completer completer = Completer();

  Object? error;

  late ValueNotifier<AirSonicResult> _listController;
  final StreamController<AirSonicResult?> result = StreamController();
  final GlobalKey<NestedScrollViewState> globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _listController = ValueNotifier<AirSonicResult>(_defaultController);

    _controller = AnimationController(
        duration: const Duration(milliseconds: 250), vsync: this);

    result.stream.listen((event) {
      final pos = globalKey.currentState!.innerController.position;
      globalKey.currentState!.innerController.animateTo(-pos.pixels,
          duration: Duration(milliseconds: 250), curve: Curves.easeInCubic);
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

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      globalKey.currentState!.innerController.addListener(() {
        final pos = globalKey.currentState!.innerController.position;
        if (pos.pixels >= pos.maxScrollExtent) {
          if (completer.isCompleted) {
            completer = Completer();
            fetchAlbums().then((value) {
              completer.complete();
              return value;
            });
          }
        }
      });
    });
  }

  void fetchUntilScrollable() async {
    completer = Completer();
    await fetchAlbums();
    final pos = globalKey.currentState!.innerController.position;
    while ((pos.maxScrollExtent == 0.0) &&
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
    result.close();
    super.dispose();
  }

  Future<bool> fetchAlbums() async {
    final ori = _listController.value.album?.albums.isEmpty ?? true;
    await _listController.value.album?.fetchNext();
    setState(() {});
    if (ori) {
      await _listController.value.album?.fetchNext();
      setState(() {});
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (notification) {
          () async {
            await completer.future;

            completer = Completer();
            final pos = globalKey.currentState!.innerController.position;
            while ((pos.maxScrollExtent == 0.0) &&
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

            //dropdown
            final dd = AlbumListType.values
                .map(
                  (e) => e.name,
                )
                .toList();
            var it = dd.first;
            return NestedScrollView(
                key: globalKey,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar.large(
                      leading: Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: DropdownMenu(
                          textStyle: Theme.of(context).textTheme.bodyLarge,
                          dropdownMenuEntries:
                              dd.map<DropdownMenuEntry<String>>((String value) {
                            return DropdownMenuEntry<String>(
                              value: value,
                              label: "home",
                            );
                          }).toList(),
                        ),
                      ),
                      title: Text("Album"),
                      expandedHeight: 125,
                      backgroundColor: Theme.of(context).colorScheme.background,
                      elevation: 0,
                      surfaceTintColor: Colors.transparent,
                      actions: [SearchingBar(result)],
                    )
                  ];
                },
                body: Builder(
                  builder: (context) {
                    return CustomScrollView(
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
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                        )
                                      : CircularProgressIndicator())
                            ]),
                            itemExtent: 100),
                      ],
                    );
                  },
                ));
          }),
        ),
      ),
    );
  }
}
