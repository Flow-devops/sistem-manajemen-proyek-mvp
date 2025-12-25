// lib/services/daily_quest_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class DailyQuest {
  final String id;
  final String userId;
  final String questText;
  final DateTime createdAt;

  DailyQuest({
    required this.id,
    required this.userId,
    required this.questText,
    required this.createdAt,
  });

  factory DailyQuest.fromJson(Map<String, dynamic> j) {
    return DailyQuest(
      id: j['id'].toString(),
      userId: j['user_id'].toString(),
      questText: j['quest_text'] ?? '',
      createdAt: DateTime.parse(j['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class DailyQuestService {
  // ganti ke alamat server Anda (emulator: 10.0.2.2)
  final String baseUrl;

  DailyQuestService({required this.baseUrl});

  // Fetch quest for user (backend will return existing if <24h)
  Future<DailyQuest?> fetchOrCreateForUser(String userId) async {
    final uri = Uri.parse('$baseUrl/api/daily-quest?user_id=$userId');
    final resp = await http.get(uri);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final map = jsonDecode(resp.body) as Map<String, dynamic>;
      final q = map['quest'] ?? map['data'] ?? map;
      return DailyQuest.fromJson(q as Map<String, dynamic>);
    }
    throw Exception('Failed to fetch daily quest: ${resp.body}');
  }

  // Force create (optional)
  Future<DailyQuest?> createForUser(String userId) async {
    final uri = Uri.parse('$baseUrl/api/daily-quest');
    final resp = await http.post(uri, body: jsonEncode({'user_id': userId}), headers: {'Content-Type': 'application/json'});
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final map = jsonDecode(resp.body) as Map<String, dynamic>;
      final q = map['quest'] ?? map['data'] ?? map;
      return DailyQuest.fromJson(q as Map<String, dynamic>);
    }
    throw Exception('Failed to create daily quest: ${resp.body}');
  }
}
