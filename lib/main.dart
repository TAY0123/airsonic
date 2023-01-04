import 'dart:ui';

import 'package:airsonic/albumInfo.dart';
import 'package:airsonic/dashboard.dart';
import 'package:airsonic/airsonicConnection.dart';
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
          brightness: Brightness.light,
          primarySwatch: Colors.blue,
          useMaterial3: true),
      home: SplitView(
        Navigator(
          observers: [
            HeroController(),
          ],
          key: GlobalKey(debugLabel: "navigator"),
          initialRoute: "/album",
          onGenerateRoute: (settings) {
            print(settings.name);
            late Widget page;

            if (settings.name == "/") {
              page = Container();
            }

            //handle /Dashboard
            if (settings.name == routeDashboard) {
              page = Dashboard();
              //handle / and /AlbumList
            } else if (settings.name == routeRootAlbum) {
              page = AlbumListView();
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

            return PageRouteBuilder(
                settings: settings,
                pageBuilder: (context, a, b) {
                  return page;
                });
          },
        ),
      ),
    );
  }
}
