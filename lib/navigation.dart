import 'package:airsonic/utils/airsonic_connection.dart';
import 'package:airsonic/main.dart';
import 'package:flutter/material.dart';

class NavDrawer extends StatelessWidget {
  const NavDrawer({
    this.search = false,
    Key? key,
    required this.index,
  }) : super(key: key);

  final bool search;
  final ValueNotifier<int> index;

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
        onDestinationSelected: (value) {
          if (index.value == value) return;
          Scaffold.of(context).closeDrawer();
          switch (value) {
            case 0:
              rootNavigatorKey?.currentState
                  ?.pushNamedAndRemoveUntil("/", (route) => false);
              break;
            case 1:
              rootNavigatorKey?.currentState
                  ?.pushNamedAndRemoveUntil("/album", (route) => false);
              break;
            case 2:
              rootNavigatorKey?.currentState
                  ?.pushNamedAndRemoveUntil("/artist", (route) => false);
              break;
            case 3:
              rootNavigatorKey?.currentState
                  ?.pushNamedAndRemoveUntil("/song", (route) => false);
              break;
            case 4:
              rootNavigatorKey?.currentState
                  ?.pushNamedAndRemoveUntil("/playlist", (route) => false);
              break;
            case 5:
              rootNavigatorKey?.currentState
                  ?.pushNamedAndRemoveUntil("/setting", (route) => false);
              break;
            default:
          }
        },
        selectedIndex: index.value,
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
              icon: Icon(Icons.home), label: Text("Home")),
          const NavigationDrawerDestination(
              icon: Icon(Icons.album), label: Text("Albums")),
          const NavigationDrawerDestination(
              icon: Icon(Icons.people), label: Text("Artists")),
          const NavigationDrawerDestination(
              icon: Icon(Icons.library_music), label: Text("Songs")),
          const NavigationDrawerDestination(
              icon: Icon(Icons.playlist_play), label: Text("Playlist")),
          const NavigationDrawerDestination(
              icon: Icon(Icons.settings), label: Text("Settings")),
        ]);
  }
}

class NavBar extends StatelessWidget {
  const NavBar({super.key, required this.index});
  final ValueNotifier<int> index;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: index,
        builder: (context, value, child) {
          return NavigationBar(
              onDestinationSelected: (value) {
                if (index.value == value) return;
                switch (value) {
                  case 0:
                    rootNavigatorKey?.currentState
                        ?.pushNamedAndRemoveUntil("/", (route) => false);
                    break;
                  case 1:
                    rootNavigatorKey?.currentState
                        ?.pushNamedAndRemoveUntil("/album", (route) => false);
                    break;
                  case 2:
                    rootNavigatorKey?.currentState
                        ?.pushNamedAndRemoveUntil("/artist", (route) => false);
                    break;
                  case 3:
                    rootNavigatorKey?.currentState
                        ?.pushNamedAndRemoveUntil("/song", (route) => false);
                    break;
                  case 4:
                    rootNavigatorKey?.currentState?.pushNamedAndRemoveUntil(
                        "/playlist", (route) => false);
                    break;
                  case 5:
                    rootNavigatorKey?.currentState
                        ?.pushNamedAndRemoveUntil("/setting", (route) => false);
                    break;
                  default:
                }
              },
              destinations: const [
                /*
      NavigationDestination(icon: Icon(Icons.album), label: "Albums"),
      NavigationDestination(icon: Icon(Icons.people), label: "Artists"),
      */
                NavigationDestination(icon: Icon(Icons.home), label: "Home"),
                NavigationDestination(icon: Icon(Icons.album), label: "Albums"),
                NavigationDestination(
                    icon: Icon(Icons.people), label: "Artists"),
                NavigationDestination(
                    icon: Icon(Icons.library_music), label: "Songs"),
                NavigationDestination(
                    icon: Icon(Icons.playlist_play), label: "Playlist"),
                NavigationDestination(
                    icon: Icon(Icons.settings), label: "Settings"),
              ],
              selectedIndex: index.value);
        });
  }
}

class NavRail extends StatelessWidget {
  final bool extended;
  final ValueNotifier<int> index;
  const NavRail({this.extended = false, super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: index,
        builder: (context, value, child) {
          return NavigationRail(
              onDestinationSelected: (value) {
                if (index.value == value) return;
                switch (value) {
                  case 0:
                    rootNavigatorKey?.currentState
                        ?.pushNamedAndRemoveUntil("/", (route) => false);
                    break;
                  case 1:
                    rootNavigatorKey?.currentState
                        ?.pushNamedAndRemoveUntil("/album", (route) => false);
                    break;
                  case 2:
                    rootNavigatorKey?.currentState
                        ?.pushNamedAndRemoveUntil("/artist", (route) => false);
                    break;
                  case 3:
                    rootNavigatorKey?.currentState
                        ?.pushNamedAndRemoveUntil("/song", (route) => false);
                    break;
                  case 4:
                    rootNavigatorKey?.currentState?.pushNamedAndRemoveUntil(
                        "/playlist", (route) => false);
                    break;
                  case 5:
                    rootNavigatorKey?.currentState
                        ?.pushNamedAndRemoveUntil("/setting", (route) => false);
                    break;
                  default:
                }
              },
              groupAlignment: 0,
              extended: extended,
              labelType: extended
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
                    icon: Icon(Icons.library_music), label: Text("Songs")),
                NavigationRailDestination(
                    icon: Icon(Icons.playlist_play), label: Text("Playlist")),
                NavigationRailDestination(
                    icon: Icon(Icons.settings), label: Text("Settings")),
              ],
              selectedIndex: index.value);
        });
  }
}
