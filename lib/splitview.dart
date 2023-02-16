import 'dart:io';

import 'package:airsonic/albums_grid.dart';
import 'package:airsonic/const.dart';
import 'package:airsonic/login.dart';
import 'package:airsonic/player_control.dart';
import 'package:airsonic/playlist_view.dart';
import 'package:airsonic/setting.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'airsonic_connection.dart';
import 'album_info.dart';
import 'albums_list.dart';
import 'artist_list.dart';
import 'dashboard.dart';
import 'main.dart';
import 'navigation.dart';

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
                                  windowManager.unmaximize();
                                } else {
                                  _maximize = true;
                                  windowManager.maximize();
                                }
                              },
                              child: Container(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: const Center(
                                  child: Text("Airsonic"),
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
                                  child: Scaffold(
                                bottomSheet: const PlayBackControl(),
                                body: Padding(
                                  padding: const EdgeInsets.only(bottom: 60.0),
                                  child: nav,
                                ),
                              ))
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
                          ? const EdgeInsets.only(top: 30, bottom: 60)
                          : const EdgeInsets.only(bottom: 60),
                  child: Center(
                    child: nav,
                  ),
                ),
                // use SizedBox to contrain the AppMenu to a fixed width
                drawer: NavDrawer(),
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
    return Navigator(
      key: rootNavigatorKey,
      observers: [HeroController()],
      initialRoute: "/",
      reportsRouteUpdateToEngine: true,
      onGenerateRoute: (settings) {
        print(settings.name);

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
            case "playlist":
              index.value = 3;
              page = const PlayListView();
              break;
            case "setting":
              index.value = 4;
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
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
      },
    );
  }
}
