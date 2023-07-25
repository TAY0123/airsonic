//
//  Sound.swift
//  MacAirSonic
//
//  Created by Tommy on 13/9/2022.
//

import AudioToolbox
import AVFoundation
import CoreAudio
import SwiftUI

import MediaPlayer

import FlutterMacOS
import Opus

struct MediaItem {
    var url: String = ""
    var title: String = ""
    var cover: String = ""
    var album: String = ""
    var artist: String = ""
    var data: [String: Any]
    
    func toDictionary() -> [String: Any] {
        return [
            "url": url,
            "title": title,
            "cover": cover,
            "album": album,
            "artist": artist,
            "data": data,
        ]
    }
}

class mpWrapper: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    
    private var mp = MediaPlayer.shared()
    
    public func onListen(withArguments arguments: Any?,
                         eventSink: @escaping FlutterEventSink) -> FlutterError?
    {
        
        self.eventSink = eventSink
        mp.engineClosed = false
        mp.reg(es: eventSink)
        
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        mp.engineClosed = true
        mp.reg(es: nil)
        
        eventSink = nil
        return nil
    }
    
    func play(result: FlutterResult) {
        // if cacheMusic { audioPlayer.automaticallyWaitsToMinimizeStalling = false }
        mp.play()
        result(nil)
    }
    
    public func pause(result: FlutterResult) {
        mp.pause()
        result(nil)
    }
    
    public func stop(result: FlutterResult) {
        mp.stop()
        result(nil)
    }
    
    // seek to a index
    public func seekIndex(index: Int, result: FlutterResult) {
        mp.seekIndex(index: index)
        result(nil)
    }
    
    public func addToPlaylist(media: MediaItem, index: Int = -1, result: FlutterResult) {
        mp.addToPlaylist(media: media, index: index)
        result(nil)
    }
    
    // seek to a position (seconds)
    public func seek(to: Int, result: FlutterResult) {
        mp.seek(to)
        result(nil)
    }
    
    //change to update in future
    func getPosition(result: FlutterResult) {
        result(mp.audioPlayer.currentItem?.currentTime().seconds)
    }
    
    func update(result: FlutterResult) {
        mp.updateStatus()
        result(nil)
    }
    
    func update() {
        mp.updateStatus()
    }
    
    public func clearPlaylist(result: FlutterResult) {
        mp.clearPlaylist()
        result(nil)
    }
}

class MediaPlayer: NSObject {
    // shared
    public var engineClosed = false
    
    // audio player
    let audioPlayer: AVPlayer = .init()
    
    var format: String = "Unknown"
    var sampleRate: Double = 44100
    var bitDepth: UInt32 = 16
    
    var Playing: Bool = false
    var Stopped: Bool = true
    
    var Duration: Double = 0
    var CurrentPosition: Double = 0.0
    
    var cache: Bool = false
    
    var volume: Double = 1.0
    
    var playlist: [MediaItem] = []
    
    var currentIndex = 0
    
    private let mp = MPNowPlayingInfoCenter.default()
    private let remoteCommandCenter = MPRemoteCommandCenter.shared()
   
    private var playerItemContext = 0
    private var eventSink:FlutterEventSink?
    
    class func shared() -> MediaPlayer { return sharedSoundManager }
    
    private static var sharedSoundManager: MediaPlayer = {
        let manager = MediaPlayer()
        return manager
    }()
    
    public func reg (es: FlutterEventSink?){
        eventSink = es
    }
    
