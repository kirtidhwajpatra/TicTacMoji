import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() {}
    
    func playWinSound() {
        playSound(named: "win_sound")
    }
    
    func playLoseSound() {
        playSound(named: "lose_sound")
    }
    
    func playDrawSound() {
        playSound(named: "draw_sound")
    }
    
    func playClickSound() {
        // System click sound or custom
        AudioServicesPlaySystemSound(1104)
    }
    
    private func playSound(named name: String) {
        // Since we don't have actual sound files yet, we will just print for now.
        // In a real app, we would load the resource here.
        // guard let path = Bundle.main.path(forResource: name, ofType: "mp3") else { return }
        // let url = URL(fileURLWithPath: path)
        // do {
        //     audioPlayer = try AVAudioPlayer(contentsOf: url)
        //     audioPlayer?.play()
        // } catch {
        //     print("Error calculating sound")
        // }
        print("Playing sound: \(name)")
    }
}
