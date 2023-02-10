import 'dart:io';

import 'package:airsonic/after_layout.dart';
import 'package:airsonic/album_info.dart';
import 'package:audio_service/audio_service.dart';
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
    final colors = Theme.of(context).colorScheme;
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
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Hero(
              tag: "${widget.album.id}-Cover}",
              child: Stack(
                children: [
                  FutureBuilder(
                      future: Future.delayed(Duration(milliseconds: 500)),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return CoverImage.fromAlbum(
                            widget.album,
                            size: ImageSize.grid,
                          );
                        } else {
                          return AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: const Center(
                                  child: Icon(Icons.music_note),
                                )),
                          );
                        }
                      }),
                  if (widget.album.combined)
                    Positioned(
                        right: 8,
                        top: 8,
                        child: IconButton(
                            style: IconButton.styleFrom(
                              foregroundColor: colors.onPrimary,
                              backgroundColor: colors.primary,
                              disabledBackgroundColor: colors.primary,
                              disabledForegroundColor: colors.onPrimary,
                              hoverColor: colors.onPrimary.withOpacity(0.08),
                              focusColor: colors.onPrimary.withOpacity(0.12),
                              highlightColor:
                                  colors.onPrimary.withOpacity(0.12),
                            ),
                            onPressed: null,
                            icon: Icon(Icons.library_music)))
                ],
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
  final ValueNotifier<String>? index;
  final bool? selectable;
  final void Function(Album album)? onTap;

  const AlbumTile(
    this.album, {
    super.key,
    this.index,
    this.selectable,
    this.onTap,
  });

  @override
  State<AlbumTile> createState() => _AlbumTileState();
}

class _AlbumTileState extends State<AlbumTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  bool full = false;
  bool selected = false;
  late CurvedAnimation _animation;
  //late Color background = Theme.of(context).colorScheme.surfaceVariant;
  late Color background = Colors.transparent;
  void indexUpdated() {
    if (widget.index != null) {
      if (widget.index?.value == widget.album.id) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.index?.value == widget.album.id) {
      selected = true;
    }
    if (widget.selectable == true || widget.selectable == null) {
      widget.index?.addListener(indexUpdated);
      _controller = AnimationController(
          vsync: this, duration: Duration(milliseconds: 250));
      _animation = CurvedAnimation(parent: _controller, curve: Curves.linear);
    }
  }

  @override
  void dispose() {
    if (widget.selectable != false) {
      _animation.dispose();
      _controller.dispose();
    }
    widget.index?.removeListener(indexUpdated);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    if (widget.selectable != false) {
      if (widget.index?.value == widget.album.id) {
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
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 125,
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        //color: Theme.of(context).colorScheme.surfaceVariant,
        color: Colors.transparent,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (widget.onTap != null) {
              widget.onTap!(widget.album);
            }
            widget.index?.value = widget.album.id;
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
                      AspectRatio(
                        aspectRatio: 1.2,
                        child: widget.album.combined
                            ? StackedAlbumImage(
                                child: CoverImage.fromAlbum(
                                  widget.album,
                                  size: ImageSize.avatar,
                                ),
                              )
                            : Align(
                                alignment: Alignment.centerLeft,
                                child: CoverImage.fromAlbum(
                                  widget.album,
                                  size: ImageSize.avatar,
                                ),
                              ),
                      ),
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.album.name,
                              maxLines: 2,
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Padding(padding: EdgeInsets.only(top: 8)),
                            Text(
                              widget.album.artist?.name ?? "N.A",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
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

class CoverImage extends StatelessWidget {
  late Future<ImageProvider?> data;

  final BoxFit fit;
  final MediaPlayer mp = MediaPlayer.instance;

  late Widget placeholder;

  final ImageSize size;

  CoverImage(
    String coverId, {
    super.key,
    this.fit = BoxFit.cover,
    ImageProvider? provider,
    this.size = ImageSize.grid,
  }) {
    if (provider != null) {
      data = Future.value(provider);
      return;
    } else {
      data = mp.fetchCover(coverId, size: size);
    }
  }

  factory CoverImage.fromAlbum(
    Album album, {
    BoxFit fit = BoxFit.cover,
    ImageSize size = ImageSize.grid,
  }) {
    if (album.image != null && album.image?.size == size) {
      return CoverImage("", fit: fit, provider: album.image!.image);
    } else {
      return CoverImage(
        album.coverArt,
        fit: fit,
        size: size,
      );
    }
  }

  factory CoverImage.fromFileUri(
    Uri? uri, {
    BoxFit fit = BoxFit.cover,
    ImageSize size = ImageSize.grid,
  }) {
    if (uri == null) {
      return CoverImage("");
    }
    return CoverImage(
      "",
      provider: uri.isScheme("file")
          ? FileImage(File.fromUri(uri))
          : NetworkImage(uri.toString()) as ImageProvider,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    placeholder = Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: const Center(
          child: Icon(Icons.music_note),
        ));

    Widget content = FutureBuilder(
      future: data,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.requireData != null) {
            final displayImage = snapshot.requireData!;
            if (fit == BoxFit.cover) {
              return img(context, displayImage);
            } else {
              return Center(
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  child: img(context, displayImage),
                ),
              );
            }
          } else {
            return placeholder;
          }
        } else if (snapshot.hasError ||
            snapshot.connectionState == ConnectionState.done) {
          //TODO: fade in placeholder
          return placeholder;
        } else {
          return Container();
        }
      },
    );

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

  Widget img(BuildContext context, ImageProvider img) {
    return FadeInImage(
      fadeInCurve: Curves.easeInCubic,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: MemoryImage(kTransparentImage),
      placeholderErrorBuilder: (context, error, stackTrace) => placeholder,
      image: img,
      fit: fit,
      imageErrorBuilder: (context, error, stackTrace) => Container(),
    );
  }
}

class StackedAlbumImage extends StatefulWidget {
  final Widget child;
  const StackedAlbumImage({super.key, required this.child});

  @override
  State<StackedAlbumImage> createState() => _StackedAlbumImageState();
}

class _StackedAlbumImageState extends State<StackedAlbumImage> {
  double height = 0;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: height / 12 * 2,
          width: height,
          height: height,
          child: Card(
            elevation: 4,
            margin: EdgeInsets.all(0),
            child: Container(),
          ),
        ),
        Positioned(
          left: height / 12,
          width: height,
          height: height,
          child: Card(
            elevation: 8,
            margin: EdgeInsets.all(0),
            child: Container(),
          ),
        ),
        AfterLayout(
          callback: (value) {
            setState(() {
              height = value.size.height;
            });
          },
          child: AspectRatio(
            aspectRatio: 1,
            child: widget.child,
          ),
        ),
      ],
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