    override init() {
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
        
        audioPlayer.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
        // if cacheMusic {  }
        
        // add binding volume
        
        audioPlayer.addObserver(self,
                                forKeyPath: #keyPath(AVPlayer.currentItem),
                                options: [.old, .new],
                                context: &playerItemContext)
        
        // add handler to systemMediaPlayer
        remoteCommandCenter.pauseCommand.addTarget(handler: pause)
        remoteCommandCenter.playCommand.addTarget(handler: play)
        remoteCommandCenter.nextTrackCommand.addTarget(handler: nextTrack)
        remoteCommandCenter.previousTrackCommand.addTarget(handler: prevTrack)
        remoteCommandCenter.changePlaybackPositionCommand.addTarget(handler: {
            handle in
            if let event = handle as? MPChangePlaybackPositionCommandEvent {
                self.seek(Int(event.positionTime))
            }
            return .success
        })
        remoteCommandCenter.togglePlayPauseCommand.addTarget(handler: { [self]
            _ in
                if mp.playbackState == .playing {
                    pause()
                } else {
                    play()
                }
            
                return MPRemoteCommandHandlerStatus.success
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// remote function call for system
    private func pause(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        pause()
        return MPRemoteCommandHandlerStatus.success
    }
    
    private func play(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        play()
        return MPRemoteCommandHandlerStatus.success
    }
    
    private func nextTrack(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        nextTrack()
        return MPRemoteCommandHandlerStatus.success
    }
    
    private func prevTrack(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        if currentIndex == -1 {
            return .noActionableNowPlayingItem // This should not happen
        }
        prevTrack()
        
        return MPRemoteCommandHandlerStatus.success
    }
    
   
    
    // audio player
    func replaceCurrent(media: MediaItem, result: FlutterResult) {
        replaceCurrent(media: media)
        result(nil)
    }
    
    func nextTrack() {
        if currentIndex + 1 < playlist.count {
            currentIndex += 1
            replaceCurrent(media: playlist[currentIndex])
        }
    }
    
    private func replaceCurrent(media: MediaItem) {
        var item: AVPlayerItem
        if cache {
            item = CachingPlayerItem(url: URL(string: media.url)!, customFileExtension: "wav") // just set a common extension anyway coz seem avplayeritem will auto recognize it
        } else {
            item = AVPlayerItem(url: URL(string: media.url)!)
        }
        item.seek(to: .zero, completionHandler: nil)
        audioPlayer.replaceCurrentItem(with: item)
        
        audioPlayer.automaticallyWaitsToMinimizeStalling = false
        
        audioPlayer.play()
    }
    
    
    

    func stop() {
        audioPlayer.pause()
        Stopped = true
        Playing = false
    }
    
    
    
    func seekIndex(index: Int) {
        if index > playlist.count - 1 {
            return
        }
        let media = playlist[index]
        var item: AVPlayerItem
        if cache {
            item = CachingPlayerItem(url: URL(string: media.url)!, customFileExtension: "wav") // just set a common extension anyway coz seem avplayeritem will auto recognize it
        } else {
            item = AVPlayerItem(url: URL(string: media.url)!)
        }
        audioPlayer.replaceCurrentItem(with: item)
        audioPlayer.seek(to: CMTime(seconds: Double(0), preferredTimescale: CMTimeScale(1000)), completionHandler: {
            _ in
            self.updateStatus()
        })
        currentIndex = index
    }
    
    
    
    // default will append to the last of the playlist
    public func addToPlaylist(media: MediaItem, index: Int = -1) {
        if index == -1 {
            playlist.append(media)
        } else {
            if index > playlist.count - 1 {
                return
            }
            playlist.insert(media, at: index)
        }
    }
    
    public func clearPlaylist() {
        playlist = []
    }
    
    public func removeFromPlaylist(index: Int, result: FlutterResult) {
        if index > playlist.count - 1 {
            return
        }
        playlist.remove(at: index)
        result(nil)
    }
    
    // should be private ?
    public func updateStatus() {
        if engineClosed {
            return
        }
        guard let eventSink = eventSink else {
            return
        }
        
        CurrentPosition = audioPlayer.currentTime().seconds.isNaN ? 0 : audioPlayer.currentTime().seconds
        
        let data: [String: Any] = [
            "duration": Duration,
            "position": CurrentPosition,
            "playing": Playing,
            "stopped": Stopped,
            "format": format,
            "sampleRate": sampleRate,
            "bitRate": bitDepth,
            "volume": volume,
            "index": currentIndex,
            "queue": playlist.map { e in e.toDictionary() },
        ]
        eventSink(data)
    }
    
    
    
    // For in-App control
    func pause() {
        if audioPlayer.currentTime().seconds.rounded(.awayFromZero) != 0 {
            CurrentPosition = audioPlayer.currentTime().seconds
        }
        
        audioPlayer.pause()
        mp.playbackState = .paused
        
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
        if playlist.isEmpty {
            print("playlist is empty!")
            return
        }
        if Stopped && !Playing {
            let media = playlist[currentIndex]
            var item: AVPlayerItem
            if cache {
                item = CachingPlayerItem(url: URL(string: media.url)!, customFileExtension: "wav") // just set a common extension anyway coz seem avplayeritem will auto recognize it
            } else {
                item = AVPlayerItem(url: URL(string: media.url)!)
            }
            item.seek(to: .zero, completionHandler: nil)
            audioPlayer.replaceCurrentItem(with: item)
        }
        
        audioPlayer.play()
        
        mp.playbackState = .playing
        
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
        Playing = false
        if currentIndex + 1 == playlist.count {
            Stopped = true
            mp.playbackState = .stopped
        } else {
            nextTrack()
        }
        updateStatus()
    }
    
    func prevTrack() {
        if currentIndex == 0 {
            seek(0)
            return
        } else {
            currentIndex -= 1
            replaceCurrent(media: playlist[currentIndex])
        }
        updateStatus()
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
            if let statusitem = change?[.newKey] as? AVPlayerItem {
            } else {
                print("Stopped")
                Stopped = true
                return
            }
            // Switch over status value
            
            Duration = 1 // set a 1 min timeout for fetching real duration from metadata
            Stopped = false
            mp.playbackState = .playing
            
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(playerDidFinishPlaying),
                                                   name: .AVPlayerItemDidPlayToEndTime,
                                                   object: audioPlayer.currentItem)
            
            Task.detached { [self] in
                do {
                    let formatInfo = try await self.audioPlayer.currentItem?.asset.loadTracks(withMediaType: .audio)[0].load(.formatDescriptions).first
                    if formatInfo != nil {
                        self.format = formatInfo?.mediaSubType.description.trimmingCharacters(in:
                            .punctuationCharacters) ?? "Unknown"
                        let info: AudioStreamBasicDescription? = CMAudioFormatDescriptionGetStreamBasicDescription(formatInfo!)?.pointee
                        self.sampleRate = info?.mSampleRate ?? 44100
                        self.changeOutputSampleRate()
                    }
                    // print("rate: ",try await audioPlayer.currentItem!.asset.load(.preferredRate))
                    
                    try print("accurate: ", await self.audioPlayer.currentItem!.asset.load(.providesPreciseDurationAndTiming))
                    
                    let duration = try await self.audioPlayer.currentItem!.asset.load(.duration).seconds
                    self.Duration = duration
                    
                    var nowPlayingInfo = mp.nowPlayingInfo ?? [String: Any]()
                    nowPlayingInfo[MPMediaItemPropertyTitle] = playlist[currentIndex].title
                    nowPlayingInfo[MPMediaItemPropertyArtist] = playlist[currentIndex].artist
                    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = playlist[currentIndex].album
                    
                    nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = false
                    nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
                    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = Float(1.0)
                    nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = Float(1.0)
                    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioPlayer.currentItem?.currentTime().seconds ?? 0
                    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = Duration
                    
                    if playlist[currentIndex].cover != "" {
                        nowPlayingInfo[MPMediaItemPropertyArtwork] =
                            MPMediaItemArtwork(boundsSize: CGSize(width: 50, height: 50), requestHandler: { [self]
                                _ in
                                    NSImage(byReferencingFile: playlist[currentIndex].cover.deletingPrefix("file://"))!
                            })
                    }
                
                    mp.nowPlayingInfo = nowPlayingInfo
                    if Playing {
                        mp.playbackState = .playing
                    } else if !Stopped {
                        mp.playbackState = .paused
                    } else {
                        mp.playbackState = .stopped
                    }
                    
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
    
    public func changeOutputSampleRate() {
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
            /*
             var status = AudioObjectSetPropertyData(
                 outputDeviceID,
                 &propertyAddress,
                 0,
                 nil,
                 dataSize,
                 &sampleRate
             )
              */
            
            if status != noErr {
                print("Error setting sample rate: \(status)")
            }
            
        } else {
            print("Error getting default output device ID: \(status)")
        }
    }
}

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }
}
