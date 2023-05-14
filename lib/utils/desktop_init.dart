import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

Future<void> desktopWindowManagerInit() async {
  if (Platform.isLinux || Platform.isWindows && !kIsWeb) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      minimumSize: Size(450, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
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
