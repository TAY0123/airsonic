
import AudioToolbox
import AVFoundation
import Cocoa
import CoreAudio
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    
    // audio player
    let audioPlayer: AVPlayer = .init()
    
    var format: String = "Unknown"
    var sampleRate: Double = 44100
    var bitDepth: UInt32 = 16
    
    var Playing: Bool = false
    var Stopped: Bool = true
    
    var Duration: Double = 0
    var CurrentPosition: Double = 0.0
    
    var volume: Double = 1.0
    
    // gui
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    override func applicationDidFinishLaunching(_ notification: Notification) {
        let controller: FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController
        let batteryChannel = FlutterMethodChannel(name: "samples.flutter.dev/mediaplayer",
                                                  binaryMessenger: controller.engine.binaryMessenger)
        
        let playerStatusChannel = FlutterEventChannel(name: "samples.flutter.dev/mediaplayerStatus",
                                                      binaryMessenger: controller.engine.binaryMessenger)
        
        playerStatusChannel.setStreamHandler(self)
        batteryChannel.setMethodCallHandler {
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            // This method is invoked on the UI thread.
            switch call.method {
                case "add":
                    self?.replaceCurrent(url: call.arguments as! String, result: result, cacheMusic: false)
                case "play":
                    self?.play(result: result)
                case "pause":
                    self?.pause(result: result)
                case "seek":
                    self?.seek(to: call.arguments as! Int, result: result)
                case "stop":
                    self?.stop(result: result)
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
                window.makeKeyAndOrderFront(self)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        return true
    }
    
    // end of gui
    
    // audio player
    // For in-App control
    func pause() {
        if audioPlayer.currentTime().seconds.rounded(.awayFromZero) != 0 {
            CurrentPosition = audioPlayer.currentTime().seconds
        }
        
        audioPlayer.pause()
        
        Playing = false
        updateStatus()
        /*
         Task.detached {
         await MainActor.run {
         self.CurrentPosition = audioPlayer.currentTime().seconds
         }
         }
         */
    }
    
    func playAudio() {
        if audioPlayer.timeControlStatus == .playing {
            return
        }
        /*
         if Stopped {
         if playFromLastIndex { playItem(Playlist.count - 1) }
         else { playItem(0) }
         return
         }
         */
        audioPlayer.play()
        
        CurrentPosition = audioPlayer.currentTime().seconds
        Playing = true
        Stopped = false
        updateStatus()
    }
    
    func seek(_ second: Int) {
        print("seek to: ", second)
        audioPlayer.seek(to: CMTime(seconds: Double(second), preferredTimescale: CMTimeScale(1000)), completionHandler: {
            _ in
            self.CurrentPosition = self.audioPlayer.currentItem?.currentTime().seconds ?? 0
            self.updateStatus()
        })
    }
    
    @objc func playerDidFinishPlaying() {
        /* emit a stopped signal ? */
         Stopped = true
         updateStatus()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override private init() {
        super.init()
        
#if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback)
        } catch {
            print(error)
        }
#else
#endif
        
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(playerDidFinishPlaying),
                         name: .AVPlayerItemDidPlayToEndTime,
                         object: audioPlayer.currentItem)
        
        audioPlayer.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
        // if cacheMusic {  }
        
        // add binding volume
        
        audioPlayer.addObserver(self,
                                forKeyPath: #keyPath(AVPlayer.currentItem),
                                options: [.old, .new],
                                context: &playerItemContext)
    }
    
    private var playerItemContext = 0

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?)
    {
        // Only handle observations for the playerItemContext
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
            return
        }
        
        if keyPath == #keyPath(AVPlayer.currentItem) {
            let item: AVPlayerItem?
            if let statusitem = change?[.newKey] as? AVPlayerItem {
                item = statusitem
            } else {
                print("Stopped")
                Stopped = true
                return
            }
            // Switch over status value
            print("value: \(item)")
            
            Duration = 1 // set a 1 min timeout for fetching real duration from metadata
            Stopped = false
            
            Task.detached {
                do {
                    let formatInfo = try await self.audioPlayer.currentItem?.asset.loadTracks(withMediaType: .audio)[0].load(.formatDescriptions).first
                    if formatInfo != nil {
                        self.format = formatInfo?.mediaSubType.description.trimmingCharacters(in:
                            .punctuationCharacters) ?? "Unknown"
                        let info: AudioStreamBasicDescription? = CMAudioFormatDescriptionGetStreamBasicDescription(formatInfo!)?.pointee
                        self.sampleRate = info?.mSampleRate ?? 44100
                        self.changeOutputFormat()
                    }
                    // print("rate: ",try await audioPlayer.currentItem!.asset.load(.preferredRate))
                    
                    print("accurate: ", try await self.audioPlayer.currentItem!.asset.load(.providesPreciseDurationAndTiming))
                    
                    let duration = try await self.audioPlayer.currentItem!.asset.load(.duration).seconds
                    self.Duration = duration
                    self.updateStatus()
                } catch {
                    print("❌ media metadata read error: ", error)
                }
            }
            
            self.CurrentPosition = 0
            // self.current = Int(Player.audioPlayer.currentTime().seconds.isNaN ? 0 : audioPlayer.currentTime().seconds) //fetch second from player to calibrate
            
            // self.current = Int(Player.audioPlayer.currentTime().seconds) //fetch second from player to calibrate
            Playing = true
        }
    }
    
    public func onListen(withArguments arguments: Any?,
                         eventSink: @escaping FlutterEventSink) -> FlutterError?
    {
        self.eventSink = eventSink
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerDidFinishPlaying),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: audioPlayer.currentItem)
        return nil
    }
    
    // music player
    private func replaceCurrent(url: String, result: FlutterResult, cacheMusic: Bool) {
        var item: AVPlayerItem
        if cacheMusic {
            item = CachingPlayerItem(url: URL(string: url)!, customFileExtension: "wav") // just set a common extension anyway coz seem avplayeritem will auto recognize it
        } else {
            item = AVPlayerItem(url: URL(string: url)!)
        }
        let i = item
        audioPlayer.replaceCurrentItem(with: i)
        audioPlayer.automaticallyWaitsToMinimizeStalling = false
        result(nil)
    }
    
    private func play(result: FlutterResult) {
        print("play pressed")
        // if cacheMusic { audioPlayer.automaticallyWaitsToMinimizeStalling = false }
        playAudio()
        result(nil)
    }
    
    private func pause(result: FlutterResult) {
        print("pause pressed")
        pause()
        result(nil)
    }
    
    private func stop(result: FlutterResult) {
        audioPlayer.pause()
        Stopped = true
        Playing = false
        updateStatus()
        result(nil)
    }
    
    private func seek(to: Int, result: FlutterResult) {
        seek(to)
        updateStatus()
        result(nil)
    }
    
    private func updateStatus() {
        guard let eventSink = eventSink else {
            return
        }
        
        let data: [String: Any] = [
            "duration": Duration,
            "position": CurrentPosition,
            "playing": Playing,
            "stopped": Stopped,
            "format": format,
            "sampleRate": sampleRate,
            "bitRate": bitDepth,
            "volume": volume,
        ]
        print(data)
        eventSink(data)
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        return nil
    }
    
    func getAllAudioDevices() -> [AudioDeviceID] {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
            
        var dataSize: UInt32 = 0
        var deviceCount: UInt32 = 0
        var deviceIds: [AudioDeviceID] = []
            
        // Get the required data size
        let error = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
            
        if error != 0 {
            return []
        }
            
        // Calculate the number of devices
        deviceCount = dataSize / UInt32(MemoryLayout<AudioDeviceID>.size)
            
        // Allocate memory for the device IDs
        deviceIds = [AudioDeviceID](repeating: AudioDeviceID(), count: Int(deviceCount))
            
        return deviceIds
    }

    public func changeOutputFormat() {
        print("b: \(bitDepth) r: \(sampleRate)")
        var outputDeviceID = AudioDeviceID(0)
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        let audioObjectID = AudioObjectID(kAudioObjectSystemObject)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        // Get the ID of the default output device
        let status = AudioObjectGetPropertyData(
            audioObjectID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &outputDeviceID
        )
        
        if status == noErr {
            // Set the sample rate of the output device to 48000 Hz
            
            propertyAddress.mSelector = kAudioDevicePropertyNominalSampleRate
            dataSize = UInt32(MemoryLayout<Float64>.size)
            var status = AudioObjectSetPropertyData(
                outputDeviceID,
                &propertyAddress,
                0,
                nil,
                dataSize,
                &sampleRate
            )
            
            if status != noErr {
                print("Error setting sample rate: \(status)")
            }
            
        } else {
            print("Error getting default output device ID: \(status)")
        }
    }
}
