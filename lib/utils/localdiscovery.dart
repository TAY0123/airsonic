import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:airsonic/utils/airsonic_connection.dart';
import 'package:audio_service/audio_service.dart';
import 'package:http/http.dart' as http;
import 'package:nsd/nsd.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDiscovery {
  bool enabled = false;
  final preferences = SharedPreferences.getInstance();
  StreamController<List<Service>> devices = StreamController.broadcast();

  Registration? registration;
  HttpServer? server;

  LocalDiscovery._() {
    () async {
      final storage = await preferences;
      if (storage.getBool("localDiscovery") ?? false) {
        start();
        scan();
      }
    }();
  }

  Future<bool> send(List<MediaItem> item, Service device) async {
    try {
      await http.post(Uri.http(device.host ?? "", '/'),
          body: jsonEncode(item.map((e) => e.toJson()).toList()));
    } catch (e) {
      return false;
    }
    return true;
  }

  void start() async {
    try {
      server = await HttpServer.bind(InternetAddress.anyIPv6, 56005);
    } catch (e) {
      print(e);
    }
    server?.forEach((HttpRequest request) {
      () async {
        final content = await utf8.decodeStream(request);
        final res = jsonDecode(content);
        if (res == null) {
          request.response.write(jsonEncode({"status": false}));
        } else {
          List<dynamic> objects = res;
          final List<MediaItem> result = [];
          for (var element in objects) {
            try {
              result.add(MediaItem(
                  id: element["id"],
                  title: element["title"],
                  artist: element["artist"],
                  album: element["album"],
                  artUri: Uri.parse(element["artUri"]),
                  duration: Duration(seconds: element["duration"]),
                  extras: {
                    "songId": element["extras.songId"],
                    "coverArt": element["extras.coverArt"],
                    "duration": element["extras.duration"],
                  }));
            } catch (e) {
              continue;
            }
          }
          request.response.write(jsonEncode({"status": true}));
          final mp = await MediaPlayer.instance.futurePlayer;
          await mp.updateQueue(result);
          mp.play();
        }
        request.response.close();
      }();
    });

    print("start register");
    registration = await register(
        Service(name: "AirSonic-Test", type: '_http._tcp', port: 56000));
    print(registration.toString());
    updateRegister(null);
  }

  void updateRegister(MediaItem? current) async {}

  Future<void> scan() async {
    final discovery = await startDiscovery('_http._tcp');
    discovery.addListener(() {
      // discovery.services contains discovered services
      devices.add(discovery.services);
    });

    //stop after 10 seconds
    Future.delayed(const Duration(seconds: 10)).then(
      (value) async {
        await stopDiscovery(discovery);
      },
    );
  }

  void stop() async {
    if (registration != null) {
      await unregister(registration!);
    }
    await server?.close();
  }

  /// the one and only instance of this singleton
  static final instance = LocalDiscovery._();
}
