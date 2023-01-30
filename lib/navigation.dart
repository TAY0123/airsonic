import 'package:airsonic/airsonic_connection.dart';
import 'package:airsonic/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NavDrawer extends StatelessWidget {
  NavDrawer({
    this.search = false,
    Key? key,
  }) : super(key: key);

  final bool search;
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
  final ValueNotifier<int>? index;
  const NavRail({this.extended = false, super.key, this.index});

  @override
  State<NavRail> createState() => _NavRailState();
}

class _NavRailState extends State<NavRail> {
  late final ValueNotifier<int> _index = widget.index ?? ValueNotifier(0);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    if (widget.index == null) {
      _index.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: _index,
        builder: (context, value, child) {
          return NavigationRail(
              onDestinationSelected: (value) {
                if (_index.value == value) return;
                if (widget.index == null) {
                  _index.value = value;
                }
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
                  case 3:
                    Navi?.currentState?.pushNamedAndRemoveUntil(
                        "/playlist", (route) => false);
                    break;
                  case 4:
                    Navi?.currentState
                        ?.pushNamedAndRemoveUntil("/setting", (route) => false);
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
                    icon: Icon(Icons.playlist_play), label: Text("Playlist")),
                NavigationRailDestination(
                    icon: Icon(Icons.settings), label: Text("Settings")),
              ],
              selectedIndex: _index.value);
        });
  }
}
