import Cocoa
import CoreAudio
import FlutterMacOS
import SwiftUI

@main
struct FlutterApp: App {
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
    
    func makeNSViewController(context: Context) -> NSViewController {
        // Return MyViewController instance
        let mp = MediaPlayer.shared()
        let engine = FlutterEngine(name: "a", project: nil)
        print("engine: ", engine.run(withEntrypoint: nil))
        let controller = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
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
}

class AppDelegate: FlutterAppDelegate {
    private var eventSink: FlutterEventSink?
    private final var mp = MediaPlayer.shared()
 
    // gui
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
 
    override func applicationWillBecomeActive(_ notification: Notification) {
        print(notification.name)
    }
 
    override func applicationDidFinishLaunching(_ notification: Notification) {
        let controller: FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController
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
    }
 
    override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in NSApp.windows {
                if !window.isVisible {
                    window.setIsVisible(true)
                }
                reOpen(window: window)
                window.makeKeyAndOrderFront(self)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        return true
    }
 
    // end of gui
 
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        return nil
    }
 
    func reOpen(window: NSWindow) {
        let engine = FlutterEngine(name: UUID().uuidString, project: nil)
        print("engine: ", engine.run(withEntrypoint: nil))
        let controller = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
        RegisterGeneratedPlugins(registry: controller)
        window.contentViewController = controller
 
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
    }
}
 
