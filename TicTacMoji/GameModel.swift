//
//  GameModel.swift
//  TicTacMoji
//
//  Created by Mr SwiftUI on 16/01/26.
//

import Foundation

enum GameMode {
    case vsHuman
    case vsMachine
    case onlineServer
}

enum Player: Equatable {
    case p1, p2
    
    var icon: String {
        switch self {
        case .p1: return "🍄"
        case .p2: return "🌼"
        }
    }
    
    // For the UI logic
    var next: Player { self == .p1 ? .p2 : .p1 }
}

struct Move {
    let player: Player
    let boardIndex: Int
}

enum GameState: Equatable {
    case active
    case draw
    case won(Player)
}
