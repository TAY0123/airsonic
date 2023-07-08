import 'package:airsonic/utils/navigation.dart';
import 'package:airsonic/views/login.dart';
import 'package:airsonic/views/setup/local.dart';
import 'package:flutter/material.dart';

class PageSourceSelection extends StatefulWidget {
  const PageSourceSelection({super.key});

  @override
  State<PageSourceSelection> createState() => _PageSourceSelectionState();
}

class _PageSourceSelectionState extends State<PageSourceSelection> {
  Source? _source;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Select source for player",
                style: textTheme.headlineMedium,
              ),
              const Spacer(
                flex: 4,
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _source = Source.subsonic;
                  });
                },
                child: ListTile(
                  leading: Radio<Source>(
                      value: Source.subsonic,
                      groupValue: _source,
                      onChanged: (a) {}),
                  title: const Text("Subsonic"),
                  subtitle: const Text(
                      "Add a library from a subsonic API capable server"),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _source = Source.local;
                  });
                },
                child: ListTile(
                  leading: Radio<Source>(
                      value: Source.local,
                      groupValue: _source,
                      onChanged: (a) {}),
                  title: const Text("Local"),
                  subtitle: const Text("Create library from local folder"),
                ),
              ),
              const Spacer(
                flex: 2,
              ),
              ButtonBar(
                children: [
                  FilledButton(
                      onPressed: () {
                        switch (_source) {
                          case Source.subsonic:
                            Navigator.of(context)
                                .push(createRoute(LoginPage()));
                            break;
                          default:
                            Navigator.of(context)
                                .push(createRoute(PageSetupLocalLibrary()));
                        }
                      },
                      child: Text("Next"))
                ],
              ),
              const Spacer(
                flex: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum Source { subsonic, local }
