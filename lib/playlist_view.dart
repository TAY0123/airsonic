import 'dart:async';

import 'package:airsonic/airsonic_connection.dart';
import 'package:airsonic/layout.dart';
import 'package:airsonic/playlist_info.dart';
import 'package:airsonic/search.dart';
import 'package:flutter/material.dart';

import 'card.dart';

class PlayListView extends StatefulWidget {
  const PlayListView({super.key});

  @override
  State<PlayListView> createState() => _PlayListViewState();
}

class _PlayListViewState extends State<PlayListView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  StreamController<AirSonicResult?> result = StreamController();

  MediaPlayer mp = MediaPlayer.instance;

  late Future<XMLResult> playlists;

  CrossFadeState addcard = CrossFadeState.showFirst;

  @override
  void initState() {
    super.initState();
    playlists = mp.getPlaylists();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: ResponsiveLayout(
          tablet: (context, constraints) {
            return FutureBuilder(
                future: playlists,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final currentPlaylist = snapshot.requireData.playlists;

                    return CustomScrollView(
                      slivers: [
                        SliverList(
                            delegate: SliverChildListDelegate([
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: SearchingBar(result),
                          )
                        ])),
                        SliverGrid.builder(
                          itemCount: snapshot.requireData.playlists.length + 1,
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 280,
                                  childAspectRatio: 0.75),
                          itemBuilder: (context, index) {
                            if (index == currentPlaylist.length) {
                              return createNewPlayList();
                            } else {
                              final playlist =
                                  snapshot.requireData.playlists[index];
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Dialog(
                                              child: Dialog(
                                                child: PlayListInfo(
                                                  playlist: playlist,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: PlayListCard(playlist: playlist)),
                              );
                            }
                          },
                        )
                      ],
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                });
          },
          mobile: (context, constraints) {
            return FutureBuilder(
                future: playlists,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final currentPlaylist = snapshot.requireData.playlists;
                    return CustomScrollView(
                      slivers: [
                        SliverList(
                            delegate: SliverChildListDelegate([
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: SearchingBar(result),
                          )
                        ])),
                        SliverGrid.builder(
                          itemCount: snapshot.requireData.playlists.length + 1,
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 525,
                                  childAspectRatio: 1.5),
                          itemBuilder: (context, index) {
                            if (index == currentPlaylist.length) {
                              return createNewPlayList();
                            } else {
                              final playlist =
                                  snapshot.requireData.playlists[index];
                              return CardSwipeAction(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Dialog(
                                            child: PlayListInfo(
                                              playlist: playlist,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: PlayListCard(playlist: playlist));
                            }
                          },
                        )
                      ],
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                });
          },
        ));
  }

  Widget createNewPlayList() {
    return GestureDetector(
        onTap: () {
          setState(() {
            if (addcard == CrossFadeState.showSecond) {
              addcard = CrossFadeState.showFirst;
            } else {
              addcard = CrossFadeState.showSecond;
            }
          });
        },
        child: AnimatedCrossFade(
            layoutBuilder:
                (topChild, topChildKey, bottomChild, bottomChildKey) {
              return Stack(
                children: [
                  Positioned.fill(child: topChild),
                  Positioned.fill(child: bottomChild)
                ],
              );
            },
            firstChild: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: Center(
                  child: Icon(
                Icons.add_circle_rounded,
                color: Theme.of(context).colorScheme.outline,
                size: 50,
              )),
            ),
            secondChild: Card(
                child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Flexible(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CoverImage(""),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Column(
                              children: const [
                                TextField(
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  autofocus: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ButtonBar(
                    children: [
                      FilledButton.icon(
                          onPressed: () async {},
                          //label: Text("Continue"),
                          icon: Container(),
                          label: const Icon(Icons.done)),
                    ],
                  )
                ],
              ),
            )),
            crossFadeState: addcard,
            duration: const Duration(milliseconds: 250)));
  }
}
