import SwiftUI

struct MainMenuView: View {
    @Binding var currentView: AppView
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var wsManager = WebSocketManager.shared
    @State private var showProfile = false
    @State private var showMultiplayer = false
    
    var body: some View {
        ZStack {
            Color(hex: "F2F2F7").ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header / Profile Summary
                HStack {
                    Button(action: { showProfile = true }) {
                        HStack {
                            Text(profileManager.currentUser.avatarRawValue)
                                .font(.system(size: 40))
                                .padding(10)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                            
                            VStack(alignment: .leading) {
                                Text("Hello,")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(profileManager.currentUser.name)
                                    .font(.headline)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // Title
                VStack {
                    Text("TicTacMoji")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(hex: "EF553B"))
                    Text("The classic game re-imagined")
                        .font(.subheadline)
                            .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: 20) {
                    MenuButton(title: "Play vs Robot 🤖", color: Color(hex: "EF553B")) {
                        currentView = .game(.vsMachine)
                    }
                    
                    MenuButton(title: "Play vs Friend 👥", color: Color(hex: "F3A333")) {
                        currentView = .game(.vsHuman)
                    }
                    
                    MenuButton(title: "Multiplayer 🌍", color: Color(hex: "65C466")) {
                        showMultiplayer = true
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showMultiplayer) {
            MultiplayerView() // No init args
        }
        .onChange(of: wsManager.gameState) { newState in
            // When game becomes active (after countdown), switch view
            if newState == .active {
                showMultiplayer = false 
                currentView = .game(.onlineServer)
            }
        }
    }
}

struct MenuButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(color)
                .cornerRadius(20)
                .shadow(color: color.opacity(0.4), radius: 10, y: 5)
        }
    }
}
