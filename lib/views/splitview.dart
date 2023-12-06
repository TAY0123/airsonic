import 'dart:io';

import 'package:airsonic/views/playlists/playlist_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../const.dart';
import '../player_control.dart';
import '../utils/airsonic_connection.dart';
import 'albums/album_info.dart';
import 'albums/layout/albums_grid.dart';
import 'albums/layout/albums_list.dart';
import 'artist/artist_list.dart';
import 'dashboard.dart';
import '../main.dart';
import '../navigation.dart';
import 'login.dart';
import 'setting.dart';

class SplitView extends StatelessWidget {
  final bool _mac = !kIsWeb && Platform.isMacOS;

  bool _maximize = false;

  final bool hideNavigator = false;

  SplitView({
    super.key,
  });

  ValueNotifier<int> index = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final storage = snapshot.requireData;
          final nav = AppNavigator(index: index, storage: storage);

          return LayoutBuilder(builder: (context, constraints) {
            if (desktop || constraints.maxWidth > breakpointM) {
              // widescreen: menu on the left, content on the right
              return Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: LayoutBuilder(builder: (context, constraints) {
                    return Column(
                      children: [
                        if (_mac)
                          SizedBox(
                            height: 25,
                            child: GestureDetector(
                              onDoubleTap: () {
                                if (_maximize) {
                                  _maximize = false;
                                } else {
                                  _maximize = true;
                                }
                              },
                              child: Container(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: const Center(
                                  child: Text(
                                      'Flutter Airsonic ${kReleaseMode ? "" : "(Debug)"}'),
                                ),
                              ),
                            ),
                          ),
                        SizedBox(
                          height:
                              _mac // reserve space for title bar gesture detection
                                  ? constraints.maxHeight - 25
                                  : constraints.maxHeight,
                          child: Row(
                            children: [
                              if (!hideNavigator)
                                NavRail(
                                  index: index,
                                  extended: (constraints.maxWidth > breakpointL)
                                      ? true
                                      : false,
                                ),

                              // use SizedBox to constrain the AppMenu to a fixed width
                              // vertical black line as separator
                              // use Expanded to take up the remaining horizontal space
                              Expanded(
                                  child: Stack(children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: bottomHeight),
                                  child: nav,
                                ),
                                Align(
                                    alignment: Alignment.bottomCenter,
                                    child: PlayBackControl()),
                              ]))
                            ],
                          ),
                        )
                      ],
                    );
                  }));
            } else {
              // narrow screen: show content, menu inside drawer
              return Scaffold(
                bottomSheet: const PlayBackControl(),
                body: Padding(
                  padding:
                      Platform.isMacOS || Platform.isLinux || Platform.isWindows
                          ? const EdgeInsets.only(top: 30, bottom: bottomHeight)
                          : const EdgeInsets.only(bottom: bottomHeight),
                  child: SafeArea(
                    child: Center(
                      child: nav,
                    ),
                  ),
                ),
                // use SizedBox to contrain the AppMenu to a fixed width
                drawer: NavDrawer(
                  index: index,
                ),
              );
            }
          });
        } else {
          return Center(
            child: Column(
              children: const [CircularProgressIndicator(), Text("loading...")],
            ),
          );
        }
      },
    );
  }
}

class AppNavigator extends StatelessWidget {
  const AppNavigator({
    super.key,
    required this.index,
    required this.storage,
  });

  final ValueNotifier<int> index;
  final SharedPreferences storage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
      child: Navigator(
        key: rootNavigatorKey,
        observers: [HeroController()],
        initialRoute: "/",
        reportsRouteUpdateToEngine: true,
        onGenerateRoute: (settings) {
          debugPrint(settings.name);

          double uiSize = MediaQuery.of(context).size.width;
          if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
            uiSize -= 80; //navrail width
          }
          Widget page = Container();
          //parse uri
          Object? err;
          Uri? uri;
          try {
            uri = Uri.parse(settings.name ?? "");
          } catch (e) {
            err = e;
          }
          if (err == null && (uri?.pathSegments.isNotEmpty ?? false)) {
            switch (uri?.pathSegments.first) {
              case "dashboard": //handle
                index.value = 0;
                page = const Dashboard();
                break;
              case "login":
                page = const LoginPage();

                break;
              case "artist":
                index.value = 2;
                Artist? parm;
                if (uri?.pathSegments.length == 2) {
                  parm = Artist(uri?.pathSegments[1] ?? "", "");
                }
                page = ArtistViewList(
                  artist: parm,
                );
                break;
              case "album":
                index.value = 1;
                if (uri?.pathSegments.length == 2) {
                  ///push albuminfo directly on top if screen is mobile size
                  if (uiSize <= breakpointMScale) {
                    page = AlbumInfo(Album(uri?.pathSegments[1] ?? ""));
                  } else {
                    if (storage.getBool("albumStyle") ?? false) {
                      page = const AlbumViewGrid();
                      //display: Album(uri?.pathSegments[1] ?? ""),
                    } else {
                      page = AlbumViewList(
                        display: Album(uri?.pathSegments[1] ?? ""),
                      );
                    }
                  }
                } else {
                  if (storage.getBool("albumStyle") ?? false) {
                    page = const AlbumViewGrid();
                  } else {
                    page = const AlbumViewList();
                  }
                }
                /* if (settings.arguments != null) {
                  page = AlbumInfo(settings.arguments as Album);
                } */
                break;
              case "song":
                index.value = 3;
                page = const Placeholder();
                break;
              case "playlist":
                index.value = 4;
                page = const PlayListView();
                break;
              case "setting":
                index.value = 5;
                page = const SettingPage();
                break;
              default:
            }
          } else {
            //default page for / and undefined
            index.value = 0;
            page = const Dashboard();
          }
          return PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 250),
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
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
    );
  }
}

const bottomHeight = 70.0;
