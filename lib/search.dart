import 'dart:async';

import 'package:airsonic/airsonic_connection.dart';
import 'package:flutter/material.dart';

class SearchingBar extends StatefulWidget {
  SearchingBar(this.result, {super.key});

  StreamController<AirSonicResult?> result;

  @override
  State<SearchingBar> createState() => _SearchingBarState();
}

class _SearchingBarState extends State<SearchingBar> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  Completer status = Completer();

  MediaPlayer mp = MediaPlayer.instance;

  bool clearBtn = false;

  final fieldText = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Material(
        elevation: 3,
        surfaceTintColor: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          decoration: BoxDecoration(
            color: ElevationOverlay.applySurfaceTint(
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surfaceTint,
                3),
            borderRadius: BorderRadius.circular(30),
          ),
          duration: const Duration(milliseconds: 250),
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: Center(
              child: TextField(
                controller: fieldText,
                //autofocus: true,
                onChanged: (keywords) {
                  //create local completer
                  var local = Completer();
                  status = local;

                  if (keywords.isEmpty) {
                    widget.result.add(null);
                    setState(() {
                      clearBtn = false;
                    });
                    return;
                  } else {
                    setState(() {
                      clearBtn = true;
                    });
                  }
                  Future.delayed(const Duration(milliseconds: 500))
                      .then((value) {
                    local.complete();
                    if (status.isCompleted) {
                      () async {
                        final r = await mp.search3(keywords);
                        widget.result.add(r);
                      }();
                    }
                  });
                },
                style: Theme.of(context).textTheme.bodyLarge,
                //sdtextAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  icon: const Icon(
                    Icons.search,
                  ),
                  suffixIcon: clearBtn
                      ? IconButton(
                          onPressed: () {
                            fieldText.clear();
                            widget.result.add(null);
                          },
                          icon: const Icon(Icons.close))
                      : null,
                  hintText: "Search",
                  isCollapsed: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
/* 
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  StreamController<SearchResult> result = StreamController();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [SearchingBar(result)],
        ),
        body: StreamBuilder(
          stream: result.stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return CustomScrollView(
                slivers: [
                  SliverFixedExtentList(
                      delegate: SliverChildListDelegate([
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 5.0),
                              child: Text(
                                "Artist",
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                            ),
                          ],
                        )
                      ]),
                      itemExtent: 75),
                  SliverGrid.builder(
                      itemCount: snapshot.requireData.artists.length,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                              childAspectRatio: 2.75,
                              maxCrossAxisExtent: 250,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16),
                      itemBuilder: ((context, index) {
                        final artists = snapshot.requireData.artists;
                        final artist = artists[index];
                        return ArtistCard(artist);
                      })),
                  SliverFixedExtentList(
                      delegate: SliverChildListDelegate([
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 5.0),
                              child: Text(
                                "Album",
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                            ),
                          ],
                        )
                      ]),
                      itemExtent: 75),
                  SliverGrid.builder(
                      itemCount: snapshot.requireData.albums.length,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                              childAspectRatio: 0.75,
                              maxCrossAxisExtent: 250,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16),
                      itemBuilder: ((context, index) {
                        final albums = snapshot.requireData.albums;
                        final album = albums[index];
                        return AlbumCard(album);
                      })),
                ],
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}
 */