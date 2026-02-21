import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/custom_design.dart';

class AIAgentService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';

  String? get _apiKey => dotenv.env['GEMINI_API_KEY'];

  // Current conversation history
  final List<Map<String, dynamic>> _history = [];

  /// Sends a message to the agent and returns a response.
  /// The response can be a text reply or a structured design update.
  Future<AgentResponse> sendMessage(
    String userMessage,
    CustomDesign currentDesign,
  ) async {
    if (_apiKey == null) {
      return AgentResponse(text: "Error: API Key not found.");
    }

    try {
      // Add user message to history
      _history.add({
        'role': 'user',
        'parts': [
          {'text': userMessage},
        ],
      });

      // Construct the system prompt and context
      final systemPrompt =
          '''
You are "DesignBot", an expert fashion AI assistant for the Designwear app.
Your goal is to help users design t-shirts in the Design Studio.

You have direct control over the t-shirt design. You can change:
- Base Color (hex code, e.g., "0xFF00FF00")
- Text content
- Text color (hex code, e.g., "0xFF000000")
- Text position (X, Y coordinates)
- Font Size

Current State:
${jsonEncode(currentDesign.toJson())}

INSTRUCTIONS:
1. If the user asks to change the design (e.g., "Make it blue", "Add text 'Hello'"), generate a JSON object representing the NEW full design state.
2. If the user just wants to chat, reply with normal text.
3. BE CREATIVE! If the user says "Make a spooky shirt", choose appropriate colors (black/orange) and text (e.g., "Boo!").
4. ALWAYS return a JSON object if you are changing the design. Format: {"design": {...}}
5. COLORS MUST BE IN "0xFFRRGGBB" FORMAT. Do not use "#".
6. If just chatting, return plain text.
7. **IMPORTANT**: You CANNOT generate new images/graphics. You can ONLY change color, text, and text position. If a user asks for a specific graphic (like "sunrise"), politely explain you can only change colors/text, and try to match the VIBE with colors (e.g., "I can't print a sunrise image, but I've set the shirt to a nice sunrise orange and yellow for you!").
''';

      final requestBody = {
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        'contents': _history,
        'generationConfig': {'temperature': 0.7},
      };

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            String textResponse = parts[0]['text'];

            // Add model response to history
            _history.add({
              'role': 'model',
              'parts': [
                {'text': textResponse},
              ],
            });

            // Try to extract JSON from the response using Regex
            // Matches content between ```json and ``` or just {...} if possible
            final jsonRegex = RegExp(
              r'```json\s*(\{.*?\})\s*```',
              dotAll: true,
            );
            final match = jsonRegex.firstMatch(textResponse);

            if (match != null) {
              final jsonString = match.group(1);
              try {
                if (jsonString != null) {
                  final jsonResponse = jsonDecode(jsonString);
                  if (jsonResponse is Map<String, dynamic> &&
                      jsonResponse.containsKey('design')) {
                    final newDesign = CustomDesign.fromJson(
                      jsonResponse['design'],
                    );

                    // Extract the conversational part (everything before the JSON)
                    // so we don't show the raw JSON to the user
                    final splitParts = textResponse.split('```json');
                    final conversationalText = splitParts.isNotEmpty
                        ? splitParts[0].trim()
                        : "I've updated the design for you!";

                    return AgentResponse(
                      text: conversationalText.isNotEmpty
                          ? conversationalText
                          : "I've updated the design for you!",
                      updatedDesign: newDesign,
                    );
                  }
                }
              } catch (e) {
                debugPrint('JSON Parse Error: $e');
              }
            } else {
              // Fallback: try to find just a raw JSON object if code blocks were omitted
              try {
                final start = textResponse.indexOf('{');
                final end = textResponse.lastIndexOf('}');
                if (start != -1 && end != -1 && end > start) {
                  final potentialJson = textResponse.substring(start, end + 1);
                  if (potentialJson.contains('"design"')) {
                    final jsonResponse = jsonDecode(potentialJson);
                    if (jsonResponse is Map<String, dynamic> &&
                        jsonResponse.containsKey('design')) {
                      final newDesign = CustomDesign.fromJson(
                        jsonResponse['design'],
                      );
                      // Determine conversational text
                      final conversationalText = textResponse
                          .substring(0, start)
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
              } catch (e) {
                debugPrint('Fallback JSON Parse Error: $e');
              }
            }

            return AgentResponse(text: textResponse);
          }
        }
      } else {
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
        return AgentResponse(
          text: "API Error (${response.statusCode}): ${response.body}",
        );
      }

      return AgentResponse(
        text: "Sorry, I couldn't understand that (Empty Response).",
      );
    } catch (e, stackTrace) {
      debugPrint('Exception: $e\n$stackTrace');
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
