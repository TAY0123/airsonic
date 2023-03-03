import 'dart:io';

import 'package:airsonic/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

Future<void> desktopWindowManagerInit() async {
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows && !kIsWeb) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = WindowOptions(
      size: const Size(1280, 720),
      minimumSize: const Size(450, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle:
          Platform.isMacOS ? TitleBarStyle.hidden : TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    //windowManager.addListener(MyWindowHandler());
  }
}


/*
class MyWindowHandler extends WindowListener {
  bool closed = false;

  @override
  void onWindowEvent(String eventName) {
    print('[WindowManager] onWindowEvent: $eventName');
  }

  @override
  void onWindowClose() {
    closed = true;
    rootNavigatorKey?.currentState?.pushAndRemoveUntil(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
    ), (route) => false);
  }

  @override
  void onWindowRestore() {
    print("restored");
    rootNavigatorKey?.currentState?.pushNamed("/dashboard");
  }

  @override
  void onWindowFocus() {
    if (closed) {
      closed = false;
      rootNavigatorKey?.currentState?.pushNamed("/dashboard");
    }
  }
}
*/
