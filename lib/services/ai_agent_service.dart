import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:designwear/models/models.dart';
import 'package:designwear/config/config.dart';

class AIAgentService {
  String get _baseUrl =>
      ConfigLoader.get('WEB_API_BASE_URL') ??
      'https://designwear-backend.vishwamai.com/api';

  final List<Map<String, dynamic>> _history = [];

  /// Generates a graphic design image for the given theme.
  /// Returns base64-encoded PNG string, or null on failure.
  Future<String?> generateDesignImage(String prompt) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/ai/generate-design'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'prompt': prompt}),
          )
          .timeout(const Duration(seconds: 45));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['imageData'] as String?;
      }
      debugPrint('Image gen error: ${data['error']}');
      return null;
    } catch (e) {
      debugPrint('generateDesignImage: $e');
      return null;
    }
  }

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

      List<Map<String, String>>? imageData;
      if (imageAttachments != null && imageAttachments.isNotEmpty) {
        imageData = [];
        for (final image in imageAttachments) {
          try {
            final bytes = await image.readAsBytes();
            imageData.add({
              'mimeType': 'image/jpeg',
              'data': base64Encode(bytes),
            });
          } catch (e) {
            debugPrint('Error encoding attachment: $e');
          }
        }
      }

      // Fire both requests in parallel — agent for design JSON, image gen for graphic
      final agentFuture = http.post(
        Uri.parse('$_baseUrl/ai/agent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'systemPrompt': systemPrompt,
          'history': _history,
          'userMessage': userMessage,
          'imageAttachments': imageData,
        }),
      );
      final imageFuture = generateDesignImage(userMessage);

      final agentHttpResponse = await agentFuture;
      final imageBase64 = await imageFuture;

      final responseData = jsonDecode(agentHttpResponse.body);

      if (agentHttpResponse.statusCode == 200 &&
          responseData['success'] == true) {
        final List<Map<String, dynamic>> userParts = [
          {'text': userMessage},
        ];
        if (imageAttachments != null && imageAttachments.isNotEmpty) {
          for (final image in imageAttachments) {
            try {
              final bytes = await image.readAsBytes();
              userParts.add({
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Encode(bytes),
                },
              });
            } catch (e) {
              debugPrint('Error adding attachment to history: $e');
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
            final String textResponse = parts[0]['text'];
            _history.add({
              'role': 'model',
              'parts': [
                {'text': textResponse},
              ],
            });

            // Greedy match captures full nested JSON object
            final jsonRegex = RegExp(
              r'```json\s*(\{.*\})\s*```',
              dotAll: true,
            );
            final match = jsonRegex.firstMatch(textResponse);

            if (match != null) {
              final jsonString = match.group(1);
              if (jsonString != null) {
                final jsonResponse = jsonDecode(jsonString);
                if (jsonResponse is Map<String, dynamic> &&
                    jsonResponse.containsKey('design')) {
                  var newDesign = CustomDesign.fromJson(
                    jsonResponse['design'],
                  );
                  // Attach AI-generated graphic when available
                  if (imageBase64 != null) {
                    newDesign = newDesign.copyWith(
                      designImageBase64: imageBase64,
                    );
                  }
                  final conversationalText =
                      textResponse.split('```json').first.trim();
                  return AgentResponse(
                    text: conversationalText.isNotEmpty
                        ? conversationalText
                        : 'Design created! ✨',
                    updatedDesign: newDesign,
                  );
                }
              }
            }
            return AgentResponse(text: textResponse);
          }
        }
      } else {
        return AgentResponse(text: 'API Error: ${responseData['error']}');
      }
      return AgentResponse(text: 'No response from AI.');
    } catch (e) {
      debugPrint('sendMessage exception: $e');
      return AgentResponse(text: 'Error: $e');
    }
  }

  void clearHistory() => _history.clear();
}

class AgentResponse {
  final String text;
  final CustomDesign? updatedDesign;

  AgentResponse({required this.text, this.updatedDesign});
}
