import SwiftUI

// MARK: - Main View
struct TicTacToeView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: TicTacToeViewModel
    @State private var isLoading = true
    
    // Win Line Animation
    @State private var showWinLine = false
    
    init(gameMode: GameMode = .vsHuman, onDismiss: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: TicTacToeViewModel(gameMode: gameMode))
        self.customDismiss = {
            SoundManager.shared.stopSound()
            onDismiss?()
        }
    }
    
    var customDismiss: (() -> Void)?
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Base Background (Always White)
                Color.white.ignoresSafeArea()
                
                // Winning Overlay
                if case .won = viewModel.gameState {
                    WinningGradient()
                        .ignoresSafeArea()
                        .transition(.opacity.animation(.easeInOut(duration: 1.0)))
                }
                
                if isLoading {
                    LoadingScreen()
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                withAnimation { isLoading = false }
                            }
                        }
                } else {
                    GameContent(viewModel: viewModel, onDismiss: {
                        customDismiss?() ?? dismiss()
                    }, screenSize: geo.size)
                    .transition(.opacity)
                }
                
                if case .won(let winner) = viewModel.gameState,
                   viewModel.gameResultText == "You Won!" {
                    ConfettiView().allowsHitTesting(false)
                }
            }
        }
    }
}

// MARK: - Loading View
struct LoadingScreen: View {
    @State private var scale = 0.8
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(hex: "FDE047"))
                    .frame(width: 120, height: 120)
                    .scaleEffect(scale)
                Text("🍄")
                    .font(.system(size: 60))
                    .scaleEffect(scale)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    scale = 1.0
                }
            }
            Spacer()
        }
    }
}

// MARK: - Game Content
struct GameContent: View {
    @ObservedObject var viewModel: TicTacToeViewModel
    let onDismiss: () -> Void
    let screenSize: CGSize
    
    var isLandscape: Bool { screenSize.width > screenSize.height }
    
    var boardSize: CGFloat {
        let dim = min(screenSize.width, screenSize.height)
        return isLandscape ? min(dim * 0.85, 700) : min(dim * 0.9, 600)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .padding(10)
                        .background(Color(hex: "F3F4F6"))
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle()) // Haptic Button
                
                Spacer()
                ScorePill(viewModel: viewModel)
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            
            if isLandscape {
                HStack(spacing: 40) {
                    VStack {
                        Spacer()
                        ZStack {
                            NotebookBackground()
                                .frame(width: boardSize, height: boardSize)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.1), lineWidth: 1))
                            BoardGrid(viewModel: viewModel, size: boardSize)
                                .padding(20)
                        }
                        .frame(width: boardSize, height: boardSize)
                        Spacer()
                    }
                    .padding(.leading, 40)
                    
                    VStack(spacing: 30) {
                        Spacer()
                        StatusSection(viewModel: viewModel)
                        TurnIndicatorSection(viewModel: viewModel)
                        Spacer()
                    }
                    .frame(maxWidth: 300)
                    .padding(.trailing, 40)
                }
            } else {
                Spacer()
                StatusSection(viewModel: viewModel)
                    .padding(.bottom, 20)
                
                ZStack {
                    NotebookBackground()
                        .frame(width: boardSize, height: boardSize)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.15), lineWidth: 1)) // Thinnest
                        .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 8)
                    BoardGrid(viewModel: viewModel, size: boardSize)
                        .padding(60) // Increased padding significantly
                }
                .frame(width: boardSize, height: boardSize)
                
                Spacer()
                
                TurnIndicatorSection(viewModel: viewModel)
                    .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Subviews

struct ScorePill: View {
    @ObservedObject var viewModel: TicTacToeViewModel
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Text(viewModel.p1Avatar)
                Text("\(viewModel.p1Score)").fontWeight(.bold)
            }
            HStack(spacing: 4) {
                Text(viewModel.p2Avatar)
                Text("\(viewModel.p2Score)").fontWeight(.bold)
            }
        }
        .font(.system(size: 16, design: .rounded))
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(hex: "F3F4F6"))
        .clipShape(Capsule())
        .foregroundColor(.black)
    }
}

