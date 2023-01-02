import 'package:airsonic/dashboard.dart';
import 'package:airsonic/player.dart';
import 'package:airsonic/playerControl.dart';
import 'package:airsonic/route.dart';
import 'package:airsonic/splitview.dart';
import 'package:flutter/material.dart';

import 'albumList.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          brightness: Brightness.dark,
          primarySwatch: Colors.blue,
          useMaterial3: true),
      onGenerateRoute: (settings) {
        late Widget page;
        if (settings.name == routeDashboard) {
          page = Dashboard();
        } else if (settings.name == routeRootAlbumList ||
            settings.name == "/") {
          page = AlbumListView();
        } else if (settings.name!.startsWith(routeDashboardAlbumInfo)) {
          final subRoute =
              settings.name!.substring(routeDashboardAlbumInfo.length);
        }

        return MaterialPageRoute(
            settings: settings,
            builder: (context) {
              return SplitView(page);
            });
      },
    );
  }
}
