import 'package:airsonic/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/animation/animation_controller.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/ticker_provider.dart';

class AlbumListView extends StatefulWidget {
  const AlbumListView({super.key});

  @override
  State<AlbumListView> createState() => _AlbumListViewState();
}

class _AlbumListViewState extends State<AlbumListView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  MediaPlayer mp = MediaPlayer.instance;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /*
    return ListView.builder(
        itemCount: result.albums.length,
        itemBuilder: ((context, index) {
          final item = result.albums[index];
          return ListTile(
            title: Text(item.name),
          );
        }));
  }
  */
    return FutureBuilder(
        future: mp.fetchAlbum(),
        builder: ((context, snapshot) {
          if (snapshot.hasData) {
            return ListView(
                children: snapshot.data?.albums.map((e) {
                      print(e.name);
                      return Text(e.name);
                    }).toList() ??
                    []);
          } else {
            return const CircularProgressIndicator();
          }
        }));
  }
}
