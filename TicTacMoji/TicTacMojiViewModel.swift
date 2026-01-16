import SwiftUI
import Combine
import MultipeerConnectivity

class TicTacToeViewModel: ObservableObject {
    @Published var board: [Player?] = Array(repeating: nil, count: 9)
    @Published var activePlayer: Player = .p1
    @Published var gameState: GameState = .active
    @Published var winningIndices: Set<Int> = []
    
    // Scores
    @Published var p1Score = 0
    @Published var p2Score = 0
    
    // Player Info
    @Published var p1Name: String = "Player 1"
    @Published var p2Name: String = "Player 2"
    @Published var p1Avatar: String = "🍄"
    @Published var p2Avatar: String = "🌼"
    
    // Rematch State
    @Published var isOpponentReady: Bool = false
    @Published var waitingForRematch: Bool = false
    
    var gameMode: GameMode = .vsHuman
    var wsManager: WebSocketManager?
    private var cancellables = Set<AnyCancellable>()
    
    private let winPatterns: Set<Set<Int>> = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        [0, 4, 8], [2, 4, 6]
    ]
    
    init(gameMode: GameMode = .vsHuman) {
        self.gameMode = gameMode
        if gameMode == .onlineServer {
            self.wsManager = WebSocketManager.shared
        }
        
        setupPlayers()
        setupMultiplayerBindings()
    }
    
    private func setupPlayers() {
        let currentUser = ProfileManager.shared.currentUser
        p1Name = currentUser.name
        p1Avatar = currentUser.avatarRawValue
        
        switch gameMode {
        case .vsHuman:
            p2Name = "Friend"
            p2Avatar = "👤"
        case .vsMachine:
            p2Name = "Robot"
            p2Avatar = "🤖"
        case .onlineServer:
            // Initial placeholder, will be updated via binding
            p2Name = "Opponent"
            p2Avatar = "⏳" 
        }
    }
    
    private func setupMultiplayerBindings() {
        guard let wsManager = wsManager else { return }
        
        wsManager.$receivedMove
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] index in
                self?.handleRemoteMove(at: index)
            }
            .store(in: &cancellables)
            
        wsManager.$gameState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                if state == .opponentLeft {
                    // Handle opponent left
                }
            }
            .store(in: &cancellables)
            
        // Use combined publisher for identity to handle late updates
        Publishers.CombineLatest3(wsManager.$opponentName, wsManager.$opponentAvatar, wsManager.$playerIndex)
            .receive(on: RunLoop.main)
            .sink { [weak self] name, avatar, index in
                guard let self = self, let idx = index else { return }
                let oppName = name ?? "Opponent"
                let oppAvatar = avatar ?? "⏳"
                let myName = ProfileManager.shared.currentUser.name
                let myAvatar = ProfileManager.shared.currentUser.avatarRawValue
                
                if idx == 0 {
                    // I am Host (P1)
                    self.p1Name = myName
                    self.p1Avatar = myAvatar
                    self.p2Name = oppName
                    self.p2Avatar = oppAvatar
                } else {
                    // I am Guest (P2)
                    self.p1Name = oppName
                    self.p1Avatar = oppAvatar
                    self.p2Name = myName
                    self.p2Avatar = myAvatar
                }
            }
            .store(in: &cancellables)
            
        wsManager.$isRematchRequested
            .receive(on: RunLoop.main)
            .assign(to: &$isOpponentReady)
            
        // Reset waiting state if game becomes active again
        wsManager.$gameState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                if state == .active {
                    self?.waitingForRematch = false
                    self?.resetGame(keepOnline: true)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Game Action
    func processMove(at index: Int) {
        guard board[index] == nil, case .active = gameState else { return }
        
        // Online: Only allow move if it's my turn
        if gameMode == .onlineServer {
            guard wsManager?.isMyTurn == true else { return }
            wsManager?.sendMove(index: index)
            wsManager?.isMyTurn = false // Optimistic update
        }
        
        makeMove(index: index, player: activePlayer)
        
        // Machine Move
        if case .active = gameState, gameMode == .vsMachine, activePlayer == .p2 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.makeAIMove()
            }
        }
    }
    
    func handleRemoteMove(at index: Int) {
        guard board[index] == nil else { return }
        makeMove(index: index, player: activePlayer)
    }
    
    private func makeMove(index: Int, player: Player) {
        // Ensure we don't process moves if game is already over
        // (Prevents double scoring race conditions)
        if case .won = gameState { return }
        if case .draw = gameState { return }
        
        board[index] = player
        HapticManager.shared.lightImpact()
        SoundManager.shared.playClickSound()
        
        if checkForWin(player: player) {
            gameState = .won(player)
            if isLocalPlayer(player: player) {
                // Sound logic
                SoundManager.shared.playWinSound()
            } else {
                 SoundManager.shared.playLoseSound()
            }
            
            // Score update (Server tracks or local?)
            if player == .p1 { p1Score += 1 } else { p2Score += 1 }
            HapticManager.shared.successFeedback()
        } else if !board.contains(nil) {
            gameState = .draw
            SoundManager.shared.playDrawSound()
            HapticManager.shared.drawFeedback()
        } else {
            activePlayer = player.next
        }
    }
    
    // MARK: - AI Logic
    private func makeAIMove() {
        let availableMoves = board.indices.filter { board[$0] == nil }
        guard let move = findBestMove(availableMoves: availableMoves) else { return }
        makeMove(index: move, player: .p2)
    }
    
    private func findBestMove(availableMoves: [Int]) -> Int? {
        for i in availableMoves {
            if wouldWin(index: i, player: .p2) { return i }
        }
        for i in availableMoves {
            if wouldWin(index: i, player: .p1) { return i }
        }
        if availableMoves.contains(4) { return 4 }
        return availableMoves.randomElement()
    }
    
    private func wouldWin(index: Int, player: Player) -> Bool {
        var tempBoard = board
        tempBoard[index] = player
        return winPatterns.contains { pattern in
            pattern.allSatisfy { tempBoard[$0] == player }
        }
    }
    
    private func checkForWin(player: Player) -> Bool {
        for pattern in winPatterns {
            if pattern.allSatisfy({ board[$0] == player }) {
                winningIndices = pattern
                return true
            }
        }
        return false
    }
    
    func resetGame(keepOnline: Bool = false) {
        if gameMode == .onlineServer && !keepOnline {
            // Initiate rematch request
            wsManager?.requestRematch()
            waitingForRematch = true
            return
        }
        
        board = Array(repeating: nil, count: 9)
        activePlayer = .p1
        gameState = .active
        winningIndices = []
    }
    
    // MARK: - Helper
    private func isLocalPlayer(player: Player) -> Bool {
        if gameMode == .onlineServer {
            guard let idx = wsManager?.playerIndex else { return false }
            let myPlayer: Player = (idx == 0) ? .p1 : .p2
            return player == myPlayer
        }
        // Local: User is P1
        return player == .p1
    }
    
    var gameResultText: String {
        guard case .won(let winner) = gameState else { return "" }
        if gameMode == .vsHuman {
             return winner == .p1 ? "\(p1Name) Won!" : "\(p2Name) Won!"
        }
        return isLocalPlayer(player: winner) ? "You Won!" : "You Lost!"
    }
    
    var turnMessage: String {
        if gameMode == .onlineServer {
            return isLocalPlayer(player: activePlayer) ? "Your Turn" : "\(activePlayer == .p1 ? p1Name : p2Name)'s Turn"
        }
        return activePlayer == .p1 ? "Your Turn" : "\(p2Name)'s Turn"
    }
}
