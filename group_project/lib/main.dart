import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:uuid/uuid.dart';

final supabase = Supabase.instance.client;

const Set<String> kAvailableModels = {
  'deepseek/deepseek-r1-0528:free',
  'google/gemma-3n-e4b-it:free',
  'openai/gpt-oss-20b:free',
};
final ValueNotifier<Set<String>> selectedModels = ValueNotifier<Set<String>>({
  'deepseek/deepseek-r1-0528:free',
  'google/gemma-3n-e4b-it:free',
  'openai/gpt-oss-20b:free',
});

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
      routes: {
        '/': (_) => AuthGate(onToggleTheme: _toggleTheme),
        '/auth/register': (_) => const RegisterMagicPage(),
        '/auth/phone': (_) => const PhoneAuthPage(),
        '/chat/new': (_) => const NewChatPage(),
        '/chat': (_) => const ChatPage(),
        '/history': (_) => const HistoryPage(),
        '/models': (_) => const ModelPickerPage(),
        '/settings': (_) => SettingsPage(onToggleTheme: _toggleTheme),
      },
      initialRoute: '/',
    );
  }

  void _toggleTheme() {
    setState(() {
      _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }
}

class AuthGate extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  const AuthGate({super.key, this.onToggleTheme});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
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
          return AuthScreen(onToggleTheme: widget.onToggleTheme);
        }
        return const ChatPage();
      },
    );
  }
}

class AuthScreen extends StatelessWidget {
  final VoidCallback? onToggleTheme;
  const AuthScreen({super.key, this.onToggleTheme});

  static const String _mobileRedirect = 'inforno://callback';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in • Inforno'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
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

                      SupaEmailAuth(
                        redirectTo: kIsWeb ? null : _mobileRedirect,
                        onSignInComplete: (AuthResponse _) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Signed in!')),
                          );
                        },
                        onSignUpComplete: (AuthResponse _) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Signed up! Check your email if confirmation is enabled.',
                              ),
                            ),
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
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.mail_outline),
                              label: const Text('Register / Magic'),
                              onPressed:
                                  () => Navigator.pushNamed(
                                    context,
                                    '/auth/register',
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.sms_outlined),
                              label: const Text('Phone Auth'),
                              onPressed:
                                  () => Navigator.pushNamed(
                                    context,
                                    '/auth/phone',
                                  ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
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
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Reset password',
                        style: TextStyle(fontWeight: FontWeight.w600),
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

class RegisterMagicPage extends StatelessWidget {
  const RegisterMagicPage({super.key});
  static const String _mobileRedirect = 'inforno://callback';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register • Magic link')),
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
                        'Magic link',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SupaMagicAuth(
                        redirectUrl: kIsWeb ? null : _mobileRedirect,
                        onSuccess: (Session _) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Magic link sent!')),
                          );
                        },
                        onError:
                            (error) => ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('$error'))),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Or sign up with',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      SupaSocialsAuth(
                        socialProviders: const [
                          OAuthProvider.apple,
                          OAuthProvider.google,
                        ],
                        colored: true,
                        onSuccess: (Session _) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Signed in!')),
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

