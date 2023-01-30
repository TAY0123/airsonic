import 'dart:math';

import 'package:airsonic/album_info.dart';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:transparent_image/transparent_image.dart';

import 'airsonic_connection.dart';

class AlbumCard extends StatefulWidget {
  final Album album;
  final bool pushNamed;
  const AlbumCard(this.album, {super.key, required this.pushNamed});

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
        if (widget.pushNamed) {
          Navigator.pushNamed(context, "/album/${widget.album.id}",
              arguments: widget.album);
        } else {
          Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: Duration(milliseconds: 250),
                pageBuilder: (context, animation, secondaryAnimation) =>
                    Scaffold(
                  body: AlbumInfo(widget.album),
                ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
              ));
        }
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

class AlbumTile extends StatefulWidget {
  final Album album;
  final ValueNotifier<String> index;

  const AlbumTile(this.album, {super.key, required this.index});

  @override
  State<AlbumTile> createState() => _AlbumTileState();
}

class _AlbumTileState extends State<AlbumTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  bool full = false;
  bool selected = false;
  late CurvedAnimation _animation;
  late Color background = Theme.of(context).colorScheme.surfaceVariant;
  void indexUpdated() {
    if (widget.index.value == widget.album.id) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.index.value == widget.album.id) {
      selected = true;
    }
    widget.index.addListener(indexUpdated);
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 250));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.linear);
  }

  @override
  void dispose() {
    _animation.dispose();
    _controller.dispose();
    widget.index.removeListener(indexUpdated);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    if (widget.index.value == widget.album.id) {
      background = Theme.of(context).colorScheme.onSurface.withOpacity(0.24);
      _controller.animateTo(1, duration: Duration(microseconds: 0));
    }

    final fading = _animation.drive<Color?>(
      ColorTween(
          begin: Colors.transparent,
          end: Theme.of(context).colorScheme.onSurface.withOpacity(0.24)),
    );
    fading.addListener(() {
      setState(() {
        background = fading.value!;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 125,
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            widget.index.value = widget.album.id;
          },
          child: Stack(
            children: [
              Container(
                color: background,
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Row(
                    children: [
                      AlbumImage(
                        album: widget.album,
                      ),
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.only(left: 8, top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.album.name,
                              maxLines: 2,
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.album.artist?.name ?? "N.A",
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      )),
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Column(
                          children: [
                            IconButton(
                                onPressed: () {}, icon: Icon(Icons.favorite)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
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

class AlbumCardList extends StatelessWidget {
  List<Album> albumList;

  AlbumCardList(this.albumList, {super.key});

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
          leading: CircleAvatar(
            child: FutureBuilder(
              future: artist.fetchCover(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.requireData) {
                  return Image(
                    image: artist.img!,
                  );
                } else {
                  return Container(
                    color: Colors.black,
                  );
                }
              },
            ),
          ),
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

class ArtistTile extends StatefulWidget {
  final Artist artist;
  final ValueNotifier<String> index;

  const ArtistTile(this.artist, {super.key, required this.index});

  @override
  State<ArtistTile> createState() => _ArtistTileState();
}

class _ArtistTileState extends State<ArtistTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late CurvedAnimation _animation;

  bool full = false;
  late Color background = Colors.transparent;
  void indexUpdated() {
    if (widget.index.value == widget.artist.id) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void initState() {
    super.initState();

    widget.index.addListener(indexUpdated);
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 250));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.linear);
  }

  @override
  void dispose() {
    _animation.dispose();
    _controller.dispose();
    widget.index.removeListener(indexUpdated);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    if (widget.index.value == widget.artist.id) {
      background = Theme.of(context).colorScheme.onSurface.withOpacity(0.24);
      _controller.animateTo(1, duration: Duration(microseconds: 0));
    }

    final fading = _animation.drive<Color?>(
      ColorTween(
          begin: Colors.transparent,
          end: Theme.of(context).colorScheme.onSurface.withOpacity(0.24)),
    );
    fading.addListener(() {
      setState(() {
        background = fading.value!;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 125,
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceVariant,
        clipBehavior: Clip.antiAlias,
        //color: Theme.of(context).colorScheme.surfaceVariant,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            widget.index.value = widget.artist.id;
          },
          child: Stack(
            children: [
              Container(
                color: background,
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 80,
                        child: Row(
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: widget.artist.img == null
                                    ? FutureBuilder(
                                        future: widget.artist.fetchCover(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData &&
                                              snapshot.requireData &&
                                              widget.artist.img != null) {
                                            return Image(
                                              image: widget.artist.img!,
                                            );
                                          } else {
                                            return Container(
                                              width: 75,
                                              height: 75,
                                              color: Colors.black,
                                            );
                                          }
                                        })
                                    : Image(
                                        image: widget.artist.img!,
                                      ),
                              ),
                            ),
                            Padding(padding: EdgeInsets.only(left: 16)),
                            Expanded(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.artist.name,
                                    maxLines: 2,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "Album count: ${widget.artist.albumsCount}",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                    onPressed: () {},
                                    icon: Icon(Icons.favorite)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
