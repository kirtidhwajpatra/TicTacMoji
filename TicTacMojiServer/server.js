const http = require('http');
const WebSocket = require('ws');

const PORT = process.env.PORT || 8080;

// Initialize HTTP Server for Health Checks and WS Upgrade
const server = http.createServer((req, res) => {
    if (req.method === 'GET' && req.url === '/health') {
        res.writeHead(200, { 'Content-Type': 'text/plain' });
        res.end('OK');
    } else {
        res.writeHead(404);
        res.end();
    }
});

// Attach WebSocket Server to HTTP Server
const wss = new WebSocket.Server({ server });

const rooms = {};

// Heartbeat to detect stale connections
const interval = setInterval(() => {
    wss.clients.forEach((ws) => {
        if (ws.isAlive === false) return ws.terminate();
        ws.isAlive = false;
        ws.ping();
    });
}, 30000);

wss.on('close', () => clearInterval(interval));

function generateRoomId() {
    return Math.random().toString(36).substring(2, 6).toUpperCase();
}

wss.on('connection', (ws) => {
    ws.isAlive = true;
    ws.on('pong', () => { ws.isAlive = true; });

    ws.on('message', (message) => {
        try {
            const data = JSON.parse(message);

            // Create Room
            if (data.type === 'create_room') {
                const roomId = generateRoomId();
                const userData = data.userData || { name: 'Player 1', avatar: '😎' };
                ws.userData = userData;
                ws.roomId = roomId;

                rooms[roomId] = {
                    players: [ws],
                    turn: 0,
                    board: Array(9).fill(null),
                    gameActive: false
                };

                ws.send(JSON.stringify({ type: 'room_created', roomId }));
            }

            // Join Room
            else if (data.type === 'join_room') {
                const roomId = data.roomId;
                const guestData = data.userData || { name: 'Player 2', avatar: '🤠' };

                if (rooms[roomId] && rooms[roomId].players.length < 2) {
                    ws.roomId = roomId;
                    ws.userData = guestData;
                    rooms[roomId].players.push(ws);

                    const host = rooms[roomId].players[0];

                    // Notify Host
                    host.send(JSON.stringify({
                        type: 'player_joined',
                        opponent: guestData
                    }));

                    // Notify Guest
                    ws.send(JSON.stringify({
                        type: 'joined_room',
                        roomId,
                        opponent: host.userData
                    }));

                    startCountdown(roomId);
                } else {
                    ws.send(JSON.stringify({ type: 'error', message: 'Room full or invalid' }));
                }
            }

            // Game Move
            else if (data.type === 'move') {
                const roomId = ws.roomId;
                if (roomId && rooms[roomId] && rooms[roomId].gameActive) {
                    const room = rooms[roomId];
                    const playerIndex = room.players.indexOf(ws);

                    if (room.turn === playerIndex && room.board[data.index] === null) {
                        room.board[data.index] = playerIndex;
                        room.turn = 1 - room.turn;

                        const opponent = room.players.find(p => p !== ws);
                        if (opponent) {
                            opponent.send(JSON.stringify({
                                type: 'opponent_move',
                                index: data.index,
                                player: playerIndex
                            }));
                        }
                    }
                }
            }

            // Rematch Request
            else if (data.type === 'request_rematch') {
                const roomId = ws.roomId;
                if (roomId && rooms[roomId]) {
                    const room = rooms[roomId];
                    ws.wantsRematch = true;

                    const opponent = room.players.find(p => p !== ws);
                    if (opponent) {
                        if (opponent.wantsRematch) {
                            startRematch(roomId);
                        } else {
                            opponent.send(JSON.stringify({ type: 'rematch_requested' }));
                        }
                    }
                }
            }

        } catch (e) {
            console.error('Message parsing failed:', e.message);
        }
    });

    ws.on('close', () => {
        const roomId = ws.roomId;
        if (roomId && rooms[roomId]) {
            const room = rooms[roomId];

            // Notify other player
            room.players.forEach(p => {
                if (p !== ws && p.readyState === WebSocket.OPEN) {
                    p.send(JSON.stringify({ type: 'opponent_left' }));
                }
            });

            // Cleanup
            room.players = room.players.filter(p => p !== ws);
            if (room.players.length === 0) {
                delete rooms[roomId];
            }
        }
    });
});

function startCountdown(roomId) {
    const room = rooms[roomId];
    if (!room) return;

    let count = 3;
    broadcastToRoom(room, { type: 'countdown', count });

    room.countdownInterval = setInterval(() => {
        count--;
        if (count > 0) {
            broadcastToRoom(room, { type: 'countdown', count });
        } else {
            clearInterval(room.countdownInterval);
            room.gameActive = true;
            broadcastToRoom(room, { type: 'game_start' });
        }
    }, 1000);
}

function startRematch(roomId) {
    const room = rooms[roomId];
    if (!room) return;

    room.board = Array(9).fill(null);
    room.turn = 0;
    room.gameActive = false;
    room.players.forEach(p => p.wantsRematch = false);

    startCountdown(roomId);
}

function broadcastToRoom(room, message) {
    const msg = JSON.stringify(message);
    room.players.forEach(p => {
        if (p.readyState === WebSocket.OPEN) p.send(msg);
    });
}

server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
