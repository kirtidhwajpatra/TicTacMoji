import AVFoundation
import UIKit // Required for NSDataAsset

class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
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
    
    // Stop any playing sound
    func stopSound() {
        if let player = audioPlayer, player.isPlaying {
            player.stop()
            player.currentTime = 0
        }
    }
    
    // Legacy support (optional, or redirect)
    func playClickSound() {
        // Fallback or default to MyMove?
        playMoveSound(isMine: true)
    }
    
    private func playSound(assetName: String) {
        // Run on background to prevent UI lag
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Note: NSDataAsset must be accessed on Main Thread? 
            // Actually NSDataAsset(name:) looks up in bundle. It SHOULD be main thread safe usually, 
            // but let's grab the data on Main if needed. 
            // Documentation says NSDataAsset init is thread safe? 
            // Let's safe-guard: Get data on main, then init player on BG.
            
            // Wait, if we are already on background... we can't sync to main easily without blocking.
            // Let's assume looking up data is fast, but decoding audio (AVAudioPlayer init) is slow.
            
            DispatchQueue.main.async { // Get asset on main
                 guard let asset = NSDataAsset(name: assetName) else {
                    if assetName.contains("Move") {
                         AudioServicesPlaySystemSound(1104)
                    }
                    return
                 }
                 
                 let data = asset.data
                 
                 DispatchQueue.global(qos: .userInitiated).async {
                     do {
                        let player = try AVAudioPlayer(data: data)
                        player.volume = 1.0
                        player.prepareToPlay()
                        
                        if player.play() {
                            // Keep strong reference
                            self.audioPlayer = player
                        }
                     } catch {
                        print("AudioPlayer error: \(error)")
                     }
                 }
            }
        }
    }
}
