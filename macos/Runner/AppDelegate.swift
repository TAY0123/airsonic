import Cocoa
import CoreAudio
import FlutterMacOS
import SwiftUI

@main
struct FlutterApp: App {
    @NSApplicationDelegateAdaptor(FlutterAppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MyView().ignoresSafeArea(.all)
                .frame(minWidth: 499, idealWidth: 960, minHeight: 600, idealHeight: 600)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}

struct MyView: NSViewControllerRepresentable {
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
    
    typealias NSViewControllerType = NSViewController
    
    func makeNSViewController(context: Context) -> NSViewController {
        // Return MyViewController instance
        let mp = mpWrapper()
        let flutterEngine = FlutterEngine(name: "flutterEngine", project: nil)
        flutterEngine.run(withEntrypoint: nil)
        let controller = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
        RegisterGeneratedPlugins(registry: controller)
        let batteryChannel = FlutterMethodChannel(name: "samples.flutter.dev/mediaplayer",
                                                  binaryMessenger: controller.engine.binaryMessenger)
        
        let playerStatusChannel = FlutterEventChannel(name: "samples.flutter.dev/mediaplayerStatus",
                                                      binaryMessenger: controller.engine.binaryMessenger)
        
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
        return controller
    }
    
    static func dismantleNSViewController(_ nsViewController: Self.NSViewControllerType, coordinator: Self.Coordinator) {
        
        //should find a more elegant way to do this
        let mp = MediaPlayer.shared()
        mp.engineClosed = true
        mp.reg(es: nil)
        let controller = nsViewController as! FlutterViewController
        controller.engine.shutDownEngine()
        
    }
}
