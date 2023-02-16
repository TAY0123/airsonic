import 'package:flutter/material.dart';

class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Card(
          child: Row(
            children: const [Placeholder(), Text("Album")],
          ),
        ),
        Card(
          child: Row(
            children: const [Placeholder(), Text("Artist")],
          ),
        ),
        Card(
          child: Row(
            children: const [Placeholder(), Text("Folders")],
          ),
        ),
        Card(
          child: Row(
            children: const [Placeholder(), Text("Playlists")],
          ),
        ),
        Card(
          child: Row(
            children: const [Placeholder(), Text("Starred")],
          ),
        )
      ],
    );
  }
}
