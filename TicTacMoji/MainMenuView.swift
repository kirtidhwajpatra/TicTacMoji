import SwiftUI

struct MainMenuView: View {
    @Binding var currentView: AppView
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var wsManager = WebSocketManager.shared
    @State private var showProfile = false
    @State private var showMultiplayer = false
    
    @State private var showShare = false
    
    // Animation State
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack {
                // Header (Delay 0.1s)
                HStack {
                    Spacer()
                    Button(action: { showShare = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
                    .scaleEffect(animateContent ? 1 : 0.8)
                    .opacity(animateContent ? 1 : 0)
                    
                    SizedBox(width: 20)
                    
                    Button(action: { showProfile = true }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
                    .scaleEffect(animateContent ? 1 : 0.8)
                    .opacity(animateContent ? 1 : 0)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateContent)
                
                Spacer().frame(height: 40)
                
                // Avatar & Greeting (Delay 0.2s)
                VStack(spacing: 8) {
                    Text(profileManager.currentUser.avatarRawValue)
                        .font(.system(size: 60))
                        .padding(10)
                        .background(Color(hex: "F3F4F6"))
                        .clipShape(Circle())
                        .scaleEffect(animateContent ? 1 : 0.5)
                        .opacity(animateContent ? 1 : 0)
                    
                    Text("Hi, \(profileManager.currentUser.name)")
                        .font(.system(size: 18, design: .rounded))
                        .foregroundColor(.black)
                        .offset(y: animateContent ? 0 : 20)
                        .opacity(animateContent ? 1 : 0)
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateContent)
                
                Spacer()
                
                // Title (Delay 0.3s)
                VStack(spacing: 0) {
                    Text("Welcome to")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.gray)
                        .offset(y: animateContent ? 0 : 20)
                        .opacity(animateContent ? 1 : 0)
                    Text("TicTacMoji")
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .scaleEffect(animateContent ? 1 : 0.9)
                        .opacity(animateContent ? 1 : 0)
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: animateContent)
                
                Spacer()
                
                // Buttons (Delay 0.4s+)
                VStack(spacing: 16) {
                    MenuPillButton(
                        title: "Play vs Friend",
                        icon: "person.2.fill",
                        bgColor: Color(hex: "FDE047"),
                        textColor: .black
                    ) {
                        currentView = .game(.vsHuman)
                    }
                    .offset(y: animateContent ? 0 : 50)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: animateContent)
                    
                    MenuPillButton(
                        title: "Play vs Robot",
                        icon: "desktopcomputer",
                        bgColor: Color(hex: "7C3AED"),
                        textColor: .white
                    ) {
                        currentView = .game(.vsMachine)
                    }
                    .offset(y: animateContent ? 0 : 50)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: animateContent)
                    
                    MenuPillButton(
                        title: "Online Multiplayer",
                        icon: "globe",
                        bgColor: .black,
                        textColor: .white
                    ) {
                        showMultiplayer = true
                    }
                    .offset(y: animateContent ? 0 : 50)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6), value: animateContent)
                }
                .padding(.horizontal, 30)
                .frame(maxWidth: 500) // Constrain width for iPad
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            animateContent = true
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showMultiplayer) {
            MultiplayerView()
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: ["Come play TicTacMoji with me! 🍄🌼"])
        }
        .onChange(of: wsManager.gameState) { newState in
            if newState == .active {
                showMultiplayer = false
                currentView = .game(.onlineServer)
            }
        }
    }
}

// MARK: - Components

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct MenuPillButton: View {
    let title: String
    let icon: String
    let bgColor: Color
    let textColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 20))
            }
            .foregroundColor(textColor)
            .padding(.vertical, 18)
            .padding(.horizontal, 24)
            .background(bgColor)
            .clipShape(Capsule())
            .shadow(color: bgColor.opacity(0.3), radius: 5, y: 3)
        }
        .buttonStyle(ScaleButtonStyle()) // Apply Haptic Scale Style
    }
}

struct SizedBox: View {
    var width: CGFloat?
    var height: CGFloat?
    var body: some View {
        Spacer().frame(width: width, height: height)
    }
}
