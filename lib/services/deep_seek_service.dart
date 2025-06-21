import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:decoy/services/isar_service.dart';
import 'package:decoy/services/step_provider.dart';
import 'package:decoy/services/water_provider.dart';
import 'package:decoy/services/user_provider.dart';

class DeepSeekService {
  static const String _baseUrl = "https://openrouter.ai/api/v1";
  static const String _model = "deepseek/deepseek-chat-v3-0324:free";
  final String apiKey;
  static const int _maxMessages = 20;
  final List<Map<String, dynamic>> _conversationHistory = [];

  DeepSeekService({
    required this.apiKey,
  });

  // Метод для получения системного промпта с данными пользователя
  String _buildSystemPrompt(BuildContext context, {Map<String, dynamic>? userData}) {
    String name = "Пользователь";
    int age = 0;
    int weight = 0;
    int height = 0;
    int steps = 0;
    int waterConsumed = 0;

    if (userData != null) {
      name = userData['name'] ?? name;
      age = userData['age'] ?? age;
      weight = userData['weight'] ?? weight;
      height = userData['height'] ?? height;
      steps = userData['steps'] ?? steps;
      waterConsumed = userData['water'] ?? waterConsumed;
    } else {
      // Получаем провайдеры данных
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final stepProvider = Provider.of<StepProvider>(context, listen: false);
      final waterProvider = Provider.of<WaterProvider>(context, listen: false);

      name = userProvider.user?.name ?? name;
      age = userProvider.user?.age ?? age;
      weight = userProvider.user?.weight ?? weight;
      height = userProvider.user?.height ?? height;
      steps = stepProvider.steps;
      waterConsumed = waterProvider.waterConsumed;
    }

    return """Ты — персональный ЗОЖ-ассистент в мобильном приложении VitaTrack. Твоя задача — помогать пользователю вести здоровый образ жизни. Общайся дружелюбно, понятно и мотивирующе.
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
- Не используй специальной символики по типу ** чтобы текст стал жирным, или любого другого форматирования текста. Ответ должен состоять только из букв, знаков препинания и смайликов, никакого форматирования.

Примеры использования:
- Мало шагов → "Попробуй короткую прогулку! Маленькие шаги тоже важны 👍"
- Достиг цели → "Супер! Горжусь твоим результатом 💪"
- Не по теме → "Извини, я помогаю только с вопросами ЗОЖ"

Задача — быть доброжелательным и полезным помощником, как заботливый тренер-друг.

Текущие данные пользователя:
- Имя: $name
- Возраст: $age лет
- Вес: $weight кг
- Рост: $height см
- Шагов сегодня: $steps
- Выпито воды: $waterConsumed мл
""";
  }

  Future<String> sendMessage({
    required BuildContext context,
    required String userMessage,
    Map<String, dynamic>? userData,
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

      _conversationHistory.add({
        "role": "user",
        "content": userMessage
      });

      final systemPrompt = _buildSystemPrompt(context, userData: userData);
      debugPrint("Системный промпт:\n$systemPrompt");

      final response = await http.post(
        Uri.parse("$_baseUrl/chat/completions"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "model": _model,
          "messages": [
            {"role": "system", "content": systemPrompt},
            ..._conversationHistory,
          ],
          "temperature": temperature,
          "max_tokens": maxTokens,
          "stream": false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'];
        
        _conversationHistory.add({
          "role": "assistant",
          "content": aiResponse
        });
        
        return aiResponse;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          "API Error ${response.statusCode}: ${error['error']?['message'] ?? response.body}",
        );
      }
    } catch (e) {
      debugPrint("DeepSeek API Error: $e");
      return "Извините, произошла ошибка. Пожалуйста, попробуйте снова.";
    }
  }
}