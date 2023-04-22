import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> desktopWindowManagerInit() async {
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows && !kIsWeb) {
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
