import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Card(
          child: Row(
            children: [Placeholder(), Text("Album")],
          ),
        ),
        Card(
          child: Row(
            children: [Placeholder(), Text("Artist")],
          ),
        ),
        Card(
          child: Row(
            children: [Placeholder(), Text("Folders")],
          ),
        ),
        Card(
          child: Row(
            children: [Placeholder(), Text("Playlists")],
          ),
        ),
        Card(
          child: Row(
            children: [Placeholder(), Text("Starred")],
          ),
        )
      ],
    );
  }
}
