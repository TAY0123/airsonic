import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:airsonic/albumInfo.dart';
import 'package:airsonic/dashboard.dart';
import 'package:airsonic/airsonicConnection.dart';
import 'package:airsonic/login.dart';
import 'package:airsonic/route.dart';
import 'package:airsonic/splitview.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'albumList.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    size: const Size(1280, 720),
    minimumSize: const Size(650, 720),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle:
        Platform.isMacOS ? TitleBarStyle.hidden : TitleBarStyle.normal,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

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

          primarySwatch: Colors.blue,
          useMaterial3: true),
      initialRoute: "/",
      onGenerateRoute: (settings) {
        print(settings.name);
        late Widget page;

        if (settings.name == "/") {
          page = InitPage();
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
        if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'album') {
          var id = uri.pathSegments[1];
          if (settings.arguments != null) {
            print((settings.arguments as Album).name);
            page = AlbumInfo(settings.arguments as Album);
          } else {
            page = AlbumInfo(Album(id, "", ""));
          }
        }

        return MaterialPageRoute(
            settings: settings,
            builder: (context) {
              return page;
            });
      },
      themeMode: ThemeMode.system,
      builder: (context, child) {
        return StreamBuilder(
          stream: login.stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.requireData) {
                return SplitView(child);
              } else {
                () async {
                  login.add(await SharedPreferences.getInstance()
                      .then((value) => value.getBool("login") ?? (false)));
                }();
                return child!;
              }
            } else {
              return Scaffold(
                body: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "App is now loading...",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ]),
                ),
              );
            }
          },
        );
      },
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
