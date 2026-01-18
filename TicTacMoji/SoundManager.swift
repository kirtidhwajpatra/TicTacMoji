import AVFoundation
import UIKit // Required for NSDataAsset

class SoundManager: NSObject, AVAudioPlayerDelegate {
    static let shared = SoundManager()
    
    private var activePlayers: Set<AVAudioPlayer> = []
    
    private override init() {
        super.init()
        // Prepare session
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session:", error)
        }
    }
    
    func playWinSound() {
        playSound(assetName: "Win")
    }
    
    func playDrawSound() {
        // Fallback to system sound or no sound
        // AudioServicesPlaySystemSound(1001) 
    }
    
    // Updated to support MyMove vs OpponentMove
    func playMoveSound(isMine: Bool) {
        let soundName = isMine ? "MyMove" : "OponentMove"
        playSound(assetName: soundName)
    }
    
    // Stop all playing sounds
    func stopSound() {
        DispatchQueue.main.async {
            for player in self.activePlayers {
                player.stop()
            }
            self.activePlayers.removeAll()
        }
    }
    
    // Legacy support
    func playClickSound() {
        playMoveSound(isMine: true)
    }
    
    private func playSound(assetName: String) {
        // Run heavy lifting (loading/decoding) on background to prevent UI lag
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Get data on Main (NSDataAsset requirement for bundle access safety)
            DispatchQueue.main.async {
                 guard let asset = NSDataAsset(name: assetName) else {
                    if assetName.contains("Move") {
                         AudioServicesPlaySystemSound(1104)
                    }
                    return
                 }
                 
                 let data = asset.data
                 
                 // Decode on Background
                 DispatchQueue.global(qos: .userInitiated).async {
                     do {
                        let player = try AVAudioPlayer(data: data)
                        player.volume = 1.0
                        player.prepareToPlay()
                        
                        // Hand back to Main to Play and Retain (Prevent Race Condition/Crash)
                        DispatchQueue.main.async {
                            player.delegate = self
                            if player.play() {
                                self.activePlayers.insert(player)
                            }
                        }
                     } catch {
                        print("AudioPlayer error: \(error)")
                     }
                 }
            }
        }
    }
    
    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Cleanup finished player
        activePlayers.remove(player)
    }
}
