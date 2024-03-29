import 'dart:io';

import 'package:airsonic/utils/after_layout.dart';
import 'package:airsonic/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:transparent_image/transparent_image.dart';

import '../utils/airsonic_connection.dart';

class AlbumCard extends StatelessWidget {
  final Album album;
  final void Function(Album album)? onTap;
  final bool? hero;
  final Duration? delay;
  const AlbumCard(
      {super.key, required this.album, this.onTap, this.hero, this.delay});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    var albumTitle = Text(
      album.name,
      maxLines: 1,
      style: Theme.of(context).textTheme.titleMedium,
      overflow: TextOverflow.ellipsis,
    );
    var albumArtist = Text(
      album.artist?.name ?? "N.A",
      style: Theme.of(context).textTheme.bodySmall,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    var albumCover = Stack(
      children: [
        FutureBuilder(
            future: Future.delayed(delay ?? const Duration(milliseconds: 250)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CoverImage.fromAlbum(
                  album,
                  size: ImageSize.grid,
                  cache: true,
                );
              } else {
                return AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    child: Container(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: const Center(
                          child: Icon(Icons.music_note),
                        )),
                  ),
                );
              }
            }),
        if (album.combined)
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
                    highlightColor: colors.onPrimary.withOpacity(0.12),
                  ),
                  onPressed: null,
                  icon: const Icon(Icons.library_music)))
      ],
    );
    return RawMaterialButton(
      splashColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: () async {
        //TODO: add dialog to route so it display on url navigate
        //DialogRoute(context: context, builder: builder)
        if (onTap != null) {
          onTap!(album);
        }
      },
      child: Column(
        children: [
          hero != false
              ? Hero(
                  tag: "${album.id}-Cover}",
                  child: albumCover,
                )
              : albumCover,
          Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, top: 5),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: hero != false
                          ? Hero(
                              tag: "${album.id}-Title}",
                              child: albumTitle,
                            )
                          : albumTitle,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: hero != false
                          ? Hero(
                              tag: "${album.id}-Artist}",
                              child: albumArtist,
                            )
                          : albumArtist,
                    ),
                  ],
                ),
              ))
        ],
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
          vsync: this, duration: const Duration(milliseconds: 250));
      _animation = CurvedAnimation(parent: _controller, curve: Curves.linear);
    }
  }

  Animation<Color?>? fading;

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
    super.didChangeDependencies();
    if (widget.selectable != false) {
      if (widget.index?.value == widget.album.id) {
        background = Theme.of(context).colorScheme.onSurface.withOpacity(0.24);
        _controller.animateTo(1, duration: const Duration(microseconds: 0));
      }

      fading = _animation.drive<Color?>(
        ColorTween(
            begin: Colors.transparent,
            end: Theme.of(context).colorScheme.onSurface.withOpacity(0.24)),
      );
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
        child: RawMaterialButton(
          splashColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onPressed: () {
            if (widget.onTap != null) {
              widget.onTap!(widget.album);
            }
            widget.index?.value = widget.album.id;
          },
          child: Stack(
            children: [
              if (fading != null)
                AnimatedBuilder(
                  animation: fading!,
                  builder: (context, child) => Container(
                    color: fading!.value!,
                  ),
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
                                  cache: true,
                                ),
                              )
                            : Align(
                                alignment: Alignment.centerLeft,
                                child: CoverImage.fromAlbum(
                                  widget.album,
                                  size: ImageSize.avatar,
                                  cache: true,
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
                            const Padding(padding: EdgeInsets.only(top: 8)),
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
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          children: [
                            IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.favorite)),
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
  final Future<ImageProvider?>? data;

  final BoxFit fit;
  final ImageSize size;
  final Duration? fadeInDuration;
  final Radius? topLeft;
  final Radius? topRight;
  final Radius? bottomLeft;
  final Radius? bottomRight;
  final String coverId;
  final ImageProvider? placeholder;

  final MediaPlayer mp = MediaPlayer.instance;

  CoverImage(
    this.coverId, {
    super.key,
    this.fit = BoxFit.cover,
    this.data,
    this.size = ImageSize.grid,
    this.fadeInDuration = const Duration(milliseconds: 250),
    this.topLeft,
    this.topRight,
    this.bottomLeft,
    this.bottomRight,
    this.placeholder,
  });

  factory CoverImage.fromAlbum(
    Album album, {
    BoxFit fit = BoxFit.cover,
    ImageSize size = ImageSize.grid,
    bool cache = false,
    Duration? fadeInDuration = const Duration(milliseconds: 250),
    ImageProvider? placeholder,
  }) {
    if (album.image != null && album.image?.size == size) {
      return CoverImage("",
          fadeInDuration: fadeInDuration,
          placeholder: placeholder,
          fit: fit,
          data: Future.value(album.image!.image));
    } else {
      if (cache) {
        return CoverImage(
          "",
          fadeInDuration: fadeInDuration,
          fit: fit,
          size: size,
          data: () async {
            await album.fetchCover(size: size);
            return album.image?.image;
          }(),
        );
      } else {
        return CoverImage(
          album.coverArt,
          fadeInDuration: fadeInDuration,
          fit: fit,
          size: size,
        );
      }
    }
  }

  factory CoverImage.fromFileUri(
    Uri? uri, {
    BoxFit fit = BoxFit.cover,
    ImageSize size = ImageSize.grid,
    Duration? fadeInDuration = const Duration(milliseconds: 250),
    ImageProvider? placeholder,
  }) {
    if (uri == null) {
      return CoverImage("");
    }
    return CoverImage(
      "",
      placeholder: placeholder,
      fadeInDuration: fadeInDuration,
      data: Future.value(uri.isScheme("file")
          ? FileImage(File.fromUri(uri))
          : NetworkImage(uri.toString()) as ImageProvider),
      size: size,
      fit: fit,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert((placeholder == null && fadeInDuration != null) ||
        (placeholder != null && fadeInDuration == null));
    final ph = Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: const Center(
          child: Icon(Icons.music_note),
        ));

    fadeInEffect(context, child, frame, wasSynchronouslyLoaded) {
      return AnimatedCrossFade(
        duration: fadeInDuration!,
        firstCurve: Curves.easeInCubic,
        layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
          return Stack(
            children: [
              Positioned.fill(child: topChild),
              Positioned.fill(child: bottomChild)
            ],
          );
        },
        firstChild: ph,
        secondChild: child,
        crossFadeState: frame == null
            ? CrossFadeState.showFirst
            : CrossFadeState.showSecond,
      );
    }

    final content = ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: topLeft ?? const Radius.circular(12),
          topRight: topRight ?? const Radius.circular(12),
          bottomLeft: bottomLeft ?? const Radius.circular(12),
          bottomRight: bottomRight ?? const Radius.circular(12),
        ),
        child: FutureBuilder(
          future: () async {
            final result = await (data ?? mp.getCoverArt(coverId, size: size));
            return result;
          }(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final img = Image(
                frameBuilder: fadeInDuration == null ? null : fadeInEffect,
                image: snapshot.requireData!,
                fit: fit,
                errorBuilder: (context, error, stackTrace) => ph,
                filterQuality: fit == ImageSize.grid
                    ? FilterQuality.high
                    : FilterQuality.low,
              );
              if (fit != BoxFit.cover) {
                return Center(
                  child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      child: img),
                );
              } else {
                return img;
              }
            } else {
              return ph;
            }
          },
        ));

    return AspectRatio(aspectRatio: 1, child: content);
  }
}

