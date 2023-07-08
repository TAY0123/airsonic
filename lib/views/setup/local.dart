import 'dart:io';

import 'package:airsonic/utils/navigation.dart';
import 'package:airsonic/views/setup/local_scan.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class PageSetupLocalLibrary extends StatefulWidget {
  const PageSetupLocalLibrary({super.key});

  @override
  State<PageSetupLocalLibrary> createState() => _PageSetupLocalLibraryState();
}

class _PageSetupLocalLibraryState extends State<PageSetupLocalLibrary> {
  List<String> dir = [];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Create library",
                style: textTheme.headlineMedium,
              ),
              const Spacer(),
              SizedBox(
                height: MediaQuery.of(context).size.height / 2,
                child: ListView(
                  children: dir
                      .mapIndexed((index, element) => ListTile(
                            title: Text(
                              element,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            trailing: IconButton(
                                onPressed: () {
                                  setState(() {
                                    dir.removeAt(index);
                                  });
                                },
                                icon: const Icon(Icons.delete)),
                          ))
                      .expand((element) sync* {
                    yield element;
                    yield const Divider();
                  }).toList(),
                ),
              ),
              const Spacer(),
              ButtonBar(
                alignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                      onPressed: () async {
                        String? selectedDirectory =
                            await FilePicker.platform.getDirectoryPath();

                        if (selectedDirectory != null) {
                          //if user picked a folder
                          if (dir.contains(selectedDirectory)) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                                content: const Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text("Directory alreay exist"),
                                    ),
                                  ],
                                )));
                            return;
                          }
                          setState(() {
                            dir.add(selectedDirectory);
                          });
                        }
                      },
                      child: const Text("Select a folder")),
                  if (dir.isNotEmpty)
                    FilledButton(
                        onPressed: () {
                          Navigator.of(context)
                              .push(createRoute(PageSetupLocalScan()));
                        },
                        child: const Text("Next"))
                ],
              ),
              const Spacer(
                flex: 2,
              )
            ],
          ),
        ),
      ),
    );
  }
}
