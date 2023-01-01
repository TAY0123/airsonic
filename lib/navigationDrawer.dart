import 'package:airsonic/player.dart';
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
                  padding: EdgeInsets.only(left: 10, right: 10),
                  child: TextField(
                    style: TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
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
        NavigationDrawerDestination(
            icon: Icon(Icons.album), label: Text("Albums")),
        NavigationDrawerDestination(
            icon: Icon(Icons.people), label: Text("Artists")),
        NavigationDrawerDestination(
            icon: Icon(Icons.settings), label: Text("Settings")),
        NavigationDrawerDestination(
            icon: Icon(Icons.playlist_play), label: Text("Playlist")),
      ],
    );
  }
}
