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
          return Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99999),
                      child: Image(
                          image: widget.artist.img ??
                              MemoryImage(kTransparentImage)),
                    ),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          widget.artist.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    )),
                  ],
                ),
              ),
              Expanded(
                  flex: 2,
                  child: AlbumViewGrid(
                    controller: widget.artist.getAlbumController(),
                  ))
            ],
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