struct StatusSection: View {
    @ObservedObject var viewModel: TicTacToeViewModel
    var body: some View {
        VStack(spacing: 8) {
            if case .won = viewModel.gameState {
                // Logic for Header Title
                let isLoss = viewModel.gameResultText.contains("Lost")
                
                Text(isLoss ? "Game Over 😢" : "Congratulations🎉")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.gray)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                
                Text(viewModel.gameResultText.replacingOccurrences(of: " Won!", with: ""))
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .foregroundColor(.black)
                    .transition(.scale.combined(with: .opacity))
            } else if case .draw = viewModel.gameState {
                Text("Draw!")
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .foregroundColor(.black)
            } else {
                Text(viewModel.turnMessage)
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .transition(.opacity)
                    .id("TurnMessage" + viewModel.turnMessage) // Refresh animation on text change
            }
        }
        .animation(.spring(), value: viewModel.gameState)
    }
}

struct TurnIndicatorSection: View {
    @ObservedObject var viewModel: TicTacToeViewModel
    var body: some View {
        Group {
            if case .active = viewModel.gameState {
                HStack(spacing: 30) {
                    PlayerTurnIcon(icon: viewModel.p1Avatar, isActive: viewModel.activePlayer == .p1)
                    PlayerTurnIcon(icon: viewModel.p2Avatar, isActive: viewModel.activePlayer == .p2)
                }
            } else {
                VStack(spacing: 8) {
                    if viewModel.isOpponentReady {
                        Text("Opponent wants to play!")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .transition(.scale)
                    }
                    
                    Button(action: { viewModel.resetGame() }) {
                        HStack {
                            if viewModel.waitingForRematch {
                                ProgressView()
                                    .tint(.black)
                                Text("Waiting...")
                            } else {
                                Image(systemName: "arrow.counterclockwise")
                                Text(viewModel.isOpponentReady ? "Accept Rematch" : "Play Again")
                            }
                        }
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 32)
                        .background(Color(hex: "FDE047"))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(ScaleButtonStyle()) // Haptic
                    .disabled(viewModel.waitingForRematch) // Prevent double sending
                    .opacity(viewModel.waitingForRematch ? 0.6 : 1.0)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

struct PlayerTurnIcon: View {
    let icon: String
    let isActive: Bool
    
    // Breathing Animation State
    @State private var breathe = false
    @State private var pop = false // New Pop State
    
    var body: some View {
        ZStack {
            if isActive {
                Circle()
                    .stroke(Color.green, lineWidth: 2)
                    .frame(width: 50, height: 50)
                    .scaleEffect(breathe ? 1.05 : 0.95) // Subtle pulse
                    .opacity(breathe ? 1.0 : 0.7)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            breathe = true
                        }
                    }
            }
            Text(icon).font(.system(size: 28))
                .scaleEffect(pop ? 1.3 : (isActive ? 1.1 : 1.0)) // POP scale
                .rotationEffect(.degrees(pop ? 15 : 0)) // Slight tilt
        }
        .frame(width: 50, height: 50)
        .opacity(isActive ? 1.0 : 0.4)
        .onChange(of: isActive) { newValue in
            if newValue {
                // Trigger POP when becoming active
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    pop = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        pop = false
                    }
                }
            }
        }
    }
}

struct BoardGrid: View {
    @ObservedObject var viewModel: TicTacToeViewModel
    let size: CGFloat
    var body: some View {
        let effectiveSize = size - 40
        let cellSize = effectiveSize / 3
        ZStack {
            // Grid Lines with DRAW Animation? 
            // Keeping it simple static for performance, but adding opacity transition
            VStack(spacing: 0) {
                Spacer(); Rectangle().fill(Color.black).frame(height: 2); Spacer(); Rectangle().fill(Color.black).frame(height: 2); Spacer()
            }.frame(width: effectiveSize, height: effectiveSize)
            HStack(spacing: 0) {
                Spacer(); Rectangle().fill(Color.black).frame(width: 2); Spacer(); Rectangle().fill(Color.black).frame(width: 2); Spacer()
            }.frame(width: effectiveSize, height: effectiveSize)
            
            VStack(spacing: 0) {
                ForEach(0..<3) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<3) { col in
                            let index = row * 3 + col
                            let isWinning = viewModel.winningIndices.contains(index)
                            let isGameOver = !viewModel.winningIndices.isEmpty
                            
                            TicTacCell(
                                player: viewModel.board[index],
                                p1Icon: viewModel.p1Avatar,
                                p2Icon: viewModel.p2Avatar,
                                isWinning: isWinning,
                                isDimmed: isGameOver && !isWinning,
                                action: { viewModel.processMove(at: index) },
                                size: cellSize
                            ).frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }.frame(width: effectiveSize, height: effectiveSize)
        }
    }
}

struct NotebookBackground: View {
    var body: some View {
        ZStack {
            Color(hex: "F2F2F2") // Slightly darker paper (was F7F7F7)
            notebook_bg_path_shape()
                .stroke(Color.gray.opacity(0.2), lineWidth: 1) // Darker lines
        }
    }
}

struct notebook_bg_path_shape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 28
        for y in stride(from: spacing, to: rect.height, by: spacing) {
            path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        return path
    }
}

