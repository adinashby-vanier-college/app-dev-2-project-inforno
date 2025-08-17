import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final supabase = Supabase.instance.client;

Future<void> main() async {
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: 'https://soakitbaljxefdzhegso.supabase.co',
    anonKey: 'sb_publishable_U90sK0zFlOSCRMqAN1yrrQ_EFNlZdSA',
  );

  var supabase = Supabase.instance.client;
  await supabase.auth.signInAnonymously();

  insertData();

  runApp(MyApp());
}

Future<void> insertData() async {
  try {
    final User? user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      final String userId = user.id;
      final data = await supabase
          .from('chat') // Replace 'your_table_name' with your actual table name
          .insert({
            'cid': Uuid().v4(),
            'cuid': userId,
            'ctitle': 'test', // Replace with your column names and values
            'cjson': '{}',
            // Add more key-value pairs for other columns
          });
      print('Data inserted successfully: $data');
    }
  } catch (error) {
    print('Error inserting data: $error');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inforno',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: OpenRouterChatPage(),
    );
  }
}

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _future = Supabase.instance.client
      .from('chat')
      .select();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("History - Inforno"),
        ),
        body: Expanded(
          child: FutureBuilder(
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                };
                final chats = snapshot.data!;
                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: ((context, index) {
                    final chat = chats[index];
                    return ListTile(
                      title: Text(chat['ctitle']),
                    );
                  }),
                );
              }
          ),
        ),
    );
  }
}

class OpenRouterChatPage extends StatefulWidget {
  @override
  _OpenRouterChatPageState createState() => _OpenRouterChatPageState();
}

class _OpenRouterChatPageState extends State<OpenRouterChatPage> {
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
        Message(
          content: 'Error: Missing API key. Check your .env file.',
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
              .map((msg) => {'role': msg.role, 'content': msg.content})
              .toList(),
    });

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        setState(() {
          final newMsg = Message(content: '$model: $content', role: 'system');
          _messages.add(newMsg);
          messageList.add(Message(content: content, role: 'assistant'));
          _isLoading = false;
        });
      } else {
        throw Exception('Failed with ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() {
        final errorMsg = 'Error: $e';
        _messages.add(Message(content: errorMsg, role: 'system'));
        messageList.add(Message(content: errorMsg, role: 'system'));
        _isLoading = false;
      });
    }

    _controller.clear();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat - Inforno"),
        leading: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Text("New Chat"),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            MyApp()));
              },
            ),
            PopupMenuItem(
              child: Text("History"),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            HistoryPage()));
              },
            ),
          ]
        )
      ),
      //appBar: AppBar(title: Text('Inforno')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(message: _messages[index]);
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

class Message {
  final String content;
  final String role;

  Message({required this.content, required this.role});
}

class ChatBubble extends StatelessWidget {
  final Message message;

  const ChatBubble({required this.message});

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
          margin: EdgeInsets.symmetric(vertical: 4.0),
          padding: EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(message.content.trim()),
        ),
      ],
    );
  }
}