class DashboardCoverCard extends StatelessWidget {
  DashboardCoverCard({super.key});

  final MediaPlayer mp = MediaPlayer.instance;
  @override
  Widget build(BuildContext context) {
    final getCurrentAlbum = () async {
      return await mp.currentItem;
    }();
    return FutureBuilder(
      future: getCurrentAlbum,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final currentItemStream = snapshot.requireData;
          if (currentItemStream != null) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder(
                    stream: currentItemStream,
                    builder: (context, value) {
                      if (value.hasData) {
                        final currentItem = value.data!;
                        final currentSong = Song(currentItem.id);
                        final fetch = currentSong.getInfo();
                        return GestureDetector(
                            onTap: () async {
                              await fetch;
                              Navigator.of(context).pushReplacementNamed(
                                "/album/${currentSong.album?.id ?? ""}",
                              );
                            },
                            child: cardContent(currentItem, context));
                      } else {
                        return FutureBuilder(
                          future: mp.previousQueue,
                          builder: (context, snapshot) {
                            if (snapshot.hasData &&
                                snapshot.requireData.isNotEmpty) {
                              final currentItem = snapshot.requireData[0];
                              final currentSong = Song(currentItem.id);
                              final fetch = currentSong.getInfo();
                              return GestureDetector(
                                  onTap: () async {
                                    await fetch;
                                    Navigator.of(context).pushReplacementNamed(
                                      "/album/${currentSong.album?.id ?? ""}",
                                    );
                                  },
                                  child: cardContent(currentItem, context));
                            } else {
                              return Center(child: CircularProgressIndicator());
                            }
                          },
                        );
                      }
                    }),
              ),
            );
          } else {
            return Card();
          }
        } else {
          return Card();
        }
      },
    );
  }

  Widget cardContent(MediaItem currentItem, BuildContext context) {
    return Column(
      children: [
        Flexible(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              AspectRatio(
                  aspectRatio: 1,
                  child: CoverImage.fromFileUri(
                    currentItem.artUri,
                    size: ImageSize.grid,
                  )),
              Flexible(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentItem.title,
                          maxLines: 2,
                          style: Theme.of(context).textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Spacer(),
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Icon(Icons.album),
                            ),
                            Flexible(
                              child: Text(
                                currentItem.album ?? "",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Padding(padding: EdgeInsets.only(bottom: 8)),
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Icon(Icons.people),
                            ),
                            Flexible(
                                child: Text(
                              currentItem.artist ?? "",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )),
                          ],
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        Divider(),
        ButtonBar(
          children: [
            FilledButton.icon(
                onPressed: () async {
                  final a = Song(currentItem.id);
                  final info = await a.getInfo();
                  Navigator.of(context).pushReplacementNamed(
                      "/album/${a.album?.id ?? ""}",
                      arguments: a.album);
                },
                //label: Text("Continue"),
                icon: Container(),
                label: Icon(Icons.arrow_forward))
          ],
        ),
      ],
    );
  }
}

class PlayListCard extends StatelessWidget {
  const PlayListCard({super.key, required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Flexible(
              child: Row(
                children: [
                  CoverImage(playlist.coverArt ?? ""),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist.name ?? "",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text("Songs: ${playlist.songCount}")
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(),
            ButtonBar(
              children: [
                FilledButton.icon(
                    onPressed: () async {},
                    //label: Text("Continue"),
                    icon: Container(),
                    label: Icon(Icons.play_arrow))
              ],
            )
          ],
        ),
      ),
    );
  }
}

class CardSwipeAction extends StatefulWidget {
  final Widget child;
  const CardSwipeAction({super.key, required this.child});

  @override
  State<CardSwipeAction> createState() => _CardSwipeActionState();
}

class _CardSwipeActionState extends State<CardSwipeAction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 250));
    animation = _controller.drive(Tween(begin: 0, end: 40));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onSecondaryTap: () {
      if (animation.value > 20) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    }, onHorizontalDragUpdate: (details) {
      // Note: Sensitivity is integer used when you don't want to mess up vertical drag
      int sensitivity = 8;
      if (details.delta.dx > sensitivity) {
        _controller.play();
      } else if (details.delta.dx < -sensitivity) {
        _controller.reverse();
      }
    }, child: LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            SizedBox(
              width: 90,
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(onPressed: () {}, icon: Icon(Icons.add)),
                        IconButton(
                            onPressed: () {}, icon: Icon(Icons.favorite)),
                        IconButton(onPressed: () {}, icon: Icon(Icons.delete)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Positioned(
                  width: constraints.maxWidth - animation.value,
                  height: constraints.maxHeight,
                  left: animation.value,
                  child: child!,
                );
              },
              child: widget.child,
            )
          ],
        );
      },
    ));
  }
}
