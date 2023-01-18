import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

import 'airsonicConnection.dart';

class AlbumCard extends StatefulWidget {
  final Album album;

  const AlbumCard(this.album, {super.key});

  @override
  State<AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<AlbumCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  bool full = false;

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
    return GestureDetector(
      onTap: () async {
        /* context.pushTransparentRoute(AlbumInfo(
          widget.album,
          img: await img,
        )); */
        Navigator.pushNamed(context, "/album/${widget.album.id}",
            arguments: widget.album);
      },
      child: Card(
        child: Column(
          children: [
            Hero(
              tag: "${widget.album.id}-Cover}",
              child: AlbumImage(
                album: widget.album,
              ),
            ),
            Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, top: 5),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Hero(
                          tag: "${widget.album.id}-Title}",
                          child: Text(
                            widget.album.name,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Hero(
                          tag: "${widget.album.id}-Artist}",
                          child: Text(
                            widget.album.artist?.name ?? "N.A",
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
          ],
        ),
      ),
    );
  }
}

class AlbumImage extends StatelessWidget {
  final Album album;

  final BoxFit fit;

  const AlbumImage({
    super.key,
    required this.album,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (album.img != null) {
      content = fit == BoxFit.cover
          ? img()
          : Center(
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                child: img(),
              ),
            );
    } else {
      content = FutureBuilder(
        future: album.fetchCover(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.requireData) {
              if (fit == BoxFit.cover) {
                return img();
              } else {
                return Center(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    child: img(),
                  ),
                );
              }
            } else {
              return Container(
                color: Theme.of(context).primaryColorDark,
              );
            }
          } else {
            return Container(
              color: Theme.of(context).primaryColorDark,
            );
          }
        },
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: AspectRatio(
        aspectRatio: 1,
        child: fit == BoxFit.cover
            ? Container(
                child: content,
              )
            : content,
      ),
    );
  }

  FadeInImage img() {
    return FadeInImage(
      fadeInCurve: Curves.easeInCubic,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: MemoryImage(kTransparentImage),
      image: album.img ?? MemoryImage(kTransparentImage),
      fit: fit,
      imageErrorBuilder: (context, error, stackTrace) => Container(),
    );
  }
}

class ArtistList extends StatelessWidget {
  List<Artist> artistList;

  ArtistList(this.artistList, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView.builder(
        itemCount: artistList.length,
        itemBuilder: (context, index) {
          final artist = artistList[index];
          return ListTile(
            title: Text(artist.name),
          );
        },
      ),
    );
  }
}

class AlbumList extends StatelessWidget {
  List<Album> albumList;

  AlbumList(this.albumList, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView.builder(
        itemCount: albumList.length,
        itemBuilder: (context, index) {
          final artist = albumList[index];
          return ListTile(
            title: Text(artist.name),
          );
        },
      ),
    );
  }
}

class ArtistCard extends StatelessWidget {
  Artist artist;
  ArtistCard(this.artist, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: ListTile(
          leading: CircleAvatar(),
          title: Text(
            artist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            "Album count : ${artist.albumsCount}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