struct TicTacCell: View {
    let player: Player?
    let p1Icon: String
    let p2Icon: String
    let isWinning: Bool
    var isDimmed: Bool = false
    let action: () -> Void
    let size: CGFloat
    
    @State private var rotateRainbow = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle()
                    .fill(Color.black.opacity(0.001)) // Explicit hit-testable shape
                    .contentShape(Rectangle())
                
                if let player = player {
                    // Subtle Background Glow for Winners
                    if isWinning {
                        Circle()
                            .fill(
                                AngularGradient(gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red]), center: .center)
                            )
                            .frame(width: size * 0.85, height: size * 0.85)
                            .blur(radius: 10) // Soft Glow effect
                            .opacity(0.5)
                            .rotationEffect(.degrees(rotateRainbow ? 360 : 0))
                            .onAppear {
                                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                                    rotateRainbow = true
                                }
                            }
                    } else {
                        // Move Splash Effect (Only once on appear)
                        if showSplash {
                             Circle()
                                .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                                .scaleEffect(splashCheck ? 1.5 : 0.5)
                                .opacity(splashCheck ? 0 : 1)
                        }
                    }
                    
                    Text(player == .p1 ? p1Icon : p2Icon)
                        .font(.system(size: size * 0.6)) // Standard Size
                        .shadow(radius: isWinning ? 2 : 1)
                        .opacity(isDimmed ? 0.3 : 1.0) // Dim losers
                        .grayscale(isDimmed ? 1.0 : 0.0) // Optional: Grayscale losers
                        // Bouncy Entrance
                        .transition(.scale(scale: 0.1).combined(with: .opacity).animation(.spring(response: 0.4, dampingFraction: 0.5)))
                        .onAppear {
                            // Trigger Splash
                            // Use a slight delay to sync with bounce
                            showSplash = true
                            withAnimation(.easeOut(duration: 0.5)) {
                                splashCheck = true
                            }
                        }
                }
            }
            .contentShape(Rectangle()) // Explicit hit testing shape
        }
        .buttonStyle(PlainButtonStyle()) // Don't scale cell on press logic (handled by ViewModel logic probably or we can add small press)
    }
    @State private var showSplash = false
    @State private var splashCheck = false
}

struct WinningGradient: View {
    @State private var start = UnitPoint(x: -1, y: -1)
    @State private var end = UnitPoint(x: 0, y: 0)
    
    let colors = [
        Color.white,
        Color.yellow.opacity(0.02),
        Color.white,
        Color.cyan.opacity(0.01),
        Color.white,
        Color.orange.opacity(0.01),
        Color.white
    ]
    
    var body: some View {
        LinearGradient(gradient: Gradient(colors: colors), startPoint: start, endPoint: end)
            .onAppear {
                withAnimation(.linear(duration: 10).repeatForever(autoreverses: true)) {
                    start = UnitPoint(x: 1, y: 1)
                    end = UnitPoint(x: 2, y: 2)
                }
            }
            .blur(radius: 60)
            .opacity(0.3) // Reduced form 0.6
    }
}

#Preview {
    TicTacToeView(gameMode: .vsHuman)
}
