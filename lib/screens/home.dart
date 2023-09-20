import 'package:flutter/material.dart';
import 'package:flutter_socket_project/model/message.dart';
import 'package:flutter_socket_project/providers/home.dart';
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({Key? key, required this.username}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late IO.Socket _socket;
  final TextEditingController _messageInputController = TextEditingController();
  var logger = Logger();

  _sendMessage() {
    logger.d("jdk, try to send a message");
    _socket.emit('message', {
      // event 이름을 "message"로 지정, map data를 전송한다.
      'message': _messageInputController.text.trim(),
      'sender': widget.username
    });
    _messageInputController.clear();
    logger.d("jdk, message sending is ended.");
  }

  // private method
  _connectSocket() {
    // 연결될 때 실행
    _socket.onConnect((data) => logger.d('Connection established'));

    // 연결이 실패했을 때 실행
    _socket.onConnectError((data) => logger.d('Connect Error: $data'));

    // 연결이 해제될 때
    _socket.onDisconnect((data) => logger.d('Socket.IO server disconnected'));

    // socket을 통해서 'message' event를 listen 한다.
    // 데이터가 들어올 시, addNewMessage 메서드를 실행한다.
    _socket.on('message', (data) {
      logger.d("jdk, <message> is invoked!");
      Provider.of<HomeProvider>(context, listen: false)
          .addNewMessage(Message.fromJson(data));
    });
  }

  @override
  void initState() {
    super.initState();
    //Important: If your server is running on localhost and you are testing your app on Android then replace http://localhost:3000 with http://10.0.2.2:3000
    // 통신을 담당할 socket 객체를 초기화한다.
    _socket = IO.io(
      'http://10.0.2.2:3000',
      IO.OptionBuilder().setTransports(['websocket']).setQuery(
        {
          'username': widget.username, // io connection을 생성할 때 data를 전송.
        },
      ).build(),
    );

    logger.d("jdk, try to connecting the webSocket.");
    _connectSocket(); // socket 연결 시도
    logger.d("jdk, webSocket is connected...");
  }

  @override
  void dispose() {
    _messageInputController.dispose(); // textEditingController는 dispose 해주어야 함.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Socket.IO'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<HomeProvider>(
              builder: (_, provider, __) => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final message = provider.messages[index];
                  return Wrap(
                    alignment: message.senderUsername == widget.username
                        ? WrapAlignment.end
                        : WrapAlignment.start,
                    children: [
                      Card(
                        color: message.senderUsername == widget.username
                            ? Theme.of(context).primaryColorLight
                            : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment:
                                message.senderUsername == widget.username
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.senderUsername,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(message.message),
                              Text(
                                DateFormat('hh:mm a').format(message.sentAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  );
                },
                separatorBuilder: (_, index) => const SizedBox(
                  height: 5,
                ),
                itemCount: provider.messages.length,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageInputController,
                      decoration: const InputDecoration(
                        hintText: 'Type your message here...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_messageInputController.text.trim().isNotEmpty) {
                        _sendMessage();
                      }
                    },
                    icon: const Icon(Icons.send),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