class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({super.key});
  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _sent = false;
  bool _busy = false;

  Future<void> _sendCode() async {
    setState(() => _busy = true);
    try {
      await supabase.auth.signInWithOtp(phone: _phoneCtrl.text.trim());
      setState(() => _sent = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Code sent via SMS')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _verifyCode() async {
    setState(() => _busy = true);
    try {
      await supabase.auth.verifyOTP(
        type: OtpType.sms,
        token: _otpCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Phone verified!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy =
        _busy ? const LinearProgressIndicator() : const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Phone Auth')),
      body: Column(
        children: [
          busy,
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone (+1 555 123 4567)',
                  ),
                ),
                const SizedBox(height: 12),
                if (_sent)
                  TextField(
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'SMS Code'),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.sms),
                        onPressed: _sent ? null : _sendCode,
                        label: const Text('Send code'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.verified),
                        onPressed: _sent ? _verifyCode : null,
                        label: const Text('Verify'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});
  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: ChatPageArgs(initialPrompt: text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Chat')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ValueListenableBuilder(
              valueListenable: selectedModels,
              builder: (context, Set<String> sel, _) {
                return Wrap(
                  spacing: 8,
                  runSpacing: -6,
                  children:
                      sel
                          .map((m) => Chip(label: Text(_prettyModel(m))))
                          .toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Ask something to kick off the chat…',
                prefixIcon: Icon(Icons.message_outlined),
              ),
              onSubmitted: (_) => _start(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.send),
                    onPressed: _start,
                    label: const Text('Start'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.tune),
                  onPressed: () => Navigator.pushNamed(context, '/models'),
                  label: const Text('Models'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatPageArgs {
  final String? initialPrompt;
  final String? existingChatId;
  const ChatPageArgs({this.initialPrompt, this.existingChatId});
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final List<Message> _messages = [];
  final List<Message> _m1 = [];
  final List<Message> _m2 = [];
  final List<Message> _m3 = [];
  bool _loading = false;

  late final String apiKey;
  final String endpoint = 'https://openrouter.ai/api/v1/chat/completions';

  String? _chatId;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is ChatPageArgs && (args.initialPrompt?.isNotEmpty ?? false)) {
        _controller.text = args.initialPrompt!;
        _sendMessages(_controller.text);
      }
      if (args is ChatPageArgs && args.existingChatId != null) {
        _chatId = args.existingChatId;
      }
    });
  }

  Future<void> _sendMessage(
    String text,
    String model,
    List<Message> list,
  ) async {
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'model': model,
      'messages':
          list.map((m) => {'role': m.role, 'content': m.content}).toList(),
    });
    final response = await http.post(
      Uri.parse(endpoint),
      headers: headers,
      body: body,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      setState(() {
        _messages.add(Message(content: '$model: $content', role: 'system'));
        list.add(Message(content: content, role: 'assistant'));
      });
    } else {
      throw Exception('Failed with ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> _sendMessages(String text) async {
    if (text.trim().isEmpty || apiKey.isEmpty) return;

    final userMsg = Message(content: text, role: 'user');
    setState(() {
      _messages.add(userMsg);
      _m1.add(userMsg);
      _m2.add(userMsg);
      _m3.add(userMsg);
      _loading = true;
    });

    try {
      final models = selectedModels.value;
      final tasks = <Future<void>>[];
      for (final m in models) {
        if (m.contains('deepseek')) {
          tasks.add(_sendMessage(text, m, _m1));
        } else if (m.contains('gemma')) {
          tasks.add(_sendMessage(text, m, _m2));
        } else {
          tasks.add(_sendMessage(text, m, _m3));
        }
      }
      await Future.wait(tasks);

      final firstUser =
          _messages
              .firstWhere((m) => m.role == 'user', orElse: () => userMsg)
              .content;
      final title =
          firstUser.length <= 44 ? firstUser : firstUser.substring(0, 44);
      _chatId ??= await insertChat(title, jsonEncode(_messages));

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reply received')));
      }
    } catch (e) {
      setState(() {
        final errorMsg = 'Error: $e';
        for (final l in [_messages, _m1, _m2, _m3]) {
          l.add(Message(content: errorMsg, role: 'system'));
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
      _controller.clear();
    }
  }

  void _openDrawerRoute(String route) {
    Navigator.pop(context);
    if (ModalRoute.of(context)?.settings.name == route) return;
    Navigator.pushNamed(context, route);
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat ${_chatId != null ? "• $_chatId" : ""}'),
        actions: [
          IconButton(
            tooltip: 'New Chat',
            onPressed: () => Navigator.pushNamed(context, '/chat/new'),
            icon: const Icon(Icons.add_comment_outlined),
          ),
          IconButton(
            tooltip: 'History',
            onPressed: () => Navigator.pushNamed(context, '/history'),
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Models',
            onPressed: () => Navigator.pushNamed(context, '/models'),
            icon: const Icon(Icons.tune),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      drawer: NavigationDrawer(
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              _openDrawerRoute('/chat/new');
              break;
            case 1:
              _openDrawerRoute('/chat');
              break;
            case 2:
              _openDrawerRoute('/history');
              break;
            case 3:
              _openDrawerRoute('/models');
              break;
            case 4:
              _openDrawerRoute('/settings');
              break;
            case 5:
              _signOut();
              break;
          }
        },
        children: const [
          Padding(
            padding: EdgeInsets.fromLTRB(28, 16, 16, 6),
            child: Text(
              'Navigate',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: Text('New Chat'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: Text('Chat'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history_toggle_off),
            label: Text('History'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.tune),
            selectedIcon: Icon(Icons.tune),
            label: Text('Model Picker'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: Text('Settings'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.logout),
            selectedIcon: Icon(Icons.logout),
            label: Text('Sign out'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder:
                  (context, index) => ChatBubble(message: _messages[index]),
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
}

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

    if (newTitle == null) return;
    if (newTitle.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Title can't be empty.")));
      return;
    }

    try {
      await supabase.from('chat').update({'ctitle': newTitle}).eq('cid', cid);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title updated')));
      setState(() => _future = _fetchChats());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("History • Inforno")),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final chats = snapshot.data!;
          if (chats.isEmpty)
            return const Center(child: Text("No chats yet — go start one!"));
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
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        '/chat',
                        arguments: ChatPageArgs(existingChatId: cid),
                      ),
                  onLongPress: () => _renameChat(cid: cid, currentTitle: title),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ModelPickerPage extends StatelessWidget {
  const ModelPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Model Picker')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ValueListenableBuilder<Set<String>>(
          valueListenable: selectedModels,
          builder: (context, sel, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select models to respond:',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: -6,
                  children:
                      kAvailableModels.map((m) {
                        final active = sel.contains(m);
                        return FilterChip(
                          label: Text(_prettyModel(m)),
                          selected: active,
                          onSelected: (v) {
                            final s = {...sel};
                            if (v)
                              s.add(m);
                            else
                              s.remove(m);
                            if (s.isEmpty) s.add(m);
                            selectedModels.value = s;
                          },
                        );
                      }).toList(),
                ),
                const Spacer(),
                FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final VoidCallback onToggleTheme;
  const SettingsPage({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          if (user != null)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(user.email ?? 'Signed in'),
              subtitle: Text(user.id),
            )
          else
            const ListTile(
              leading: Icon(Icons.person_off_outlined),
              title: Text('Not signed in'),
            ),
          SwitchListTile(
            secondary: const Icon(Icons.brightness_6_outlined),
            title: const Text('Toggle light/dark'),
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (_) => onToggleTheme(),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (_) => false);
              }
            },
          ),
        ],
      ),
    );
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

String _prettyModel(String id) {
  if (id.contains('deepseek')) return 'DeepSeek R1';
  if (id.contains('gemma')) return 'Gemma 3n e4b';
  if (id.contains('gpt-oss')) return 'GPT-OSS 20B';
  return id;
}
