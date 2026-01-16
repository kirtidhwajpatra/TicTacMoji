import SwiftUI
import Combine

enum WebSocketMessage {
    case createRoom
    case joinRoom(String)
    case move(Int)
}

class WebSocketManager: ObservableObject {
    static let shared = WebSocketManager()
    
    // Cloud Server URL (Render)
    private let url = URL(string: "wss://tictactoe-signaling.onrender.com")!
    
    private var webSocketTask: URLSessionWebSocketTask?
    
    @Published var isConnected = false
    @Published var gameState: ServerGameState = .disconnected
    @Published var roomId: String?
    @Published var receivedMove: Int?
    @Published var countdown: Int?
    @Published var isMyTurn = false
    @Published var isRematchRequested = false // State for UI
    @Published var playerIndex: Int? // 0 = Host (X), 1 = Guest (O)
    @Published var opponentName: String?
    @Published var opponentAvatar: String?
    
    private init() {}
    
    func connect() {
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessage()
        
        // Send a ping or just assume connected on open?
        // WebSocket doesn't have "onOpen" callback in URLSession easily unless delegate.
        // We'll assume connected for UI purposes or wait for first message if server sent one.
        // Let's just set connected.
        DispatchQueue.main.async {
            self.isConnected = true
            self.gameState = .menu
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        DispatchQueue.main.async {
            self.isConnected = false
            self.gameState = .disconnected
        }
    }
    
    func createRoom() {
        let user = ProfileManager.shared.currentUser
        let userData = ["name": user.name, "avatar": user.avatarRawValue]
        send(json: ["type": "create_room", "userData": userData])
    }
    
    func joinRoom(roomId: String) {
        let user = ProfileManager.shared.currentUser
        let userData = ["name": user.name, "avatar": user.avatarRawValue]
        send(json: ["type": "join_room", "roomId": roomId, "userData": userData])
    }
    
    func sendMove(index: Int) {
        send(json: ["type": "move", "index": index])
    }
    
    func requestRematch() {
        send(json: ["type": "request_rematch"])
    }
    
    private func send(json: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: json),
              let string = String(data: data, encoding: .utf8) else { return }
        
        let message = URLSessionWebSocketTask.Message.string(string)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                DispatchQueue.main.async {
                    self?.isConnected = false
                    self?.gameState = .connectionError(error.localizedDescription)
                }
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                case .data(let data):
                    print("Received binary data: \(data)")
                @unknown default:
                    break
                }
                
                // Keep receiving
                self?.receiveMessage()
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }
        
        DispatchQueue.main.async {
            switch type {
            case "room_created":
                if let rId = json["roomId"] as? String {
                    self.roomId = rId
                    self.gameState = .waitingForPlayer
                    self.playerIndex = 0
                }
            case "joined_room":
                if let rId = json["roomId"] as? String {
                    self.roomId = rId
                    self.gameState = .waitingForPlayer // Actually waiting for countdown
                    self.playerIndex = 1
                    
                    if let opponent = json["opponent"] as? [String: Any],
                       let name = opponent["name"] as? String,
                       let avatar = opponent["avatar"] as? String {
                        self.opponentName = name
                        self.opponentAvatar = avatar
                    }
                }
            case "player_joined":
                // Host sees this
                // Countdown starts automatically on server, but we can update UI
                self.gameState = .countingDown
                
                if let opponent = json["opponent"] as? [String: Any],
                   let name = opponent["name"] as? String,
                   let avatar = opponent["avatar"] as? String {
                    self.opponentName = name
                    self.opponentAvatar = avatar
                }
            case "countdown":
                if let count = json["count"] as? Int {
                    self.countdown = count
                    self.gameState = .countingDown
                }
            case "game_start":
                self.gameState = .active
                self.countdown = nil
                self.isRematchRequested = false // Reset state
                // Reset turn logic: Host (0) starts
                self.isMyTurn = (self.playerIndex == 0)
                
            case "rematch_requested":
                self.isRematchRequested = true
                
            case "opponent_move":
                if let index = json["index"] as? Int {
                    self.receivedMove = index
                    self.isMyTurn = true
                }
            case "opponent_left":
                self.gameState = .opponentLeft
            case "error":
                print("Server error: \(json["message"] ?? "")")
            default:
                break
            }
        }
    }
}

enum ServerGameState: Equatable {
    case disconnected
    case connectionError(String)
    case menu
    case waitingForPlayer
    case countingDown
    case active
    case opponentLeft
}
