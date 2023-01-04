import 'package:airsonic/albumList.dart';
import 'package:airsonic/airsonicConnection.dart';
import 'package:airsonic/route.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:collection/collection.dart';

///although it accept an album but a empty album with only id inside should work
class AlbumInfo extends StatefulWidget {
  final Album album;
  final String pageRoute;
  final ImageProvider? img;

  final VoidCallback? close;

  const AlbumInfo(this.album,
      {this.close, this.img, this.pageRoute = "", super.key});

  @override
  State<AlbumInfo> createState() => _AlbumInfoState();
}

class _AlbumInfoState extends State<AlbumInfo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final mp = MediaPlayer.instance;
  late Future<Album> album;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    album = () async {
      final res = await mp.fetchAlbumInfo(widget.album.id);
      if (res.albums.isNotEmpty) {
        return res.albums[0];
      }
      return Album("", "", ""); //if error return a blank album item
    }();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > breakpoint - 90) {
        return Container(
          color: Theme.of(context).cardColor,
          child: FractionallySizedBox(
            heightFactor: 0.95,
            widthFactor: 0.95,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8),
                  child: Row(
                    children: [
                      FloatingActionButton(
                        child: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),
                Expanded(
                  flex: 8,
                  child: Row(
                    children: [
                      Hero(
                        tag: "${widget.album.id}-Cover}",
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            child: Center(
                              child: ClipRRect(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(12)),
                                  child: widget.img == null
                                      ? Container(
                                          color: Theme.of(context)
                                              .primaryColorDark,
                                        )
                                      : Image(
                                          fit: BoxFit.contain,
                                          image: widget.img!,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            color: Theme.of(context)
                                                .primaryColorDark,
                                          ),
                                        )),
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Hero(
                              tag: "${widget.album.id}-Title}",
                              child: Text(
                                widget.album.name,
                                maxLines: 2,
                                overflow: TextOverflow.fade,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            Hero(
                              tag: "${widget.album.id}-Artist}",
                              child: Text(
                                widget.album.artist?.name ?? "",
                                maxLines: 2,
                                overflow: TextOverflow.fade,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Align(
                    alignment: Alignment.centerLeft, child: Text("Songs")),
                Expanded(
                  flex: 6,
                  child: FutureBuilder(
                    future: album,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return ListView.separated(
                          itemCount: snapshot.requireData.songs?.length ?? 0,
                          separatorBuilder: (context, index) {
                            return const Divider();
                          },
                          itemBuilder: (context, index) {
                            final song = snapshot.requireData.songs![index];
                            return ListTile(
                              onTap: () {
                                mp.playPlaylist(snapshot.requireData.songs!,
                                    index: index);
                              },
                              leading: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.play_arrow_rounded)
                                ],
                              ),
                              title: Text(song.title),
                              subtitle: Text(song.artist?.name ??
                                  snapshot.requireData.artist?.name ??
                                  "Unknown"),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_printDuration(
                                      Duration(seconds: song.duration)))
                                ],
                              ),
                            );
                          },
                        );
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        );
      } else {
        return Container(
          color: Theme.of(context).cardColor,
          child: ListView(
            padding: EdgeInsets.all(10),
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8),
                child: Row(
                  children: [
                    FloatingActionButton(
                      child: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),
              Hero(
                tag: "${widget.album.id}-Cover}",
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  child: Container(
                      color: Theme.of(context).primaryColorDark,
                      child: widget.img == null
                          ? Container()
                          : Image(
                              image: widget.img!,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(),
                            )),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Hero(
                  tag: "${widget.album.id}-Title}",
                  child: Text(
                    widget.album.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Hero(
                  tag: "${widget.album.id}-Artist}",
                  child: Text(
                    widget.album.artist?.name ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              const Padding(padding: EdgeInsets.only(top: 10)),
              const Align(
                  alignment: Alignment.centerLeft, child: Text("Songs")),
              FutureBuilder(
                future: album,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Column(
                      children: snapshot.requireData.songs
                              ?.mapIndexed(((i, e) {
                                return ListTile(
                                  onTap: () {
                                    mp.playPlaylist(snapshot.requireData.songs!,
                                        index: i);
                                  },
                                  leading: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.play_arrow_rounded)
                                    ],
                                  ),
                                  title: Text(e.title),
                                  subtitle: Text(e.artist?.name ??
                                      snapshot.requireData.artist?.name ??
                                      "Unknown"),
                                );
                              }))
                              .expand<Widget>((e) sync* {
                                yield e;
                                yield const Divider();
                              })
                              .take(snapshot.requireData.songs?.length ?? 0 * 2)
                              .toList() ??
                          [],
                    );
                  } else {
                    return Column(
                      children: const [
                        CircularProgressIndicator(),
                      ],
                    );
                  }
                },
              )
            ],
          ),
        );
      }
    });
  }
}
