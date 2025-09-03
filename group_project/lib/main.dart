// lib/main.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:uuid/uuid.dart';

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: 'https://soakitbaljxefdzhegso.supabase.co',
    anonKey: 'sb_publishable_U90sK0zFlOSCRMqAN1yrrQ_EFNlZdSA',
  );

  runApp(const MyApp());
}

Future<String> insertChat(String ctitle, String cjson) async {
  try {
    final User? user = supabase.auth.currentUser;
    final String chatId = const Uuid().v4();

    if (user != null) {
      final String userId = user.id;
      final data = await supabase.from('chat').insert({
        'cid': chatId,
        'cuid': userId,
        'ctitle': ctitle,
        'cjson': cjson,
      });
      // ignore: avoid_print
      print('Data inserted successfully: $data');
    }
    return chatId;
  } catch (error) {
    // ignore: avoid_print
    print('Error inserting data: $error');
    return "";
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _mode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inforno',
      debugShowCheckedModeBanner: false,
      themeMode: _mode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6750A4),
        brightness: Brightness.light,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          isDense: true,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6750A4),
        brightness: Brightness.dark,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          isDense: true,
        ),
      ),
      home: AuthGate(
        onToggleTheme: () {
          setState(() {
            _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
          });
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  const AuthGate({super.key, this.onToggleTheme});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Keep a reference so we can dispose the listener.
  late final Stream<AuthState> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = supabase.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStream,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;
        if (session == null) {
          // Not signed in → show Supabase Auth UI
          return AuthScreen(onToggleTheme: widget.onToggleTheme);
        }
        // Signed in → go to your existing chat page
        return OpenRouterChatPage(onToggleTheme: widget.onToggleTheme);
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// AuthScreen composed of Supabase Auth UI widgets
class AuthScreen extends StatelessWidget {
  final VoidCallback? onToggleTheme;
  const AuthScreen({super.key, this.onToggleTheme});

  // Deep link for iOS/Android; leave null on web.
  static const String _mobileRedirect = 'inforno://callback';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in • Inforno'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: onToggleTheme,
            icon: const Icon(Icons.brightness_6_outlined),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Welcome',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in to start chatting',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),

                      // Email / Password
                      SupaEmailAuth(
                        redirectTo: kIsWeb ? null : _mobileRedirect,
                        onSignInComplete: (AuthResponse res) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Signed in!')),
                          );
                        },
                        onSignUpComplete: (AuthResponse res) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Signed up! Check your email if confirmation is enabled.')),
                          );
                        },
                        metadataFields: [
                          MetaDataField(
                            prefixIcon: const Icon(Icons.person_outline),
                            label: 'Username',
                            key: 'username',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Magic link (optional)
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Use a magic link instead'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: SupaMagicAuth(
                              redirectUrl: kIsWeb ? null : _mobileRedirect,
                              onSuccess: (Session _) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Magic link sent!')),
                                );
                              },
                              onError: (error) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $error')),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Socials (Google/Apple shown; add others if enabled)
                      SupaSocialsAuth(
                        socialProviders: const [
                          OAuthProvider.apple,
                          OAuthProvider.google,
                        ],
                        colored: true,
                        redirectUrl: kIsWeb ? null : _mobileRedirect,
                        onSuccess: (Session _) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Signed in!')),
                          );
                        },
                        onError: (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $error')),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Continue as guest (anonymous)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.person_outline),
                        label: const Text('Continue as guest'),
                        onPressed: () async {
                          try {
                            await supabase.auth.signInAnonymously();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Password reset
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Reset password',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SupaResetPassword(
                        accessToken: supabase.auth.currentSession?.accessToken,
                        onSuccess: (UserResponse _) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Email sent!')),
                          );
                        },
                        onError: (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $error')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Your existing pages, lightly adapted (added Sign out to the drawer)
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<dynamic>> _future;

  Future<List<dynamic>> _fetchChats() async {
    final data = await supabase
        .from('chat')
        .select()
        .order('cmodified', ascending: false);
    return (data as List).toList();
  }

  @override
  void initState() {
    super.initState();
    _future = _fetchChats();
  }

  Future<void> _renameChat({
    required String cid,
    required String currentTitle,
  }) async {
    final controller = TextEditingController(text: currentTitle);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Rename chat'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 60,
            decoration: const InputDecoration(hintText: 'Enter new title'),
            onSubmitted: (v) => Navigator.of(ctx).pop(v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newTitle == null) return; // cancelled
    if (newTitle.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Title can't be empty.")));
      return;
    }

    try {
      await supabase.from('chat').update({'ctitle': newTitle}).eq('cid', cid);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Title updated')));
      setState(() => _future = _fetchChats());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error updating: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("History • Inforno")),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snapshot.data!;
          if (chats.isEmpty) {
            return const Center(child: Text("No chats yet — go start one!"));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: chats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final chat = chats[index] as Map<String, dynamic>;
              final title = (chat['ctitle'] ?? 'Untitled') as String;
              final cid = (chat['cid'] ?? '') as String;

              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  title: Text(title),
                  subtitle: Text(
                    cid,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  leading: const Icon(Icons.chat_bubble_outline),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OpenRouterChatPage(chatId: cid),
                      ),
                    );
                  },
                  onLongPress: () {
                    _renameChat(cid: cid, currentTitle: title);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class OpenRouterChatPage extends StatefulWidget {
  final String chatId;
  final VoidCallback? onToggleTheme;
  const OpenRouterChatPage({super.key, this.chatId = "", this.onToggleTheme});
  @override
  State<OpenRouterChatPage> createState() => _OpenRouterChatPageState();
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

  int _drawerIndex = 0;

  final Set<String> _selectedModels = {'deepseek/deepseek-r1-0528:free'};
  static const models = <String>{
    'deepseek/deepseek-r1-0528:free',
    'google/gemma-3n-e4b-it:free',
    'openai/gpt-oss-20b:free'
  };

  @override
  void initState() {
    super.initState();
    apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      _messages.add(
        const Message(
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

    final response =
    await http.post(Uri.parse(endpoint), headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      setState(() {
        final newMsg = Message(content: '$model: $content', role: 'system');
        _messages.add(newMsg);
        messageList.add(Message(content: content, role: 'assistant'));
      });
    } else {
      throw Exception('Failed with ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> _sendMessages(String text) async {
    if (text.trim().isEmpty || apiKey.isEmpty) return;

    final userMessage = Message(content: text, role: 'user');

    setState(() {
      _messages.add(userMessage);
      _messages1.add(userMessage);
      _messages2.add(userMessage);
      _messages3.add(userMessage);
      _isLoading = true;
    });

    try {
      final tasks = <Future<void>>[];
      for (final m in _selectedModels) {
        if (m.contains('deepseek')) {
          tasks.add(_sendMessage(text, m, _messages1));
        } else if (m.contains('gemma')) {
          tasks.add(_sendMessage(text, m, _messages2));
        } else {
          tasks.add(_sendMessage(text, m, _messages3));
        }
      }
      await Future.wait(tasks);

      final firstUser =
          _messages
              .firstWhere((m) => m.role == 'user', orElse: () => userMessage)
              .content;
      final title =
      firstUser.length <= 44 ? firstUser : firstUser.substring(0, 44);
      await insertChat(title, jsonEncode(_messages));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Reply received')));
      }
    } catch (e) {
      setState(() {
        final errorMsg = 'Error: $e';
        _messages.add(Message(content: errorMsg, role: 'system'));
        _messages1.add(Message(content: errorMsg, role: 'system'));
        _messages2.add(Message(content: errorMsg, role: 'system'));
        _messages3.add(Message(content: errorMsg, role: 'system'));
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _controller.clear();
    }
  }

  void _newChat() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OpenRouterChatPage(onToggleTheme: widget.onToggleTheme),
      ),
    );
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    // Pop to root; AuthGate will show the AuthScreen automatically
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inforno ${widget.chatId.isNotEmpty ? "• ${widget.chatId}" : ""}',
        ),
        actions: [
          IconButton(
            tooltip: 'History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            },
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: widget.onToggleTheme,
            icon: const Icon(Icons.brightness_6_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: NavigationDrawer(
        selectedIndex: _drawerIndex,
        onDestinationSelected: (index) {
          setState(() => _drawerIndex = index);
          Navigator.pop(context);
          if (index == 0) {
            _newChat();
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryPage()),
            );
          } else if (index == 2) {
            _signOut();
          }
        },
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 16, 16, 6),
            child: Text(
              'Navigate',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: Text('New Chat'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history_toggle_off),
            label: Text('History'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.logout),
            selectedIcon: Icon(Icons.logout),
            label: Text('Sign out'),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 16, 16, 6),
            child: Text(
              'Models',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SegmentedButton<String>(
              segments: models
                  .map((m) => ButtonSegment<String>(
                value: m,
                label: Text(_prettyModel(m)),
              ))
                  .toList(),
              selected: _selectedModels,
              multiSelectionEnabled: true,
              showSelectedIcon: false,
              onSelectionChanged: (set) {
                setState(() => _selectedModels..clear()..addAll(set));
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(message: _messages[index]);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessages,
                      decoration: const InputDecoration(
                        hintText: 'Type your message…',
                        prefixIcon: Icon(Icons.message_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _sendMessages(_controller.text),
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _prettyModel(String id) {
    if (id.contains('deepseek')) return 'DeepSeek R1';
    if (id.contains('gemma')) return 'Gemma 3n e4b';
    if (id.contains('gpt-oss')) return 'GPT-OSS 20B';
    return id;
  }
}

class Message {
  final String content;
  final String role;
  const Message({required this.content, required this.role});

  Map<String, dynamic> toJson() => {'content': content, 'role': role};
}

class ChatBubble extends StatelessWidget {
  final Message message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final cs = Theme.of(context).colorScheme;

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 6),
          color: isUser ? cs.primaryContainer : cs.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              message.content.trim(),
              style: TextStyle(
                color: isUser ? cs.onPrimaryContainer : cs.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
