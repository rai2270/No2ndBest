//
//  SoundManager.swift
//  No2ndBest
//
//  Created by TR on 4/21/25.
//

import AVFoundation
import SpriteKit

enum SoundEffect: String {
    case buttonTap = "button_tap"
    case successTap = "success_tap"
    case missTap = "miss_tap"
    case gameOver = "game_over"
}

class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var backgroundMusicPlayer: AVAudioPlayer?
    private let backgroundMusicTracks = ["background_music_1", "background_music_2"]
    
    private init() {
        // Set default values in UserDefaults if not set
        if UserDefaults.standard.object(forKey: "musicEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "musicEnabled")
        }
        
        if UserDefaults.standard.object(forKey: "soundEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "soundEnabled")
        }
        
        if UserDefaults.standard.object(forKey: "difficulty") == nil {
            UserDefaults.standard.set(1, forKey: "difficulty") // Default to medium
        }
        
        // Music will be loaded when startBackgroundMusic is called
        
        // Start background music if enabled
        if UserDefaults.standard.bool(forKey: "musicEnabled") {
            startBackgroundMusic()
        }
        
        // Setup audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func playSound(_ sound: SoundEffect) {
        // Check if sound effects are enabled
        guard UserDefaults.standard.bool(forKey: "soundEnabled") else { return }
        
        // Get URL for the sound
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") else {
            print("Sound file \(sound.rawValue) not found")
            return
        }
        
        // Create and play audio player
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = nil
            player.volume = 1.0
            player.play()
            
            // Store reference to player to prevent it from being deallocated before sound completes
            audioPlayers[sound.rawValue] = player
        } catch {
            print("Failed to play sound \(sound.rawValue): \(error)")
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
