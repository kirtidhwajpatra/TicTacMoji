import SwiftUI

struct MultiplayerView: View {
    @StateObject var wsManager = WebSocketManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var joinRoomId = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if wsManager.isConnected {
                    if let roomId = wsManager.roomId {
                        // Room Created/Joined
                        VStack(spacing: 20) {
                            Text("Room Code")
                                .font(.headline)
                            Text(roomId)
                                .font(.system(size: 40, weight: .bold, design: .monospaced))
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            
                            ShareLink(item: URL(string: "tictacmoji://join?room=\(roomId)")!) {
                                Label("Share Link", systemImage: "square.and.arrow.up")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            
                            if wsManager.gameState == .waitingForPlayer {
                                HStack {
                                    ProgressView()
                                    Text("Waiting for opponent...")
                                        .foregroundColor(.gray)
                                }
                            } else if wsManager.gameState == .countingDown {
                                Text("Starting game...")
                                    .font(.title)
                                    .foregroundColor(.green)
                            }
                        }
                    } else {
                        // Menu
                        VStack(spacing: 20) {
                            Button(action: {
                                wsManager.createRoom()
                            }) {
                                Text("Create Room")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            
                            HStack {
                                TextField("Enter Room Code", text: $joinRoomId)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textCase(.uppercase)
                                    .autocapitalization(.allCharacters)
                                
                                Button("Join") {
                                    if !joinRoomId.isEmpty {
                                        wsManager.joinRoom(roomId: joinRoomId.uppercased())
                                    }
                                }
                                .disabled(joinRoomId.isEmpty)
                            }
                            .padding()
                        }
                        .padding()
                    }
                } else {
                    if case .connectionError(let error) = wsManager.gameState {
                         VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            Text("Connection Failed")
                                .font(.headline)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(action: {
                                wsManager.connect()
                            }) {
                                Text("Retry Connection")
                                    .fontWeight(.bold)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                    } else {
                        ProgressView("Connecting to Server...")
                            .onAppear {
                                wsManager.connect()
                            }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Online Multiplayer")
            .navigationBarItems(trailing: Button("Close") { dismiss() })
            .onChange(of: wsManager.gameState) { newState in
                if newState == .active {
                    // Navigate to game automatically?
                    // Handled by AppView state in TicTacMojiApp usually, 
                    // but here we might need to notify parent.
                }
            }
        }
    }
}
