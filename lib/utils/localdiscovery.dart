import 'dart:io';

import 'package:nsd/nsd.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDiscovery {
  bool enabled = false;
  final preferences = SharedPreferences.getInstance();
  List<Service> devices = [];

  Registration? registration;
  HttpServer? server;

  LocalDiscovery._() {
    () async {
      final storage = await preferences;
      if (storage.getBool("localDiscovery") ?? false) {
        start();
      }
    }();
  }

  void start() async {
    server = await HttpServer.bind(InternetAddress.anyIPv6, 56000);
    await server?.forEach((HttpRequest request) {
      request.response.write('Hello, world!');
      request.response.close();
    });

    registration = await register(
        const Service(name: "AirSonic-Test", type: '_http._tcp', port: 56000));
  }

  Future<void> scan() async {
    final discovery = await startDiscovery('_http._tcp');
    discovery.addListener(() {
      // discovery.services contains discovered services
      devices = discovery.services;
      print(discovery.services.last.name);
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
