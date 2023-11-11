import UIKit
import Flutter
import CoreAudio

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      let mp = mpWrapper()
      
      let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
      
      let batteryChannel = FlutterMethodChannel(name: "samples.flutter.dev/mediaplayer",
                                                        binaryMessenger: controller.binaryMessenger)
              
              let playerStatusChannel = FlutterEventChannel(name: "samples.flutter.dev/mediaplayerStatus",
                                                            binaryMessenger: controller.binaryMessenger)
              
              playerStatusChannel.setStreamHandler(mp)
              batteryChannel.setMethodCallHandler {
                  [weak mp] (call: FlutterMethodCall, result: @escaping FlutterResult) in
                  // This method is invoked on the UI thread.
                  
                  switch call.method {
                  case "add":
                      let t = call.arguments as! [String: Any]
                      let item = MediaItem(url: t["url"] as! String,
                                           title: t["title"] as? String ?? "",
                                           cover : t["cover"] as? String ?? "",
                                           album: t["album"] as? String ?? "",
                                           artist: t["artist"] as? String ?? "",
                                           data: t["data"] as? [String: Any] ?? [:])
                  
                      mp?.addToPlaylist(media: item, result: result)
                    
                  case "play":
                      mp?.play(result: result)
                  case "pause":
                      mp?.pause(result: result)
                  case "seek":
                      mp?.seek(to: call.arguments as! Int, result: result)
                  case "stop":
                      mp?.stop(result: result)
                  case "getPosition":
                      mp?.getPosition(result: result)
                  case "update":
                      mp?.update(result: result)
                  case "clear":
                      mp?.clearPlaylist(result: result)
                  case "seekIndex":
                      mp?.seekIndex(index: call.arguments as! Int, result: result)
                  default:
                      result(FlutterMethodNotImplemented)
                      return
                  }
                  mp?.update()
              }
      
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
