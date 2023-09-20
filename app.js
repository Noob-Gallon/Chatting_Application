const express = require("express");
const app = express();
const http = require("http");
const server = http.createServer(app);
const { Server } = require("socket.io");
const io = new Server(server);
const PORT = process.env.PORT || 3000;
const messages = [];

app.get('/', (req, res) => {
    res.sendFile(__dirname + '/index.html');
});

// 2023.09.21, jdk
// connection이라는 event name은 기본으로 정해진 이름인듯.
// 초기에 socket을 연결할 때 실행되는 것으로 보인다.
io.on('connection', (socket) => {
    const username = socket.handshake.query.username;
    console.log('username : ', username);

    // Q. io.on과 socket.on의 차이점?
    // => socket.on을 하면 event의 전달을 listening?
    socket.on('message', (data) => {
        console.log('A <message> event has arrived');
        console.log("data : ", data);

        // 전달받은 데이터
        const message = {
            message: data.message,
            senderUsername: username,
            sentAt: Date.now()
        };

        // const message2 = {
        //     message: "하이하이",
        //     senderUsername: "정동교",
        //     sentAt: Date.now()
        // }

        messages.push(message); // messages array에 전달받은 데이터를 저장.

        io.emit('message', message); // "event" 발행
        // io.emit('message', message2);
    })
});

server.listen(PORT, () => {
    console.log('listening on *:3000');
});
