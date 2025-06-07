import 'package:flutter/material.dart';
import 'package:decoy/services/deep_seek_service.dart';
import 'package:provider/provider.dart';
import 'package:decoy/services/step_provider.dart';
import 'package:decoy/services/user_provider.dart';
import 'package:decoy/services/water_provider.dart';
import 'package:decoy/services/isar_service.dart';
import 'package:decoy/db/chat_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final DeepSeekService _apiService;
  final TextEditingController _controller = TextEditingController();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _apiService = Provider.of<DeepSeekService>(context, listen: false);
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      final history = await IsarService.getChatHistory();
      setState(() {
        // Убрали reversed - сообщения уже отсортированы по убыванию
        _messages = history;
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _isInitialized = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки истории: $e')),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _getUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final stepProvider = Provider.of<StepProvider>(context, listen: false);
    final waterProvider = Provider.of<WaterProvider>(context, listen: false);
    final settings = await IsarService.getSettings();

    return {
      'name': userProvider.user?.name ?? "Пользователь",
      'age': userProvider.user?.age ?? 0,
      'weight': userProvider.user?.weight ?? 0,
      'height': userProvider.user?.height ?? 0,
      'steps': stepProvider.steps,
      'dailyGoal': settings.dailyGoal,
      'water': waterProvider.waterConsumed,
    };
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    final userMessage = ChatMessage(
      isUser: true,
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      // Добавляем новое сообщение в начало списка
      _messages.insert(0, userMessage);
      _controller.clear();
      _isLoading = true;
    });

    await IsarService.saveChatMessage(userMessage);

    try {
      final userData = await _getUserData();
      final response = await _apiService.sendMessage(
        userMessage: text,
        userData: userData,
      );

      final aiMessage = ChatMessage(
        isUser: false,
        content: response,
        timestamp: DateTime.now(),
      );

      setState(() {
        // Добавляем ответ в начало списка
        _messages.insert(0, aiMessage);
        _isLoading = false;
      });

      await IsarService.saveChatMessage(aiMessage);
    } catch (e) {
      final errorMessage = ChatMessage(
        isUser: false,
        content: "Ошибка: ${e.toString()}",
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.insert(0, errorMessage);
        _isLoading = false;
      });
      
      await IsarService.saveChatMessage(errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("DeepSeek Chat")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true, // Важно: переворачиваем список
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatBubble(
                  text: message.content,
                  isUser: message.isUser,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Введите сообщение...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: _isLoading
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser 
              ? Colors.blue[100] 
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text),
      ),
    );
  }
}