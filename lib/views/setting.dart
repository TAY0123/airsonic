import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/airsonic_connection.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late Future<SharedPreferences> instance;

  bool albumcombine = false;
  bool albumStyle = false;
  bool hideDuplicate = false;
  bool localDiscovery = false;
  bool cacheAudioFile = false;
  String format = "mp3";

  @override
  void initState() {
    super.initState();
    instance = () async {
      final storage = await SharedPreferences.getInstance();
      albumcombine = storage.getBool("albumCombine") ?? false;
      albumStyle = storage.getBool("albumStyle") ?? false;
      hideDuplicate = storage.getBool("hideDuplicate") ?? false;
      localDiscovery = storage.getBool("localDiscovery") ?? false;
      format = storage.getString("format") ?? "mp3";
      cacheAudioFile = storage.getBool("cacheAudioFile") ?? false;
      return storage;
    }();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
          future: instance,
          builder: (context, snapshots) {
            if (snapshots.hasData) {
              final storage = snapshots.requireData;
              final items = [
                Section(
                  title: Text(
                    "Server",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: FilledButton.icon(
                          onPressed: () {
                            MediaPlayer.instance.startScan();
                          },
                          icon: const Icon(Icons.search),
                          label: const Text("Start Scan")),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: TextFormField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Server',
                          ),
                          onChanged: (value) {
                            storage.setString("domain", value);
                          },
                          initialValue: storage.getString("domain"),
                          validator: (url) {
                            try {
                              final test = Uri.parse(url ?? "").isAbsolute;
                              if (!test) {
                                return "Please enter a valid url";
                              }
                            } catch (e) {
                              return "Please enter a valid url";
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: TextFormField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Username',
                          ),
                          onChanged: (value) {
                            storage.setString("username", value);
                          },
                          initialValue: storage.getString("username"),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: TextFormField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Password',
                          ),
                          onChanged: (value) {},
                          obscureText: true,
                        ),
                      ),
                    ),
                  ],
                ),
                Section(
                  title: Text(
                    "Album",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("combine Album with same name: "),
                        Switch(
                          value: albumcombine,
                          onChanged: (value) {
                            storage.setBool("albumCombine", value);
                            setState(() {
                              albumcombine = !albumcombine;
                            });
                          },
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Default album display style"),
                        Switch(
                          value: albumStyle,
                          onChanged: (value) {
                            storage.setBool("albumStyle", value);
                            setState(() {
                              albumStyle = !albumStyle;
                            });
                          },
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Hide duplicate song from album"),
                        Switch(
                          value: hideDuplicate,
                          onChanged: (value) {
                            storage.setBool("hideDuplicate", value);
                            setState(() {
                              hideDuplicate = !hideDuplicate;
                            });
                          },
                        )
                      ],
                    )
                  ],
                ),
                Section(
                    title: Text(
                      "Client",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: TextFormField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Audio Format',
                          ),
                          onChanged: (value) {
                            storage.setString("format", value);
                          },
                          initialValue: storage.getString("format") ?? "mp3",
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Enable local Discovery"),
                          Switch(
                            value: localDiscovery,
                            onChanged: (value) {
                              storage.setBool("localDiscovery", value);
                              setState(() {
                                localDiscovery = !localDiscovery;
                              });
                            },
                          ),
                        ],
                      )
                    ])
              ];

              return ListView(
                  children: items
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 40),
                            child: e,
                          ))
                      .toList());
            } else {
              return const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(),
                  Text("loading settings...")
                ]),
              );
            }
          }),
    );
  }
}

class Section extends StatelessWidget {
  const Section(
      {super.key, this.title, required this.children, this.maxWidth = 500});

  final Widget? title;
  final List<Widget> children;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 8.0), child: title),
        maxWidth != null
            ? ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth!),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: children),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: children)
      ],
    );
  }
}
