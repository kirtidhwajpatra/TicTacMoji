//
//  TicTacMojiApp.swift
//  TicTacMoji
//
//  Created by Mr SwiftUI on 16/01/26.
//

import SwiftUI

enum AppView {
    case menu
    case game(GameMode)
}

@main
struct TicTacMojiApp: App {
    @State private var currentView: AppView = .menu
    @StateObject private var wsManager = WebSocketManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch currentView {
                case .menu:
                    MainMenuView(currentView: $currentView)
                case .game(let mode):
                    TicTacToeView(gameMode: mode) {
                        currentView = .menu
                        wsManager.disconnect()
                    }
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .onChange(of: wsManager.gameState) { newState in
                if newState == .active {
                    currentView = .game(.onlineServer)
                }
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        // tictacmoji://join?room=ABCD
        guard url.scheme == "tictacmoji",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else { return }
        
        if let roomId = queryItems.first(where: { $0.name == "room" })?.value {
            // Join Room
            wsManager.connect()
            // Wait slightly for connection or handle in connect completion
            // For now, simple delay hack or let wsManager handle queueing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                wsManager.joinRoom(roomId: roomId)
            }
        }
    }
}
