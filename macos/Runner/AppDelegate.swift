
import AudioToolbox
import AVFoundation
import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    
    // audio player
    let audioPlayer: AVPlayer = .init()
    
    var format: String = "Unknown"
    var sampleRate: Double = 44100
    var bitRate: Int = 16
    
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
                case "play":
                    self?.play(url: call.arguments as! String, result: result)
                case "pause":
                    self?.pause(result: result)
                case "seek":
                    self?.seek(to: call.arguments as! Int, result: result)
                
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
    
    func play() {
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
        updateStatus()
    }
    
    func playpause() {
        if audioPlayer.timeControlStatus == .playing {
            self.pause()
        } else {
            self.play()
        }
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
        
        /*
         if currentIndex+1 > Playlist.count {
         Stopped = true
         return
         }
         self.currentIndex += 1
         playItem(self.currentIndex)
         */
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
    
    func playItem(_ url: String, cacheMusic: Bool) {
        if audioPlayer.timeControlStatus == .playing {
            audioPlayer.pause()
        }
        
        var item: AVPlayerItem
        if cacheMusic {
            item = CachingPlayerItem(url: URL(string: url)!, customFileExtension: "wav") // just set a common extension anyway coz seem avplayeritem will auto recognize it
        } else {
            item = AVPlayerItem(url: URL(string: url)!)
        }
        let i = item
        audioPlayer.replaceCurrentItem(with: i)
        audioPlayer.automaticallyWaitsToMinimizeStalling = false
        // if cacheMusic { audioPlayer.automaticallyWaitsToMinimizeStalling = false }
        audioPlayer.play()
        
        if audioPlayer.error != nil {
            print("Player error: \(audioPlayer.error!)")
        }
    }
    
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
            
            Task.detached { () -> Double in
                do {
                    let formatInfo = try await self.audioPlayer.currentItem?.asset.loadTracks(withMediaType: .audio)[0].load(.formatDescriptions)[0]
                    if formatInfo != nil {
                        self.format = formatInfo?.mediaSubType.description.trimmingCharacters(in:
                            .punctuationCharacters) ?? "Unknown"
                        let info: AudioStreamBasicDescription? = CMAudioFormatDescriptionGetStreamBasicDescription(formatInfo!)?.pointee
                        self.sampleRate = info?.mSampleRate ?? 44100
                        self.bitRate = Int(info?.mBitsPerChannel ?? 16)
                    }
                    // print("rate: ",try await audioPlayer.currentItem!.asset.load(.preferredRate))
                    
                    print("accurate: ", try await self.audioPlayer.currentItem!.asset.load(.providesPreciseDurationAndTiming))
                    
                    let duration = try await self.audioPlayer.currentItem!.asset.load(.duration).seconds
                    self.Duration = duration
                    self.updateStatus()
                } catch {
                    print("❌ media metadata read error: ", error)
                }
                return 0.0
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
    private func play(url: String, result: FlutterResult) {
        playItem(url, cacheMusic: false)
    }
    
    private func pause(result: FlutterResult) {
        self.pause()
    }
    
    private func stop(result: FlutterResult) {
        self.pause()
    }
    
    private func seek(to: Int, result: FlutterResult) {
        self.seek(to)
    }
    
    private func updateStatus() {
        guard let eventSink = eventSink else {
            return
        }
        
        let data: [String: Any] = [
            "duration": Duration,
            "position": CurrentPosition,
            "playing": Playing,
        ]
        eventSink(data)
    }
    
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        return nil
    }
}
