import 'package:airsonic/airsonic_connection.dart';
import 'package:airsonic/albums_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:transparent_image/transparent_image.dart';

class ArtistInfo extends StatefulWidget {
  final Artist artist;

  const ArtistInfo({super.key, required this.artist});

  @override
  State<ArtistInfo> createState() => _ArtistInfoState();
}

class _ArtistInfoState extends State<ArtistInfo> {
  GlobalKey<NestedScrollViewState> scrollviewKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: () async {
        if (widget.artist.albumsCount != 0) {
        } else {
          await widget.artist.getDetail();
        }
        await widget.artist.fetchCover();
        return widget.artist;
      }(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return NestedScrollView(
            key: scrollviewKey,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar.large(
                    expandedHeight: 300,
                    surfaceTintColor: Colors.transparent,
                    title: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99999),
                              child: Image(
                                  image: widget.artist.img ??
                                      MemoryImage(kTransparentImage)),
                            ),
                          ),
                          Padding(padding: EdgeInsets.only(left: 8)),
                          Text(
                            widget.artist.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ))
              ];
            },
            body: Column(
              children: [
                Padding(padding: EdgeInsets.only(top: 60)),
                Row(
                  children: [Text("Albums"), Divider()],
                ),
                Expanded(
                  child: AlbumViewGrid(
                    controller: widget.artist.getAlbumController(),
                    searchBar: false,
                    pushNamedNavigation: false,
                    listenOnly: true,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