/*
class _CoverImageState extends State<CoverImage> {
  late Widget placeholder;

  CrossFadeState status = CrossFadeState.showFirst;
  final MediaPlayer mp = MediaPlayer.instance;

  late Future<ImageProvider<Object>?> task;

  @override
  void initState() {
    super.initState();
    task = () async {
      final result = await (widget.data ??
          mp.getCoverArt(widget.coverId, size: widget.size));

      if (mounted && result != null) {
        setState(() {
          status = CrossFadeState.showSecond;
        });
      }
      return result;
    }();
  }

  @override
  void dispose() {
    task.ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: widget.topLeft ?? const Radius.circular(12),
        topRight: widget.topRight ?? const Radius.circular(12),
        bottomLeft: widget.bottomLeft ?? const Radius.circular(12),
        bottomRight: widget.bottomRight ?? const Radius.circular(12),
      ),
      child: AnimatedCrossFade(
          firstCurve: Curves.easeInCubic,
          layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
            return Stack(
              children: [
                Positioned.fill(child: topChild),
                Positioned.fill(child: bottomChild)
              ],
            );
          },
          firstChild: Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: const Center(
                child: Icon(Icons.music_note),
              )),
          secondChild: FutureBuilder(
            future: task,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final img = Image(
                  image: snapshot.requireData!,
                  fit: widget.fit,
                  filterQuality: widget.fit == ImageSize.grid
                      ? FilterQuality.high
                      : FilterQuality.low,
                );
                if (widget.fit != BoxFit.cover) {
                  return Center(
                    child: ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(12)),
                        child: img),
                  );
                } else {
                  return img;
                }
              } else {
                return Container();
              }
            },
          ),
          crossFadeState: status,
          duration: widget.fadeInDuration ?? const Duration(milliseconds: 250)),
    );

    return AspectRatio(aspectRatio: 1, child: content);
  }

  Widget img(BuildContext context, ImageProvider img) {
    return FadeInImage(
      fadeInCurve: Curves.easeInCubic,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: TransparentPlaceholder,
      placeholderErrorBuilder: (context, error, stackTrace) => placeholder,
      image: img,
      fit: widget.fit,
      imageErrorBuilder: (context, error, stackTrace) => Container(),
    );
  }
}
*/

