import SwiftUI

// MARK: - Main View
struct TicTacToeView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: TicTacToeViewModel
    
    // Simulate Loading State
    @State private var isLoading = true
    
    // Init with dependencies (simplified)
    init(gameMode: GameMode = .vsHuman, onDismiss: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: TicTacToeViewModel(gameMode: gameMode))
        self.customDismiss = onDismiss
    }
    
    var customDismiss: (() -> Void)?
    
    var body: some View {
        ZStack {
            Color(hex: "F2F2F7").ignoresSafeArea() // Use theme background color
            
            if isLoading {
                LoadingScreen()
                    .transition(.opacity)
                    .onAppear {
                        // Fake loading delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                isLoading = false
                            }
                        }
                    }
            } else {
                GameContent(viewModel: viewModel, onDismiss: {
                    customDismiss?() ?? dismiss()
                })
                .transition(.opacity)
            }
            
            // Win Overlay
            // Only show confetti if WE won
            if case .won(let winner) = viewModel.gameState, 
               viewModel.gameResultText == "You Won!" {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - 1. Loading Screen
struct LoadingScreen: View {
    var body: some View {
        VStack {
            Spacer()
            
            // App Icon Style
            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(hex: "EF553B")) // Red color
                    .frame(width: 140, height: 140)
                    .shadow(color: Color(hex: "EF553B").opacity(0.3), radius: 15, y: 10)
                
                Circle()
                    .fill(Color(hex: "952B1E")) // Darker red
                    .frame(width: 60, height: 60)
                    .offset(y: -10)
                
                Text("TicTacToe")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .offset(y: 40)
            }
            
            Spacer()
            
            Text("Loading...")
                .font(.system(size: 18))
                .foregroundColor(.gray)
                .padding(.bottom, 50)
        }
    }
}

// MARK: - 2. Game Content
struct GameContent: View {
    @ObservedObject var viewModel: TicTacToeViewModel
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            // Header
            HStack(alignment: .top) {
                Button(action: onDismiss) {
                    Image(systemName: "arrow.turn.up.left")
                        .font(.system(size: 20))
                        .padding(12)
                        .background(Color.white)
                        .clipShape(Circle())
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                // Scoreboard Card
                HStack(spacing: 0) {
                    // Player 1
                    VStack {
                        Text(viewModel.p1Avatar)
                            .font(.system(size: 30))
                        Text("\(viewModel.p1Score)")
                            .font(.system(size: 24, weight: .bold))
                        Text(viewModel.p1Name)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .frame(width: 80)
                    
                    Divider().frame(height: 40)
                    
                    // Player 2
                    VStack {
                        Text(viewModel.p2Avatar)
                            .font(.system(size: 30))
                        Text("\(viewModel.p2Score)")
                            .font(.system(size: 24, weight: .bold))
                        Text(viewModel.p2Name)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .frame(width: 80)
                }
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(radius: 2)
                .foregroundColor(.black) // Ensure text is visible on white background
            }
            .padding()
            
            Spacer()
            
            // Status Message
            if case .active = viewModel.gameState {
                Text(viewModel.turnMessage)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.black.opacity(0.7))
                    .padding(.top, 10)
            } else {
                VStack(spacing: 4) {
                    if viewModel.gameResultText.contains("Won") {
                        Text("Congratulations🎉")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                        Text(viewModel.gameResultText.replacingOccurrences(of: " Won!", with: ""))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                    } else {
                        Text(viewModel.gameState == .draw ? "It's a Draw!" : viewModel.gameResultText)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(viewModel.gameResultText.contains("Lost") ? .red : .black)
                    }
                }
                .padding(.bottom, 30)
                .transition(.scale.combined(with: .opacity))
            }
                
                Spacer()
                
                // Game Board (Clean White Card)
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
                        .frame(width: 320, height: 320)
                    
                    // Grid
                    VStack(spacing: 0) {
                        ForEach(0..<3) { row in
                            HStack(spacing: 0) {
                                ForEach(0..<3) { col in
                                    let index = row * 3 + col
                                    TicTacCell(
                                        content: viewModel.board[index],
                                        p1Icon: viewModel.p1Avatar,
                                        p2Icon: viewModel.p2Avatar
                                    )
                                    .onTapGesture {
                                        viewModel.processMove(at: index)
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: 300, height: 300)
                    
                    // Custom Grid Lines (Thinner, lighter)
                    HStack(spacing: 98) {
                        Rectangle().fill(Color.gray.opacity(0.2)).frame(width: 2, height: 280)
                        Rectangle().fill(Color.gray.opacity(0.2)).frame(width: 2, height: 280)
                    }
                    VStack(spacing: 98) {
                        Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 2).frame(width: 280)
                        Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 2).frame(width: 280)
                    }
                }
                
                Spacer()
                
                // Bottom Controls
                if viewModel.gameState != .active {
                    VStack(spacing: 16) {
                        if viewModel.waitingForRematch {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Waiting for opponent...")
                            }
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding()
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.05), radius: 5)
                        } else {
                            if viewModel.isOpponentReady {
                                Text("\(viewModel.p2Name) wants to play!")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.black)
                            }
                            
                            Button(action: {
                                viewModel.resetGame()
                            }) {
                                HStack {
                                    Text(viewModel.isOpponentReady ? "Accept Rematch" : "Play Again")
                                    Image(systemName: "arrow.right")
                                }
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.black)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 18)
                                .background(Color(hex: "D0FD3E")) // Exact Lime Green
                                .clipShape(Capsule())
                                .shadow(color: Color(hex: "D0FD3E").opacity(0.5), radius: 10, y: 5)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                } else {
                    // Turn Indicator (Clean)
                    HStack(spacing: 40) {
                        CircleIcon(icon: viewModel.p1Avatar, isActive: viewModel.activePlayer == .p1)
                        CircleIcon(icon: viewModel.p2Avatar, isActive: viewModel.activePlayer == .p2)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    
}
    
struct TicTacCell: View {
    let content: Player?
    let p1Icon: String
    let p2Icon: String
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
                .frame(width: 100, height: 100)
            
            if let player = content {
                Text(player == .p1 ? p1Icon : p2Icon)
                    .font(.system(size: 60))
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}
    
struct CircleIcon: View {
    let icon: String
    let isActive: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 50, height: 50)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                .overlay(
                    Circle().stroke(isActive ? Color.green : Color.clear, lineWidth: 2)
                )
            
            Text(icon)
                .font(.system(size: 24))
        }
        .scaleEffect(isActive ? 1.1 : 1.0)
        .animation(.spring(), value: isActive)
    }
}
