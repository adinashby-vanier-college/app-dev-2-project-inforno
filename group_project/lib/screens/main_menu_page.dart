import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Main menu screen (AI aggregator)
class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inforno')),
      body: const _ChatPane(),
    );
  }
}

class _ChatPane extends StatefulWidget {
  const _ChatPane();

  @override
  State<_ChatPane> createState() => _ChatPaneState();
}

class _ChatPaneState extends State<_ChatPane> {
  final _controller = TextEditingController();
  final List<Message> _messages = [];
  final List<Message> _messages1 = [];
  final List<Message> _messages2 = [];
  final List<Message> _messages3 = [];
  bool _isLoading = false;
  late final String apiKey;
  final String endpoint = 'https://openrouter.ai/api/v1/chat/completions';

  @override
  void initState() {
    super.initState();
    apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      _messages.add(
        const Message(
          content: 'Error: Missing OPENROUTER_API_KEY in .env',
          role: 'system',
        ),
      );
    }
  }

  Future<void> _sendMessage(
    String text,
    String model,
    List<Message> messageList,
  ) async {
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'model': model,
      'messages':
          messageList
              .map((m) => {'role': m.role, 'content': m.content})
              .toList(),
    });

    try {
      final resp = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: body,
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final content = data['choices'][0]['message']['content'];
        setState(() {
          _messages.add(Message(content: '$model: $content', role: 'system'));
          messageList.add(Message(content: content, role: 'assistant'));
          _isLoading = false;
        });
      } else {
        throw Exception('Failed with ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      setState(() {
        final err = 'Error: $e';
        _messages.add(Message(content: err, role: 'system'));
        messageList.add(Message(content: err, role: 'system'));
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessages(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = Message(content: text, role: 'user');
    setState(() {
      _messages.add(userMessage);
      _messages1.add(userMessage);
      _messages2.add(userMessage);
      _messages3.add(userMessage);
      _isLoading = true;
    });

    _sendMessage(text, 'deepseek/deepseek-r1-0528:free', _messages1);
    _sendMessage(text, 'google/gemma-3n-e4b-it:free', _messages2);
    _sendMessage(text, 'tngtech/deepseek-r1t-chimera:free', _messages3);

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _messages.length,
            itemBuilder: (_, i) => ChatBubble(message: _messages[i]),
          ),
        ),
        if (_isLoading) const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: _sendMessages,
                  decoration: const InputDecoration(
                    hintText: 'Enter your message',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _sendMessages(_controller.text),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class Message {
  final String content;
  final String role;
  const Message({required this.content, required this.role});
}

class ChatBubble extends StatelessWidget {
  final Message message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final alignment =
        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bgColor = isUser ? Colors.blue[100] : Colors.grey[200];

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(message.content.trim()),
        ),
      ],
    );
  }
}
