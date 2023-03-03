import 'dart:async';
import 'dart:io';

import 'package:airsonic/utils/desktop_init.dart';
import 'package:airsonic/pages/login.dart';
import 'package:airsonic/pages/splitview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
  if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
    await desktopWindowManagerInit();
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
      final storage = await SharedPreferences.getInstance();
      login.add(storage.getBool("login") ?? false);
      /*
      if (storage.getBool("localDiscovery") ?? false) {
        final registration = await register(
            Service(name: "AirSonic-Test", type: '_http._tcp', port: 56000));
      }
      */
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
        body: FutureBuilder(
          future: SharedPreferences.getInstance(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Navigator(
                pages: [
                  MaterialPage(
                      child: snapshot.requireData.getBool("login") ?? false
                          ? SplitView()
                          : const LoginPage())
                ],
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
      themeMode: ThemeMode.system,
    );
  }
}

GlobalKey<NavigatorState>? rootNavigatorKey = GlobalKey();
