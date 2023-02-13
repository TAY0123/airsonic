import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:airsonic/album_info.dart';
import 'package:airsonic/albums_list.dart';
import 'package:airsonic/artist_list.dart';
import 'package:airsonic/const.dart';
import 'package:airsonic/dashboard.dart';
import 'package:airsonic/airsonic_connection.dart';
import 'package:airsonic/login.dart';
import 'package:airsonic/desktop_init.dart';
import 'package:airsonic/playerControl.dart';
import 'package:airsonic/playlist_view.dart';
import 'package:airsonic/route.dart';
import 'package:airsonic/search.dart';
import 'package:airsonic/setting.dart';
import 'package:airsonic/splitview.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'albums_grid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
  if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
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
        body: SplitView(),
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
