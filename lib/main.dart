import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:airsonic/album_info.dart';
import 'package:airsonic/albums_list.dart';
import 'package:airsonic/artist_list.dart';
import 'package:airsonic/dashboard.dart';
import 'package:airsonic/airsonic_connection.dart';
import 'package:airsonic/login.dart';
import 'package:airsonic/desktop_init.dart';
import 'package:airsonic/playerControl.dart';
import 'package:airsonic/playlist_view.dart';
import 'package:airsonic/route.dart';
import 'package:airsonic/search.dart';
import 'package:airsonic/splitview.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'albums_grid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows && !kIsWeb) {
    await DesktopInit();
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamController<bool> login = StreamController();

  bool _hideNav = false;

  ValueNotifier<int> _index = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    () async {
      login.add(await SharedPreferences.getInstance()
          .then((value) => value.getBool("login") ?? (false)));
    }();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.blue,
          useMaterial3: true),
      darkTheme: ThemeData(
          brightness: Brightness.dark,
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          useMaterial3: true),
      home: Scaffold(
        body: SplitView(
          Navigator(
            key: Navi,
            observers: [HeroController()],
            initialRoute: "/",
            onGenerateRoute: (settings) {
              print(settings.name);
              if (_hideNav) {
                setState(() {
                  _hideNav = false;
                });
              }
              Widget page = const InitPage();

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
                  case "dashboard": //handle /Dashboard
                    _index.value = 0;
                    page = const Dashboard();
                    break;
                  case "login":
                    page = const LoginPage();
                    setState(() {
                      _hideNav = true;
                    });
                    break;
                  case "artist":
                    _index.value = 2;
                    Artist? parm = null;
                    if (uri?.pathSegments.length == 2) {
                      parm = Artist(uri?.pathSegments[1] ?? "", "");
                    }
                    page = ArtistViewList(
                      artist: parm,
                    );
                    break;
                  case "album":
                    _index.value = 1;
                    if (uri?.pathSegments.length == 2) {
                      page = AlbumViewList(
                        display: Album(uri?.pathSegments[1] ?? ""),
                      );
                    } else {
                      page =
                          const AlbumViewList(); //album: Album(id: uri?.pathSegments[1]) );
                    }
                    /* if (settings.arguments != null) {
                      page = AlbumInfo(settings.arguments as Album);
                    } */
                    break;
                  case "playlist":
                    _index.value = 3;
                    page = const PlayListView();
                    break;
                  default:
                    break;
                }
              }

              return PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 250),
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
          hideNavigator: _hideNav,
          index: _index, //follow navigation.dart
        ),
      ),
      themeMode: ThemeMode.system,
    );
  }
}

GlobalKey<NavigatorState>? Navi = GlobalKey();

class InitPage extends StatelessWidget {
  const InitPage({super.key});

  @override
  Widget build(BuildContext context) {
    () async {
      if ((await SharedPreferences.getInstance()).getBool("login") ?? false) {
        Navigator.of(context).popAndPushNamed("/dashboard");
      } else {
        Navigator.of(context).popAndPushNamed("/login");
      }
    }();
    return const Scaffold();
  }
}
