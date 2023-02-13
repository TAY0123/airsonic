import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingPage extends StatefulWidget {
  SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final instance = SharedPreferences.getInstance();

  bool albumconbine = false;
  bool albumStyle = false;

  @override
  void initState() {
    super.initState();
    () async {
      final storage = await instance;
      albumconbine = storage.getBool("albumCombine") ?? false;
      albumStyle = storage.getBool("albumStyle") ?? false;
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
                  title: "Server",
                  children: [
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
                  title: "Album",
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("combine Album with same name: "),
                        Switch(
                          value: albumconbine,
                          onChanged: (value) {
                            storage.setBool("albumCombine", value);
                            setState(() {
                              albumconbine = !albumconbine;
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
                    )
                  ],
                )
              ];

              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 40),
                            child: e,
                          ))
                      .toList());
            } else {
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: const [
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

  final title;
  final List<Widget> children;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        maxWidth != null
            ? ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth!),
                child:
                    Column(mainAxisSize: MainAxisSize.min, children: children),
              )
            : Column(mainAxisSize: MainAxisSize.min, children: children)
      ],
    );
  }
}