class StackedAlbumImage extends StatefulWidget {
  final Widget child;
  const StackedAlbumImage({super.key, required this.child});

  @override
  State<StackedAlbumImage> createState() => _StackedAlbumImageState();
}

ImageProvider TransparentPlaceholder = MemoryImage(kTransparentImage);

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
            color: Theme.of(context).colorScheme.surfaceVariant,
            margin: const EdgeInsets.all(0),
            child: Container(),
          ),
        ),
        Positioned(
          left: height / 12,
          width: height,
          height: height,
          child: Card(
            color: Theme.of(context).colorScheme.surfaceVariant,
            elevation: 12,
            margin: const EdgeInsets.all(0),
            child: Container(),
          ),
        ),
        AfterLayout(
          callback: (value) {
            if (mounted) {
              setState(() {
                height = value.size.height;
              });
            }
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
  final List<Artist> artistList;

  const ArtistList(this.artistList, {super.key});

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
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
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
      _controller.animateTo(1, duration: const Duration(microseconds: 0));
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
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
                            const Padding(padding: EdgeInsets.only(left: 16)),
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
                                    icon: const Icon(Icons.favorite)),
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
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder(
                  stream: currentItemStream,
                  builder: (context, value) {
                    if (value.hasData) {
                      final currentItem = value.data!;
                      final currentSong = Song(currentItem.extras?["songId"]);
                      return GestureDetector(
                          onTap: () async {
                            final fetch = currentSong.getInfo();
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
                            return GestureDetector(
                                onTap: () async {
                                  final fetch = currentSong.getInfo();
                                  await fetch;
                                  Navigator.of(context).pushReplacementNamed(
                                    "/album/${currentSong.album?.id ?? ""}",
                                  );
                                },
                                child: cardContent(currentItem, context));
                          } else {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                        },
                      );
                    }
                  }),
            ),
          );
        } else {
          return const Card();
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
                        const Spacer(),
                        Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(right: 8.0),
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
                        const Padding(padding: EdgeInsets.only(bottom: 8)),
                        Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(right: 8.0),
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
        const Divider(),
        ButtonBar(
          children: [
            FilledButton.icon(
                onPressed: () async {
                  /*
                  final a = Song(currentItem.id);
                  final info = await a.getInfo();
                  Navigator.of(context).pushReplacementNamed(
                      "/album/${a.album?.id ?? ""}",
                      arguments: a.album);
                      */
                  final player = await mp.futurePlayer;
                  player.clear();
                  player.addPlaylist([currentItem]);
                  player.play();
                },
                //label: Text("Continue"),
                icon: Container(),
                label: const Icon(Icons.play_arrow))
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
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CoverImage(
            playlist.coverArt ?? "",
            bottomLeft: Radius.zero,
            topRight: Radius.zero,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.name ?? "",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text("Songs: ${playlist.songCount}")
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CardSwipeAction extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const CardSwipeAction({super.key, required this.child, this.onTap});

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
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    animation = _controller.drive(Tween(begin: 0, end: 40));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: widget.onTap,
        onSecondaryTap: () {
          if (animation.value > 20) {
            _controller.reverse();
          } else {
            _controller.forward();
          }
        },
        onHorizontalDragUpdate: (details) {
          // Note: Sensitivity is integer used when you don't want to mess up vertical drag
          int sensitivity = 8;
          if (details.delta.dx > sensitivity) {
            _controller.play();
          } else if (details.delta.dx < -sensitivity) {
            _controller.reverse();
          }
        },
        child: LayoutBuilder(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                              onPressed: () {}, icon: const Icon(Icons.add)),
                          IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.favorite)),
                          IconButton(
                              onPressed: () {}, icon: const Icon(Icons.delete)),
                        ],
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
