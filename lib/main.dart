import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:airsonic/album_info.dart';
import 'package:airsonic/dashboard.dart';
import 'package:airsonic/airsonic_connection.dart';
import 'package:airsonic/login.dart';
import 'package:airsonic/desktop_init.dart';
import 'package:airsonic/playerControl.dart';
import 'package:airsonic/route.dart';
import 'package:airsonic/search.dart';
import 'package:airsonic/splitview.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'album_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows && !kIsWeb) {
    await DesktopInit();
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key}) {
    () async {
      login.add(await SharedPreferences.getInstance()
          .then((value) => value.getBool("login") ?? (false)));
    }();
  }

  StreamController<bool> login = StreamController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      navigatorKey: Navi,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          brightness: Brightness.light,
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.blue,
          useMaterial3: true),
      darkTheme: ThemeData(
          brightness: Brightness.dark,
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.

          useMaterial3: true),
      home: Scaffold(
        body: SplitView(
          Navigator(
            observers: [HeroController()],
            initialRoute: "/",
            onGenerateRoute: (settings) {
              print(settings.name);
              late Widget page;

              if (settings.name == "/") {
                page = const InitPage();
              }

              //handle /Dashboard
              if (settings.name == routeDashboard) {
                page = const Dashboard();
                //handle / and /AlbumList
              } else if (settings.name == routeRootAlbum) {
                //page = const AlbumListView();
                page = const AlbumListView();
              }
              if (settings.name == "/login") {
                page = const LoginPage();
              }

              // Handle '/album/:id'
              var uri = Uri.parse(settings.name ?? "");
              if (uri.pathSegments.length == 2 &&
                  uri.pathSegments.first == 'album') {
                var id = uri.pathSegments[1];
                if (settings.arguments != null) {
                  print((settings.arguments as Album).name);
                  page = AlbumInfo(settings.arguments as Album);
                  return TransparentRoute(
                      builder: (context) => page,
                      backgroundColor: Colors.black.withOpacity(0.5),
                      transitionDuration: Duration(milliseconds: 250),
                      reverseTransitionDuration: Duration(milliseconds: 250));
                } else {
                  page = AlbumInfo(Album(id, "", ""));
                  return TransparentRoute(
                      builder: (context) => page,
                      backgroundColor: Theme.of(context).colorScheme.background,
                      transitionDuration: Duration(milliseconds: 250),
                      reverseTransitionDuration: Duration(milliseconds: 250));
                }
              }

              return MaterialPageRoute(
                  settings: settings,
                  builder: (context) {
                    return Scaffold(
                      body: page,
                    );
                  });
            },
          ),
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
        Navigator.of(context).popAndPushNamed("/album");
      } else {
        Navigator.of(context).popAndPushNamed("/login");
      }
    }();
    return const Scaffold();
  }
}
