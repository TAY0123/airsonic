import Cocoa
import CoreAudio
import FlutterMacOS
import SwiftUI

@main
struct FlutterApp: App {
    @NSApplicationDelegateAdaptor(FlutterAppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MyView()
                .frame(minWidth: 499, idealWidth: 960, minHeight: 600, idealHeight: 600)
        }
        .windowStyle(.hiddenTitleBar).windowToolbarStyle(.unified)
    }
}

struct MyView: NSViewControllerRepresentable {
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
    
    typealias NSViewControllerType = NSViewController
    
    var close: (() -> Void)?
    
    func makeNSViewController(context: Context) -> NSViewController {
        // Return MyViewController instance
        let mp = MediaPlayer.shared()
        var c = FlutterDependencies()
        let controller = FlutterViewController(engine: c.flutterEngine, nibName: nil, bundle: nil)
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
                mp?.replaceCurrent(url: call.arguments as! String, result: result, cacheMusic: false)
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
            default:
                result(FlutterMethodNotImplemented)
                return
            }
        }
        
        return controller
    }
    
    static func dismantleNSViewController(_ nsViewController: Self.NSViewControllerType, coordinator: Self.Coordinator) {
        let c = nsViewController as! FlutterViewController
        c.engine.shutDownEngine()
    }
}

class AppDelegate: FlutterAppDelegate {}

class FlutterDependencies: ObservableObject {
    var flutterEngine = FlutterEngine(name: "flutterEngine", project: nil)
    init() {
        print("engine: ", flutterEngine.run(withEntrypoint: nil))
    }

    func re() {
        flutterEngine = FlutterEngine(name: "flutterEngine", project: nil)
        print("engine: ", flutterEngine.run(withEntrypoint: nil))
    }
}

