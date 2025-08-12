import Foundation
import AVFoundation
import MediaPlayer

class AudioManager: NSObject {
    static let shared = AudioManager()
    
    private var audioPlayer: AVAudioPlayer?
    private var fadeTimer: Timer?
    private var currentVolume: Float = 0.8
    private let spotifyManager = SpotifyManager.shared
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error setting up audio session: \(error)")
        }
    }
    
    func playAlarmSound(spotifyURI: String?) {
        if let spotifyURI = spotifyURI {
            playSpotifyTrack(uri: spotifyURI)
        } else {
            playDefaultAlarmSound()
        }
    }
    
    func stopAlarmSound() {
        audioPlayer?.stop()
        audioPlayer = nil
        fadeTimer?.invalidate()
        fadeTimer = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Error deactivating audio session: \(error)")
        }
    }
    
    func setVolume(_ level: Float) {
        currentVolume = max(0.0, min(1.0, level))
        audioPlayer?.volume = currentVolume
    }
    
    func fadeIn(duration: TimeInterval) {
        guard let player = audioPlayer else { return }
        
        player.volume = 0.0
        fadeTimer?.invalidate()
        
        let fadeSteps = 20
        let stepDuration = duration / Double(fadeSteps)
        let volumeIncrement = currentVolume / Float(fadeSteps)
        
        var currentStep = 0
        
        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.audioPlayer else {
                timer.invalidate()
                return
            }
            
            currentStep += 1
            player.volume = min(self.currentVolume, volumeIncrement * Float(currentStep))
            
            if currentStep >= fadeSteps {
                timer.invalidate()
                player.volume = self.currentVolume
            }
        }
    }
    
    private func playSpotifyTrack(uri: String) {
        Task {
            do {
                // Check if Spotify is authenticated
                if spotifyManager.isAuthenticated {
                    // Attempt to play the track through Spotify API
                    // For now, we'll open the Spotify app with the track URI
                    if let url = URL(string: uri) {
                        await UIApplication.shared.open(url)
                        // Start fade-in after opening Spotify
                        fadeIn(duration: 3.0)
                    } else {
                        playDefaultAlarmSound()
                    }
                } else {
                    // Not authenticated, play default sound
                    playDefaultAlarmSound()
                }
            } catch {
                print("Error playing Spotify track: \(error)")
                playDefaultAlarmSound()
            }
        }
    }
    
    private func playDefaultAlarmSound() {
        guard let soundURL = Bundle.main.url(forResource: "default_alarm", withExtension: "mp3") else {
            playSystemAlarmSound()
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = currentVolume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Error playing default alarm sound: \(error)")
            playSystemAlarmSound()
        }
    }
    
    private func playSystemAlarmSound() {
        guard let soundURL = Bundle.main.url(forResource: "alarm", withExtension: "caf") ??
                Bundle.main.url(forResource: "bell", withExtension: "caf") else {
            AudioServicesPlaySystemSound(1005)
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = currentVolume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Error playing system alarm sound: \(error)")
            AudioServicesPlaySystemSound(1005)
        }
    }
    
    func pauseAlarmSound() {
        audioPlayer?.pause()
    }
    
    func resumeAlarmSound() {
        audioPlayer?.play()
    }
    
    var isPlaying: Bool {
        return audioPlayer?.isPlaying ?? false
    }
}