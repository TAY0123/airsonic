import 'dart:math';

import 'package:airsonic/airsonic_connection.dart';
import 'package:airsonic/main.dart';
import 'package:flutter/material.dart';

class NavDrawer extends StatelessWidget {
  NavDrawer({
    this.search = false,
    Key? key,
  }) : super(key: key);

  bool search;
  final mp = MediaPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      children: [
        //Text("Welcome back ${mp.username}"),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: search
              ? Container(
                  height: 60,
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: TextField(
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      filled: true,
                      hintText: "Search",
                    ),
                  ),
                )
              : Container(),
        ),
        const NavigationDrawerDestination(
            icon: Icon(Icons.album), label: Text("Albums")),
        const NavigationDrawerDestination(
            icon: Icon(Icons.people), label: Text("Artists")),
        const NavigationDrawerDestination(
            icon: Icon(Icons.folder), label: Text("Folders")),
        const NavigationDrawerDestination(
            icon: Icon(Icons.settings), label: Text("Settings")),
        const NavigationDrawerDestination(
            icon: Icon(Icons.playlist_play), label: Text("Playlist")),
      ],
    );
  }
}

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(destinations: const [
      /*
      NavigationDestination(icon: Icon(Icons.album), label: "Albums"),
      NavigationDestination(icon: Icon(Icons.people), label: "Artists"),
      */
      NavigationDestination(icon: Icon(Icons.home), label: "Home"),
      NavigationDestination(icon: Icon(Icons.category), label: "Categories"),
      NavigationDestination(icon: Icon(Icons.search), label: "Search"),
    ]);
  }
}

class NavRail extends StatefulWidget {
  final bool extended;
  const NavRail({this.extended = false, super.key});

  @override
  State<NavRail> createState() => _NavRailState();
}

class _NavRailState extends State<NavRail> {
  int index = 1;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
        onDestinationSelected: (value) {
          setState(() {
            index = value;
          });
          switch (value) {
            case 0:
              Navi?.currentState
                  ?.pushNamedAndRemoveUntil("/", (route) => false);
              break;
            case 1:
              Navi?.currentState
                  ?.pushNamedAndRemoveUntil("/album", (route) => false);
              break;
            case 2:
              Navi?.currentState
                  ?.pushNamedAndRemoveUntil("/artist", (route) => false);
              break;
            default:
          }
        },
        groupAlignment: 0,
        extended: widget.extended,
        labelType: widget.extended
            ? NavigationRailLabelType.none
            : NavigationRailLabelType.selected,
        destinations: const [
          NavigationRailDestination(
              icon: Icon(Icons.home), label: Text("Home")),
          NavigationRailDestination(
              icon: Icon(Icons.album), label: Text("Albums")),
          NavigationRailDestination(
              icon: Icon(Icons.people), label: Text("Artists")),
          NavigationRailDestination(
              icon: Icon(Icons.folder), label: Text("Folders")),
          NavigationRailDestination(
              icon: Icon(Icons.playlist_play), label: Text("Playlist")),
          NavigationRailDestination(
              icon: Icon(Icons.settings), label: Text("Settings")),
          NavigationRailDestination(
              icon: Icon(Icons.view_list), label: Text("Sources")),
        ],
        selectedIndex: index);
  }
}
