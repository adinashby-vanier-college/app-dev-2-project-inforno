import 'package:flutter/material.dart';
import 'package:ollama_dart/ollama_dart.dart';
import 'dart:io' show Platform;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Remove the debug banner
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inforno',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: OllamaChatPage(),
    );
  }
}

class OllamaChatPage extends StatefulWidget {
  @override
  _OllamaChatPageState createState() => _OllamaChatPageState();
}

class _OllamaChatPageState extends State<OllamaChatPage> {
  final _controller = TextEditingController();
  final List<Message> _messages = [];
  final List<Message> _messages1 = [];
  final List<Message> _messages2 = [];
  final List<Message> _messages3 = [];
  bool _isLoading = false;

  late final OllamaClient client;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      client = OllamaClient(baseUrl: "http://localhost:11434/api");
    } else {
      client = OllamaClient(baseUrl: 'http://10.0.2.2:11434/api');
    }
  }

  Future<void> _sendMessage(
    String text,
    String model,
    List<Message> messages,
  ) async {
    final request = GenerateChatCompletionRequest(
      model: model, // Specify the model you want to use
      messages: messages,
      stream: false,
    );

    try {
      final generated = await client.generateChatCompletion(request: request);

      setState(() {
        Message m = Message(
          content: model + generated.message.content,
          role: MessageRole.system,
        );
        _messages.add(m);
        messages.add(generated.message);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(Message(content: 'Error: $e', role: MessageRole.system));
        messages.add(Message(content: 'Error: $e', role: MessageRole.system));
        _isLoading = false;
      });
    }

    _controller.clear();
  }

  Future<void> _sendMessages(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(Message(content: text, role: MessageRole.user));
      _messages1.add(Message(content: text, role: MessageRole.user));
      _messages2.add(Message(content: text, role: MessageRole.user));
      _messages3.add(Message(content: text, role: MessageRole.user));
      _isLoading = true;
    });
    _sendMessage(text, 'llama3.2:1b', _messages1);
    _sendMessage(text, 'deepseek-r1:1.5b', _messages2);
    _sendMessage(text, 'gemma3n:e2b', _messages3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inforno')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatBubble(message: message);
              },
            ),
          ),
          if (_isLoading) LinearProgressIndicator(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: _sendMessages,
                    decoration: InputDecoration(hintText: 'Enter your message'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => _sendMessages(_controller.text),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final Message message;

  const ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final alignment =
        message.role == MessageRole.user
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start;
    final bgColor =
        message.role == MessageRole.user ? Colors.blue[100] : Colors.grey[200];
    final textColor = Colors.black;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 4.0),
          padding: EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            message.content.trim(),
            style: TextStyle(color: textColor),
          ),
        ),
      ],
    );
  }
}
