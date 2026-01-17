//
//  TicTacMojiTheme.swift
//  TicTacMoji
//
//  Created by Mr SwiftUI on 16/01/26.
//

import SwiftUI

struct TicTacMojiTheme {
    // Neon Noir Palette
    static let backgroundStart = Color(hex: "1A1A1A") // Dark Graphite
    static let backgroundEnd = Color(hex: "050505")   // Deep Black
    
    static let neonBlue = Color(hex: "00F0FF")        // Cyber Blue
    static let neonPink = Color(hex: "FF0099")        // Cyber Pink
    static let neonGreen = Color(hex: "39FF14")       // Neon Green (Win)
    static let glassBorder = Color.white.opacity(0.15)
    static let glassSurface = Color.white.opacity(0.05)
    
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
}

