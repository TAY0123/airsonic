import 'package:airsonic/albumInfo.dart';
import 'package:airsonic/dashboard.dart';
import 'package:airsonic/airsonicConnection.dart';
import 'package:airsonic/route.dart';
import 'package:airsonic/splitview.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'albumList.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
      themeMode: ThemeMode.system,
      home: SplitView(
        Navigator(
          observers: [
            HeroController(),
          ],
          key: GlobalKey(),
          initialRoute: "/album",
          onGenerateRoute: (settings) {
            print(settings.name);
            late Widget page;

            if (settings.name == "/") {
              page = Container();
            }

            //handle /Dashboard
            if (settings.name == routeDashboard) {
              page = const Dashboard();
              //handle / and /AlbumList
            } else if (settings.name == routeRootAlbum) {
              page = const AlbumListView();
            }

            // Handle '/album/:id'
            var uri = Uri.parse(settings.name ?? "");
            if (uri.pathSegments.length == 2 &&
                uri.pathSegments.first == 'album') {
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
        ),
      ),
    );
  }
}
