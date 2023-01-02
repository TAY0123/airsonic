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

  const AlbumInfo(this.album, {this.pageRoute = "", super.key});

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
    return Row(
      children: [
        Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: FutureBuilder(
                future: Future.delayed(const Duration(milliseconds: 400))
                    .then((value) => mp.fetchCover(widget.album.coverArt)),
                builder: (context, imgsnapshot) {
                  Widget child;
                  if (imgsnapshot.hasData) {
                    child = Image(
                      image: imgsnapshot.requireData,
                      errorBuilder: (context, error, stackTrace) => Container(
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
          ],
        )
      ],
    );
  }
}
