import 'dart:convert';
import 'package:decoy/services/isar_service.dart';
import 'package:http/http.dart' as http;

class DeepSeekService {
  static const String _baseUrl = "https://openrouter.ai/api/v1";
  static const String _model = "deepseek/deepseek-chat-v3-0324:free";
  final String _apiKey;
  final String _systemPrompt;
  static const int _maxMessages = 20;
  final List<Map<String, dynamic>> _conversationHistory = [];

  DeepSeekService({
    required String apiKey,
    String systemPrompt = """Ты — персональный ЗОЖ-ассистент в мобильном приложении VitaTrack. Твоя задача — помогать пользователю вести здоровый образ жизни. Общайся дружелюбно, понятно и мотивирующе.
Что ты умеешь:
- Давать советы по шагам, воде, активности и сну
- Помогать формировать простые ЗОЖ-привычки
- Отвечать на вопросы про физическую активность, режим дня, питание
- Мотивировать, подбадривать и не критиковать

Правила общения:
- Отвечай кратко и по делу (1–3 предложения)
- Не используй сложные термины
- Не давай медицинских рекомендаций и диагнозов
- Не упоминай, что ты ИИ или языковая модель
- Пиши позитивно и поддерживающе
- Если пользователь пишет не по теме ЗОЖ, отвечай что не можешь помочь с такими вопросами.
- Всегда отвечай ТОЛЬКО на русском языке
- Никогда не используй другие языки
- Если пользователь пишет на другом языке, вежливо попроси использовать русский

Примеры использования:
- Мало шагов → "Попробуй короткую прогулку! Маленькие шаги тоже важны 👍"
- Достиг цели → "Супер! Горжусь твоим результатом 💪"
- Не по теме → "Извини, я помогаю только с вопросами ЗОЖ"

Задача — быть доброжелательным и полезным помощником, как заботливый тренер-друг.""",
  })  : _apiKey = apiKey,
        _systemPrompt = systemPrompt;

  Future<String> sendMessage({
    required String userMessage,
    required Map<String, dynamic> userData,
    double temperature = 0.3,
    int maxTokens = 300,
  }) async {
    try {
      final history = await IsarService.getChatHistory();
      _conversationHistory.clear();
      for (var msg in history.reversed.take(_maxMessages)) {
        _conversationHistory.add({
          "role": msg.isUser ? "user" : "assistant",
          "content": msg.content,
        });
      }

      _conversationHistory.add({"role": "user", "content": userMessage});

      final userContext = """
Пользовательские данные:
- Имя: ${userData['name']}
- Возраст: ${userData['age']} лет
- Вес: ${userData['weight']} кг
- Рост: ${userData['height']} см
- Шагов сегодня: ${userData['steps']}/${userData['dailyGoal']}
${userData.containsKey('stepHistory') ? "- История активности:\n${userData['stepHistory']}" : ""}
""";

      final response = await http.post(
        Uri.parse("$_baseUrl/chat/completions"),
        headers: _buildHeaders(),
        body: jsonEncode({
          "model": _model,
          "messages": [
            {"role": "system", "content": _systemPrompt},
            {"role": "system", "content": userContext},
            ..._conversationHistory,
          ],
          "temperature": temperature,
          "max_tokens": maxTokens,
          "stream": false,
        }),
      );

      final aiResponse = _handleResponse(response);
      _conversationHistory.add({"role": "assistant", "content": aiResponse});
      return aiResponse;
    } catch (e) {
      throw Exception("DeepSeek API Error: $e");
    }
  }

  Map<String, String> _buildHeaders() {
    return {
      "Authorization": "Bearer $_apiKey",
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
  }

  String _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        "API Error ${response.statusCode}: ${error['error']?['message'] ?? response.body}",
      );
    }
  }
}