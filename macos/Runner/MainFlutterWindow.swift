import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
    private var controller: FlutterViewController?
  
    var mp: MediaPlayer = .shared()
    
    override func awakeFromNib() {
        controller = FlutterViewController(project: nil)
        let windowFrame = frame
        contentViewController = controller
        setFrame(windowFrame, display: true)
        RegisterGeneratedPlugins(registry: controller!)
      
        let batteryChannel = FlutterMethodChannel(name: "samples.flutter.dev/mediaplayer",
                                                  binaryMessenger: controller!.engine.binaryMessenger)
      
        let playerStatusChannel = FlutterEventChannel(name: "samples.flutter.dev/mediaplayerStatus",
                                                      binaryMessenger: controller!.engine.binaryMessenger)
      
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

        super.awakeFromNib()
    }
    
    override func close() {
        controller?.dismiss(self)
        controller = nil
        super.close()
    }
}
