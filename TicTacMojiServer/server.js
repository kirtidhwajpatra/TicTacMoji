const WebSocket = require('ws');
const port = process.env.PORT || 8080;
const wss = new WebSocket.Server({ port: port, host: '0.0.0.0' });

const rooms = {};

function generateRoomId() {
    return Math.random().toString(36).substring(2, 6).toUpperCase();
}

console.log(' TicTacMoji Server started on port 8080');

wss.on('connection', (ws) => {
    let currentRoomId = null;
    let playerIndex = null;
    console.log('New client connected');

    ws.on('message', (message) => {
        try {
            const data = JSON.parse(message);
            console.log('Received:', data);

            if (data.type === 'create_room') {
                const roomId = generateRoomId();
                // Store userData on the socket
                const userData = data.userData || { name: 'Player 1', avatar: '😎' };
                ws.userData = userData;

                rooms[roomId] = { players: [ws], turn: 0, board: Array(9).fill(null), gameActive: false };
                ws.roomId = roomId;
                ws.send(JSON.stringify({ type: 'room_created', roomId }));
                console.log(`Room ${roomId} created`);
            }
            else if (data.type === 'join_room') {
                const roomId = data.roomId;
                const guestData = data.userData || { name: 'Player 2', avatar: '🤠' };

                if (rooms[roomId] && rooms[roomId].players.length < 2) {
                    ws.roomId = roomId;
                    ws.userData = guestData;
                    rooms[roomId].players.push(ws);

                    const host = rooms[roomId].players[0];

                    // Notify Host that Guest joined (send Guest data)
                    host.send(JSON.stringify({
                        type: 'player_joined',
                        opponent: guestData
                    }));

                    // Notify Guest that they joined (send Host data)
                    ws.send(JSON.stringify({
                        type: 'joined_room',
                        roomId,
                        opponent: host.userData
                    }));

                    console.log(`Player joined room ${roomId}`);

                    // Start Countdown
                    let count = 3;
                    rooms[roomId].countdownInterval = setInterval(() => {
                        broadcastToRoom(rooms[roomId], { type: 'countdown', count });
                        if (count === 0) {
                            clearInterval(rooms[roomId].countdownInterval);
                            rooms[roomId].gameActive = true;
                            broadcastToRoom(rooms[roomId], { type: 'game_start' });
                        }
                        count--;
                    }, 1000);

                } else {
                    ws.send(JSON.stringify({ type: 'error', message: 'Room full or invalid' }));
                }
            }
            else if (data.type === 'move') {
                const roomId = ws.roomId;
                if (roomId && rooms[roomId] && rooms[roomId].gameActive) {
                    const room = rooms[roomId];
                    const playerIndex = room.players.indexOf(ws);

                    if (room.turn === playerIndex) {
                        const index = data.index;
                        if (room.board[index] === null) {
                            room.board[index] = playerIndex;
                            room.turn = 1 - room.turn;

                            // Broadcast move to opponent
                            const opponent = room.players.find(p => p !== ws);
                            if (opponent) {
                                opponent.send(JSON.stringify({
                                    type: 'opponent_move',
                                    index: index,
                                    player: playerIndex
                                }));
                            }
                        }
                    }
                }
            }
            // Rematch Logic
            else if (data.type === 'request_rematch') {
                const roomId = ws.roomId;
                if (roomId && rooms[roomId]) {
                    const room = rooms[roomId];
                    ws.wantsRematch = true;

                    const otherPlayer = room.players.find(p => p !== ws);

                    if (otherPlayer) {
                        if (otherPlayer.wantsRematch) {
                            // Both want rematch -> Start Game
                            console.log(`Rematch started in room ${roomId}`);
                            room.board = Array(9).fill(null);
                            room.turn = 0; // Reset turn to Host
                            room.gameActive = false; // Wait for countdown
                            room.players.forEach(p => p.wantsRematch = false); // Reset flag

                            // Start Countdown
                            let count = 3;
                            room.countdownInterval = setInterval(() => {
                                broadcastToRoom(room, { type: 'countdown', count });
                                if (count === 0) {
                                    clearInterval(room.countdownInterval);
                                    room.gameActive = true;
                                    broadcastToRoom(room, { type: 'game_start' });
                                }
                                count--;
                            }, 1000);
                        } else {
                            // Notify opponent
                            otherPlayer.send(JSON.stringify({ type: 'rematch_requested' }));
                        }
                    }
                }
            }
            else if (data.type === 'game_over') {
                // Relay game over if needed, mostly client side
            }

        } catch (e) {
            console.error('Error parsing message', e);
        }
    });

    ws.on('close', () => {
        if (currentRoomId && rooms[currentRoomId]) {
            console.log(`Client disconnected from room ${currentRoomId}`);
            // Notify opponent
            const room = rooms[currentRoomId];
            room.players.forEach(p => {
                if (p !== ws && p.readyState === WebSocket.OPEN) {
                    p.send(JSON.stringify({ type: 'opponent_left' }));
                }
            });
            delete rooms[currentRoomId];
        }
    });
});

function startCountdown(roomId) {
    let count = 3;
    const room = rooms[roomId];
    if (!room) return;

    console.log(`Starting countdown for room ${roomId}`);

    // Immediate 3
    broadcastToRoom(room, { type: 'countdown', count: 3 });

    const interval = setInterval(() => {
        count--;
        if (count > 0) {
            broadcastToRoom(room, { type: 'countdown', count: count });
        } else {
            clearInterval(interval);
            broadcastToRoom(room, { type: 'game_start' });
        }
    }, 1000);
}

function broadcastToRoom(room, message) {
    const msgString = JSON.stringify(message);
    room.players.forEach(p => {
        if (p.readyState === WebSocket.OPEN) {
            p.send(msgString);
        }
    });
}
