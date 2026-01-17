import SwiftUI
import Combine
import CoreMotion

class ParallaxMotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var pitch: Double = 0.0
    @Published var roll: Double = 0.0
    
    init() {
        startMotionUpdates()
    }
    
    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 FPS
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }
            
            // Smooth damping
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                self.pitch = motion.attitude.pitch
                self.roll = motion.attitude.roll
            }
        }
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}

struct ParallaxEffect: ViewModifier {
    @StateObject private var motion = ParallaxMotionManager()
    var magnitude: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .offset(x: CGFloat(motion.roll * magnitude), y: CGFloat(motion.pitch * magnitude))
            .rotation3DEffect(.degrees(motion.roll * 5), axis: (x: 0, y: 1, z: 0))
            .rotation3DEffect(.degrees(motion.pitch * 5), axis: (x: 1, y: 0, z: 0))
    }
}

extension View {
    func parallax(magnitude: CGFloat = 20) -> some View {
        self.modifier(ParallaxEffect(magnitude: magnitude))
    }
}
