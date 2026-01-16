import SwiftUI

struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<50) { _ in
                ConfettiParticle()
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct ConfettiParticle: View {
    @State private var xPos = Double.random(in: -0.5...0.5)
    @State private var yPos = -1.2
    @State private var rotation = Double.random(in: 0...360)
    @State private var color = Color(
        red: .random(in: 0...1),
        green: .random(in: 0...1),
        blue: .random(in: 0...1)
    )
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 10, height: 10)
            .rotationEffect(.degrees(rotation))
            .offset(x: UIScreen.main.bounds.width * xPos, y: UIScreen.main.bounds.height * yPos)
            .onAppear {
                withAnimation(.linear(duration: Double.random(in: 2...4)).repeatForever(autoreverses: false)) {
                    yPos = 1.2
                    rotation += 360
                }
            }
    }
}
