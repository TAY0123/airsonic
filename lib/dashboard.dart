import 'dart:async';
import 'dart:math';

import 'package:airsonic/card.dart';
import 'package:airsonic/const.dart';
import 'package:airsonic/search.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'airsonic_connection.dart';
import 'album_info.dart';
import 'layout.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  StreamController<AirSonicResult?> search = StreamController();

  MediaPlayer mp = MediaPlayer.instance;

  final double cardHeight = 125 * 2 + 45;
  final double rowDesktopHeight = 125 * 2 + 105;
  final double rowMobileHeight = 125 * 4 + 45;
  late AirSonicResult recentAlbums;
  late AirSonicResult newestAlbums;
  late AirSonicResult randomAlbums;
  @override
  void initState() {
    super.initState();
    recentAlbums = mp.fetchAlbumList(type: AlbumListType.recent);
    newestAlbums = mp.fetchAlbumList(type: AlbumListType.newest);
    randomAlbums = mp.fetchAlbumList(type: AlbumListType.random);

    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme;
    final covercard = DashboardCoverCard();

    return ResponsiveLayout(
      tablet: (constraints) {
        double height = rowMobileHeight;

        if (constraints.maxWidth > breakpointM) {
          height = rowDesktopHeight;
        }
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: SearchingBar(search),
            ),
            Flexible(
                child: CustomScrollView(slivers: [
              SliverList(
                  delegate: SliverChildListDelegate([
                /* Text("Dashboard",
                      style: Theme.of(context).textTheme.headlineLarge), */
                Center(
                  child: SizedBox(
                    height: cardHeight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: min(max(450, constraints.maxWidth / 3), 550),
                          //constraints: BoxConstraints(
                          //    minWidth: 400, maxWidth: 550),
                          child: covercard,
                        ),
                        Padding(padding: EdgeInsets.only(left: 16)),
                        Flexible(
                          child: SizedBox.expand(
                            child: albumTileGrid("Random", randomAlbums),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 16),
                  child: albumCardGrid("Newest", newestAlbums),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 16),
                  child: albumCardGrid("Recent", recentAlbums),
                ),
              ]))
            ]))
          ]),
        );
      },
      mobile: (constraints) {
        double height = rowMobileHeight;

        if (constraints.maxWidth > breakpointM) {
          height = rowDesktopHeight;
        }
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: SearchingBar(search),
            ),
            Flexible(
                child: CustomScrollView(slivers: [
              SliverList(
                  delegate: SliverChildListDelegate([
                /* Text("Dashboard",
                      style: Theme.of(context).textTheme.headlineLarge), */
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: cardHeight,
                        child: covercard,
                      ),
                      SizedBox(
                          height: height,
                          child: albumTileGrid("Random", randomAlbums)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 16),
                  child: albumCardGrid("Newest", newestAlbums),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 16),
                  child: albumCardGrid("Recent", recentAlbums),
                ),
              ]))
            ]))
          ]),
        );
      },
    );
  }

  Widget albumCardGrid(
    String? title,
    AirSonicResult albumsController,
  ) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (title != null)
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                TextButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.arrow_forward),
                    label: Text("more"))
              ],
            ),
          ),
          Flexible(
            child: (albumsController.album?.albums.isNotEmpty ?? false)
                ? cardGridLayoutBuilder(albumsController)
                : FutureBuilder(
                    future: albumsController.album!.fetchNext(count: 30),
                    builder: (context, snapshot) {
                      if (albumsController.album != null &&
                          albumsController.album!.albums.isNotEmpty) {
                        return cardGridLayoutBuilder(albumsController);
                      } else {
                        return Container(
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                    }),
          ),
        ]);
  }

  LayoutBuilder cardGridLayoutBuilder(AirSonicResult albumsController) {
    int row = 4;
    int col = 1;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > breakpointM) {
          col = 1;
          row = (constraints.maxWidth / (250 + 4))
              .floor(); //max width should be 750 + padding
          if (row <= 0) {
            row = 1;
          }
        } else {
          row = 2;
          col = 2;
        }

        List<Widget> child = [];
        for (var i = 0; i < col; i++) {
          List<Widget> currentRowChild = [];
          for (var x = 0; x < row; x++) {
            final currentAlbum =
                albumsController.album?.albums.elementAtOrNull(i * row + x);
            if (currentAlbum == null) {
              break;
            }
            currentRowChild.add(Flexible(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: AspectRatio(
                  aspectRatio: 0.75,
                  child: AlbumCard(
                    currentAlbum,
                    hero: false,
                    onTap: (e) => callback(e),
                  ),
                ),
              ),
            ));
          }
          child.add(Flexible(
            child: Row(
              children: currentRowChild,
            ),
          ));
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: child,
        );
      },
    );
  }

  Widget albumTileGrid(String? title, AirSonicResult albumsController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (title != null)
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.arrow_forward),
                  label: Text("more"))
            ],
          ),
        ),
        Flexible(
          child: (albumsController.album?.albums.isNotEmpty ?? false)
              ? cardTileLayoutBuilder(albumsController)
              : FutureBuilder(
                  future: albumsController.album!.fetchNext(),
                  builder: (context, snapshot) {
                    if (albumsController.album != null &&
                        albumsController.album!.albums.isNotEmpty) {
                      return cardTileLayoutBuilder(albumsController);
                    } else {
                      return Container(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                  }),
        ),
      ],
    );
  }

  Widget cardTileLayoutBuilder(AirSonicResult albumsController) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int row = (constraints.maxWidth / (450 + 4))
            .floor(); //max width should be 750 + padding
        if (row <= 0) {
          row = 1;
        }
        int col = (constraints.maxHeight / (120 + 4)).floor();
        if (col <= 0) {
          col = 1;
        }
        List<Widget> child = [];
        for (var i = 0; i < col; i++) {
          List<Widget> currentRowChild = [];
          for (var x = 0; x < row; x++) {
            final currentAlbum =
                albumsController.album?.albums.elementAtOrNull(i * row + x);
            if (currentAlbum == null) {
              break;
            }
            currentRowChild.add(tiles(currentAlbum));
          }
          child.add(Flexible(
            child: Row(
              children: currentRowChild,
            ),
          ));
        }
        return Column(
          children: child,
        );
      },
    );
  }

  Flexible tiles(Album currentAlbum) {
    return Flexible(
      child: AlbumTile(
        currentAlbum,
        selectable: false,
        onTap: (album) {
          callback(album);
          /*
          context.pushTransparentRoute(Dialog(
            alignment: Alignment.center,
            child: FractionallySizedBox(
              heightFactor: 0.95,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AlbumInfo(album),
              ),
            ),
          ));
          */
        },
      ),
    );
  }

  void callback(Album album) {
    if (context.isMobile()) {
      Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 250),
            pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
              body: AlbumInfo(album),
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ));
    } else {
      showDialog(
          context: context,
          builder: (context) => Dialog(
                alignment: Alignment.center,
                child: FractionallySizedBox(
                  heightFactor: 0.95,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: AlbumInfo(album),
                  ),
                ),
              ));
    }
  }
}
