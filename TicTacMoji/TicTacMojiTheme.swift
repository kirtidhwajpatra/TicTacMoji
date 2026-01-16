//
//  TicTacMojiTheme.swift
//  TicTacMoji
//
//  Created by Mr SwiftUI on 16/01/26.
//

import SwiftUI

struct TicTacToeTheme {
    static let background = Color.black
    static let accent = Color(red: 255/255, green: 215/255, blue: 0/255) // Gold/Yellow
    static let gridLine = Color.white.opacity(0.2)
    static let text = Color.white
    
    // Emojis from your design
    static let player1Icon = "🌻" // Sunflower
    static let player2Icon = "🍄" // Mushroom
    static let fontName = "RoundedMplus1c-ExtraBold" // System rounded fallback used in code
}
