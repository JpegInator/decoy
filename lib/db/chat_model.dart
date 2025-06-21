import 'package:isar/isar.dart';

part 'chat_model.g.dart';

@collection
class ChatMessage {
  Id id = Isar.autoIncrement;
  final bool isUser;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.isUser,
    required this.content,
    required this.timestamp,
  });
}