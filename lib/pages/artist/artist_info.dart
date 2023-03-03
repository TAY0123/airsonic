import 'package:airsonic/utils/airsonic_connection.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

import '../albums/layout/albums_grid.dart';

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
                    backgroundColor: Colors.transparent,
                    expandedHeight: 300,
                    automaticallyImplyLeading: false,
                    surfaceTintColor: Colors.transparent,
                    flexibleSpace: Padding(
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
                          const Padding(padding: EdgeInsets.only(left: 8)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Spacer(),
                                Text(
                                  widget.artist.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const Spacer()
                              ],
                            ),
                          ),
                          //monitor scroll controller to fade btn with icon
                          IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.play_arrow))
                        ],
                      ),
                    )),
              ];
            },
            body: Column(
              children: [
                const Padding(padding: EdgeInsets.only(top: 60)),
                Row(
                  children: const [Text("Albums")],
                ),
                const Divider(),
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
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
