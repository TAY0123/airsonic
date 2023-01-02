import 'package:airsonic/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/animation/animation_controller.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/ticker_provider.dart';

///although it accept an album but a empty album with only id inside should work
class AlbumInfo extends StatefulWidget {
  final Album album;
  final String pageRoute;
  final Future<ImageProvider?> imgcache;

  final VoidCallback close;

  const AlbumInfo(this.album, this.close, this.imgcache,
      {this.pageRoute = "", super.key});

  @override
  State<AlbumInfo> createState() => _AlbumInfoState();
}

class _AlbumInfoState extends State<AlbumInfo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final mp = MediaPlayer.instance;

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
    return Card(
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
                    child: Icon(Icons.close),
                    onPressed: () => widget.close(),
                  )
                ],
              ),
            ),
            Expanded(
              flex: 8,
              child: Row(
                children: [
                  Hero(
                    tag: "albumCardCover",
                    createRectTween: (Rect? begin, Rect? end) {
                      return MaterialRectCenterArcTween(begin: begin, end: end);
                    },
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      child: FutureBuilder(
                        future: widget.imgcache, //todo fetch original image
                        builder: (context, imgsnapshot) {
                          Widget child;
                          if (imgsnapshot.hasData && imgsnapshot.data != null) {
                            child = Image(
                              fit: BoxFit.fitHeight,
                              filterQuality: FilterQuality.high,
                              image: imgsnapshot.requireData!,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: Theme.of(context).primaryColorDark,
                              ),
                            );
                          } else {
                            child = Container(
                              color: Theme.of(context).primaryColorDark,
                            );
                          }
                          return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: child);
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.album.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          widget.album.artist?.name ?? "",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  Spacer()
                ],
              ),
            ),
            Spacer(),
            Align(alignment: Alignment.centerLeft, child: Text("Songs")),
            Expanded(
                flex: 6,
                child: ListView(
                  children: [Text("test")],
                ))
          ],
        ),
      ),
    );
  }
}
