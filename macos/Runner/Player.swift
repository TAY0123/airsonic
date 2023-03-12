//
//  Sound.swift
//  MacAirSonic
//
//  Created by Tommy on 13/9/2022.
//

import AudioToolbox
import AVFoundation
import Foundation
import MediaPlayer
import NotificationCenter
import UserNotifications

// TODO: deinit? whatever it need to stay in bg anyway =w=
class Player: NSObject{
    static let audioPlayer: AVPlayer = .init()
    
    // Current Playing Song
    @Published var currentIndex = 0
    @Published var Duration: Int = 0
    @Published var format: String = "Unknown"
    @Published var sampleRate: Double = 44100
    @Published var bitRate: Int = 16
    
    // Current status of player
    @Published var Playing: Bool = false
    @Published var Stopped: Bool = true
    
    // Current playlist queue
    @Published var CurrentPosition: Double = 0.0
    
    @Published var volume: Binding<Double> = .init(get: { 1.0 }, set: { _ in })
    
    private static var sharedSoundManager: Player = {
        let manager = Player()
        
        return manager
    }()
    
    class func shared() -> Player { return sharedSoundManager }
    
    static var last = Date()
    
    // For in-App control
    func pause() {
        if Player.audioPlayer.currentTime().seconds.rounded(.awayFromZero) != 0 {
            Player.audioPlayer.currentTime().seconds
        }
        
        Player.audioPlayer.pause()
        
        Playing = false
        /*
         Task.detached {
             await MainActor.run {
                 self.CurrentPosition = Player.audioPlayer.currentTime().seconds
             }
         }
          */
    }
    
    func play() {
        if Player.audioPlayer.timeControlStatus == .playing {
            return
        }
        /*
         if Stopped {
             if playFromLastIndex { playItem(Playlist.count - 1) }
             else { playItem(0) }
             return
         }
          */
        Task.detached {
            await MainActor.run {
                Player.audioPlayer.play()
            }
            
            let cur = Player.audioPlayer.currentTime().seconds
        }
    }

    func playpause() {
        if Player.audioPlayer.timeControlStatus == .playing {
            pause()
        } else {
            play()
        }
    }
    
    func seek(_ second: Int) {
        print("seek to: ", second)
        Player.audioPlayer.seek(to: CMTime(seconds: Double(second), preferredTimescale: CMTimeScale(1000)), completionHandler: { [self]
            _ in
                CurrentPosition = Player.audioPlayer.currentItem?.currentTime().seconds ?? 0
        })
        
        Task {
            do {
                print("d: ", try await Player.audioPlayer.currentItem!.asset.load(.duration).seconds)
            } catch {}
        }
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
                         object: Player.audioPlayer.currentItem)
         
        Player.audioPlayer.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
        // if cacheMusic {  }
        
        // add binding volume
        volume = Binding(get: {
            Double(Player.audioPlayer.volume)
        }, set: {
            Player.audioPlayer.volume = Float($0)
            UserDefaults.standard.set($0, forKey: "volume")
        })

        Player.audioPlayer.addObserver(self,
                                       forKeyPath: #keyPath(AVPlayer.currentItem),
                                       options: [.old, .new],
                                       context: &playerItemContext)
    }
    
    private var playerItemContext = 0
    
    func playItem(_ url: String, cacheMusic: Bool) {
        if Player.audioPlayer.timeControlStatus == .playing {
            Player.audioPlayer.pause()
        }
            
        var item: AVPlayerItem
        if cacheMusic {
            item = CachingPlayerItem(url: URL(string: url)!, customFileExtension: "wav") // just set a common extension anyway coz seem avplayeritem will auto recognize it
        } else {
            item = AVPlayerItem(url: URL(string: url)!)
        }
        let i = item
        Player.audioPlayer.replaceCurrentItem(with: i)
        Player.audioPlayer.automaticallyWaitsToMinimizeStalling = false
        // if cacheMusic { Player.audioPlayer.automaticallyWaitsToMinimizeStalling = false }
        Player.audioPlayer.play()
            
        if Player.audioPlayer.error != nil {
            print("Player error: \(Player.audioPlayer.error!)")
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
                
            let metadataTask = Task.detached { () -> Double in
                do {
                    let formatInfo = try await Player.audioPlayer.currentItem?.asset.loadTracks(withMediaType: .audio)[0].load(.formatDescriptions)[0]
                    if formatInfo != nil {
                        self.format = formatInfo?.mediaSubType.description.trimmingCharacters(in:
                            .punctuationCharacters) ?? "Unknown"
                        let info: AudioStreamBasicDescription? = CMAudioFormatDescriptionGetStreamBasicDescription(formatInfo!)?.pointee
                        self.sampleRate = info?.mSampleRate ?? 44100
                        self.bitRate = Int(info?.mBitsPerChannel ?? 16)
                    }
                    // print("rate: ",try await Player.audioPlayer.currentItem!.asset.load(.preferredRate))
                        
                    print("accurate: ", try await Player.audioPlayer.currentItem!.asset.load(.providesPreciseDurationAndTiming))
                    
                    let duration = try await Player.audioPlayer.currentItem!.asset.load(.duration).seconds
                    print(duration)
                    self.Duration = Int(duration)
                } catch {
                    print("❌ media metadata read error: ", error)
                }
                return 0.0
            }
            
            self.CurrentPosition = 0
            // self.current = Int(Player.audioPlayer.currentTime().seconds.isNaN ? 0 : Player.audioPlayer.currentTime().seconds) //fetch second from player to calibrate
                        
            // self.current = Int(Player.audioPlayer.currentTime().seconds) //fetch second from player to calibrate
            Playing = true
                    
            Player.last = Date()
        }
    }
}
