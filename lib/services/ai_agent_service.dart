import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:designwear/models/models.dart';
import 'package:designwear/config/config.dart';

class AIAgentService {
  String get _baseUrl =>
      ConfigLoader.get('WEB_API_BASE_URL') ?? 'http://10.0.2.2:3000/api';

  final List<Map<String, dynamic>> _history = [];

  Future<AgentResponse> sendMessage(
    String userMessage,
    CustomDesign currentDesign, {
    List<File>? imageAttachments,
  }) async {
    try {
      final rawPrompt = await rootBundle.loadString('assets/system_prompt.txt');
      final systemPrompt = rawPrompt.replaceAll(
        '{{CURRENT_STATE}}',
        jsonEncode(currentDesign.toJson()),
      );

      // Prepare image attachments
      List<Map<String, String>>? imageData;
      if (imageAttachments != null && imageAttachments.isNotEmpty) {
        imageData = [];
        for (final image in imageAttachments) {
          try {
            final bytes = await image.readAsBytes();
            final base64Image = base64Encode(bytes);
            imageData.add({'mimeType': 'image/jpeg', 'data': base64Image});
          } catch (e) {
            debugPrint('Error processing image attachment: $e');
          }
        }
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/ai/agent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'systemPrompt': systemPrompt,
          'history': _history,
          'userMessage': userMessage,
          'imageAttachments': imageData,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Add user message locally now that request succeeded
        final List<Map<String, dynamic>> userParts = [
          {'text': userMessage},
        ];

        // Add image attachments to history if provided
        if (imageAttachments != null && imageAttachments.isNotEmpty) {
          for (final image in imageAttachments) {
            try {
              final bytes = await image.readAsBytes();
              final base64Image = base64Encode(bytes);
              userParts.add({
                'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
              });
            } catch (e) {
              debugPrint('Error adding image to history: $e');
            }
          }
        }

        _history.add({'role': 'user', 'parts': userParts});

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
