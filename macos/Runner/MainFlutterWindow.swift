import Cocoa
import FlutterMacOS

/*
 class MainFlutterWindow: NSWindow {
 private var controller: FlutterViewController?
 
 var mp: MediaPlayer = .shared()
 
 override func restoreUserActivityState(_ userActivity: NSUserActivity) {}
 
 override func awakeFromNib() {
 let engine = FlutterEngine(name: "a", project: nil)
 print("engine: ", engine.run(withEntrypoint: nil))
 controller = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
 
 let windowFrame = frame
 contentViewController = controller
 setFrame(windowFrame, display: true)
 RegisterGeneratedPlugins(registry: controller!)
 
 super.awakeFromNib()
 }
 
 override func close() {
 print("engine closed")
 controller?.engine.shutDownEngine()
 super.close()
 }
 }
 */
