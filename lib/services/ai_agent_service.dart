import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/custom_design.dart';

class AIAgentService {
  String get _baseUrl =>
      dotenv.env['WEB_API_BASE_URL'] ??
      'https://designwear-backend.vishwamai.com/api';

  final List<Map<String, dynamic>> _history = [];

  Future<AgentResponse> sendMessage(
    String userMessage,
    CustomDesign currentDesign,
  ) async {
    try {
      final rawPrompt = await rootBundle.loadString('assets/system_prompt.txt');
      final systemPrompt = rawPrompt.replaceAll(
        '{{CURRENT_STATE}}',
        jsonEncode(currentDesign.toJson()),
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/ai/agent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'systemPrompt': systemPrompt,
          'history': _history,
          'userMessage': userMessage,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Add user message locally now that request succeeded
        _history.add({
          'role': 'user',
          'parts': [
            {'text': userMessage},
          ],
        });

        final data = responseData['data'];
        final candidates = data['candidates'] as List?;

        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;

          if (parts != null && parts.isNotEmpty) {
            String textResponse = parts[0]['text'];

            _history.add({
              'role': 'model',
              'parts': [
                {'text': textResponse},
              ],
            });

            // Extract JSON from response
            final jsonRegex = RegExp(
              r'```json\s*(\{.*?\})\s*```',
              dotAll: true,
            );
            final match = jsonRegex.firstMatch(textResponse);

            if (match != null) {
              final jsonString = match.group(1);
              if (jsonString != null) {
                final jsonResponse = jsonDecode(jsonString);
                if (jsonResponse is Map<String, dynamic> &&
                    jsonResponse.containsKey('design')) {
                  final newDesign = CustomDesign.fromJson(
                    jsonResponse['design'],
                  );
                  final conversationalText = textResponse
                      .split('```json')
                      .first
                      .trim();

                  return AgentResponse(
                    text: conversationalText.isNotEmpty
                        ? conversationalText
                        : "I've updated the design for you!",
                    updatedDesign: newDesign,
                  );
                }
              }
            }
            return AgentResponse(text: textResponse);
          }
        }
      } else {
        return AgentResponse(text: "API Error: ${responseData['error']}");
      }
      return AgentResponse(text: "No response from AI API.");
    } catch (e) {
      debugPrint('Exception: $e');
      return AgentResponse(text: "Error: $e");
    }
  }

  void clearHistory() {
    _history.clear();
  }
}

class AgentResponse {
  final String text;
  final CustomDesign? updatedDesign;

  AgentResponse({required this.text, this.updatedDesign});
}
