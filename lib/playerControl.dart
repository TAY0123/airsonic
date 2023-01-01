import 'package:flutter/material.dart';

class PlaybackControl extends StatefulWidget {
  const PlaybackControl({super.key});

  @override
  State<PlaybackControl> createState() => _PlaybackControlState();
}

class _PlaybackControlState extends State<PlaybackControl> {
  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
        heightFactor: 0.0725,
        widthFactor: 1,
        child: Card(
          color: Theme.of(context).primaryColor,
        ));
  }
}
