//
//  SoundManager.swift
//  No2ndBest
//
//  Created by TR on 4/21/25.
//

import AVFoundation
import SpriteKit

enum SoundEffect: String, CaseIterable {
    case buttonTap = "button_tap"
    case successTap = "success_tap"
    case missTap = "miss_tap"
    case gameOver = "game_over"
}

class SoundEffectPlayer: NSObject, AVAudioPlayerDelegate {
    var player: AVAudioPlayer?
    var isAvailable = true
    var soundType: String = ""
    
    func play() {
        isAvailable = false
        player?.play()
    }
    
    // AVAudioPlayerDelegate method called when playback finishes
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isAvailable = true
    }
}

class SoundManager {
    static let shared = SoundManager()
    
    // Maximum number of concurrent sound effects
    private let maxConcurrentSounds = 3
    
    // Pre-loaded pool of audio players for each sound type
    private var soundPlayerPools: [String: [SoundEffectPlayer]] = [:]
    
    // Queue for background operations
    private let loadingQueue = DispatchQueue(label: "com.no2ndbest.audioLoading", qos: .utility)
    
    private var backgroundMusicPlayer: AVAudioPlayer?
    private let backgroundMusicTracks = ["background_music_1", "background_music_2"]
    
    // Track the last time each sound was played to prevent spam
    private var lastPlayTimes: [String: TimeInterval] = [:]
    private let cooldownTime: TimeInterval = 0.1
    
    private var currentTime: TimeInterval = 0
    
    private init() {
        // Set default values in UserDefaults if not set
        if UserDefaults.standard.object(forKey: "musicEnabled") == nil {
            UserDefaults.standard.set(false, forKey: "musicEnabled")
        }
        
        if UserDefaults.standard.object(forKey: "soundEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "soundEnabled")
        }
        
        if UserDefaults.standard.object(forKey: "difficulty") == nil {
            UserDefaults.standard.set(1, forKey: "difficulty") // Default to medium
        }
        
        // Setup audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        
        // Pre-load sound effects
        preloadSounds()
        
        // Start background music if enabled
        if UserDefaults.standard.bool(forKey: "musicEnabled") {
            startBackgroundMusic()
        }
    }
    
    // Pre-load all sound effects into player pools
    private func preloadSounds() {
        loadingQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Pre-load each sound type
            for soundType in SoundEffect.allCases {
                self.createSoundPlayerPool(for: soundType.rawValue)
            }
        }
    }
    
    // Create a pool of players for a specific sound type
    private func createSoundPlayerPool(for soundType: String) {
        guard let url = Bundle.main.url(forResource: soundType, withExtension: "mp3") else {
            print("Sound file \(soundType) not found")
            return
        }
        
        var players: [SoundEffectPlayer] = []
        
        // Create several players for each sound type to handle concurrent sounds
        for _ in 0..<maxConcurrentSounds {
            do {
                let soundPlayer = SoundEffectPlayer()
                soundPlayer.player = try AVAudioPlayer(contentsOf: url)
                soundPlayer.player?.delegate = soundPlayer
                soundPlayer.player?.prepareToPlay() // Pre-load the sound data
                soundPlayer.soundType = soundType
                players.append(soundPlayer)
            } catch {
                print("Failed to create sound player for \(soundType): \(error)")
            }
        }
        
        if !players.isEmpty {
            soundPlayerPools[soundType] = players
        }
    }
    
    // Update the current time reference (call this from your game loop)
    func updateCurrentTime(_ time: TimeInterval) {
        currentTime = time
    }
    
    // Play a sound effect with performance optimizations
    func playSound(_ sound: SoundEffect) {
        // Check if sound effects are enabled
        guard UserDefaults.standard.bool(forKey: "soundEnabled") else { return }
        
        let soundType = sound.rawValue
        
        // Check cooldown to prevent sound spam
        if let lastPlayTime = lastPlayTimes[soundType], currentTime - lastPlayTime < cooldownTime {
            return
        }
        
        // Update last play time
        lastPlayTimes[soundType] = currentTime
        
        // Use a background queue to find and play an available sound player
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            
            // Find an available player in the pool
            if let availablePlayer = self.soundPlayerPools[soundType]?.first(where: { $0.isAvailable }) {
                DispatchQueue.main.async {
                    availablePlayer.play()
                }
            }
        }
    }
    
    func startBackgroundMusic() {
        // Stop any existing music
        backgroundMusicPlayer?.stop()
        
        // Randomly select a music track
        let randomTrack = backgroundMusicTracks.randomElement() ?? "background_music_1"
        
        // Load and play the selected track
        if let musicURL = Bundle.main.url(forResource: randomTrack, withExtension: "mp3") {
            do {
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: musicURL)
                backgroundMusicPlayer?.numberOfLoops = -1 // Loop indefinitely
                backgroundMusicPlayer?.prepareToPlay()
                backgroundMusicPlayer?.play()
                print("Now playing: \(randomTrack)")
            } catch {
                print("Could not load background music: \(error)")
            }
        } else {
            print("Could not find music file: \(randomTrack)")
        }
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
    }
    
    func pauseBackgroundMusic() {
        backgroundMusicPlayer?.pause()
    }
    
    func resumeBackgroundMusic() {
        if UserDefaults.standard.bool(forKey: "musicEnabled") {
            // If no music is currently loaded or it has finished, start a new random track
            if backgroundMusicPlayer == nil || backgroundMusicPlayer?.isPlaying == false {
                startBackgroundMusic()
            } else {
                backgroundMusicPlayer?.play()
            }
        }
    }
    
    func selectNewTrack() {
        // Only select a new track if music is enabled
        if UserDefaults.standard.bool(forKey: "musicEnabled") {
            startBackgroundMusic()
        }
    }
}
