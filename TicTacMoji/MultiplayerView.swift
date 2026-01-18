import SwiftUI

struct MultiplayerView: View {
    @StateObject var wsManager = WebSocketManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var joinRoomId = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Content
                    if wsManager.isConnected {
                        if let roomId = wsManager.roomId {
                            RoomCodeView(roomId: roomId, wsManager: wsManager)
                        } else {
                            CreateOrJoinView(wsManager: wsManager, joinRoomId: $joinRoomId)
                        }
                    } else {
                        ConnectionStateView(wsManager: wsManager)
                    }
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Online Multiplayer")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: handleClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold)) // Smaller icon
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color(hex: "F3F4F6")) // Single soft background
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
    
    func handleClose() {
        if wsManager.roomId != nil {
            // Leave Room but stay in Multiplayer Menu
            withAnimation {
                wsManager.leaveRoom()
            }
        } else {
            // Dismiss Multiplayer Sheet
            dismiss()
        }
    }
}

// MARK: - Subviews

struct CreateOrJoinView: View {
    @ObservedObject var wsManager: WebSocketManager
    @Binding var joinRoomId: String
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer().frame(height: 20)
            
            // Create Room
            Button(action: {
                withAnimation { wsManager.createRoom() }
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create New Room")
                }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(hex: "FDE047")) 
                .clipShape(Capsule())
            }
            .padding(.horizontal, 40)
            .buttonStyle(ScaleButtonStyle())
            
            HStack {
                Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1)
                Text("OR").font(.caption).foregroundColor(.gray)
                Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1)
            }.padding(.horizontal, 60)
            
            // Join Room
            VStack(spacing: 16) {
                Text("Enter Room Code to Join")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                
                HStack(spacing: 12) {
                    TextField("CODE", text: $joinRoomId)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .textCase(.uppercase)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(hex: "F3F4F6"))
                        .cornerRadius(16)
                        .frame(height: 60)
                    
                    Button(action: {
                        if !joinRoomId.isEmpty {
                            withAnimation { wsManager.joinRoom(roomId: joinRoomId.uppercased()) }
                        }
                    }) {
                         Image(systemName: "arrow.right")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(!joinRoomId.isEmpty ? .black : .gray.opacity(0.5))
                            .frame(width: 60, height: 60)
                            .background(!joinRoomId.isEmpty ? Color(hex: "FDE047") : Color(hex: "F3F4F6"))
                            .clipShape(Circle())
                    }
                    .disabled(joinRoomId.isEmpty)
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 40)
            }
        }
        // Error Alert
        .alert(item: Binding<AlertError?>(
            get: { wsManager.errorMessage.map { AlertError(message: $0) } },
            set: { _ in wsManager.errorMessage = nil }
        )) { error in
            Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
        }
    }
}

// Helper for Alert
struct AlertError: Identifiable {
    let id = UUID()
    let message: String
}

struct RoomCodeView: View {
    let roomId: String
    @ObservedObject var wsManager: WebSocketManager
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer().frame(height: 20)
            
            VStack(spacing: 10) {
                Text("ROOM CODE")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.gray)
                    .tracking(2)
                
                Text(roomId)
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .tracking(2)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(
                        NotebookBackground() // Reusing the pattern if visible? Or just clean
                            .opacity(0.5)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    )
                    .padding(.horizontal, 40)
            }
            
            if wsManager.gameState == .waitingForPlayer {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Waiting for opponent...")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                
                ShareLink(item: URL(string: "tictacmoji://join?room=\(roomId)")!) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Link")
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 30)
                    .background(Color(hex: "F3F4F6"))
                    .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
                
            } else if wsManager.gameState == .countingDown {
                VStack(spacing: 10) {
                    Text("Game Starting!")
                        .font(.title2)
                        .fontWeight(.bold)
                    if let count = wsManager.countdown {
                        Text("\(count)")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(Color(hex: "FDE047"))
                            .transition(.scale)
                    }
                }
            }
        }
    }
}

struct ConnectionStateView: View {
    @ObservedObject var wsManager: WebSocketManager
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            if case .connectionError(let error) = wsManager.gameState {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
                Text("Connection Issue")
                    .font(.headline)
                Text(error)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("Retry") {
                    wsManager.connect()
                }
                .padding()
            } else {
                ProgressView()
                Text("Connecting to Server...")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .onAppear { wsManager.connect() }
            }
            Spacer()
        }
    }
}
