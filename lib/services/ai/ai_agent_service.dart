import 'dart:convert';
import 'dart:io';

import 'package:designwear/models/models.dart';

import '../../logging/app_log.dart';
import 'ai_service.dart';

/// The Design Studio's assistant. The model, its prompt and its keys live on
/// the DesignWear API; this just sends the current design and applies the edit
/// that comes back.
class AIAgentService {
  final List<({bool fromUser, String text})> _history = [];

  /// A base64 PNG graphic for [prompt], or null if image generation is
  /// unavailable.
  Future<String?> generateDesignImage(String prompt) async {
    try {
      return base64Encode(await AiService.instance.designImage(prompt));
    } catch (e) {
      AppLog.instance.info('ai', 'Design image unavailable: $e');
      return null;
    }
  }

  Future<AgentResponse> sendMessage(
    String userMessage,
    CustomDesign currentDesign, {
    List<File>? imageAttachments,
  }) async {
    final ai = AiService.instance;
    if (!ai.agentEnabled) {
      return AgentResponse(
        text: 'The design assistant is not connected yet. You can still design by hand.',
      );
    }
    try {
      final images = <List<int>>[];
      for (final f in imageAttachments ?? const <File>[]) {
        try {
          images.add(await f.readAsBytes());
        } catch (e) {
          AppLog.instance.warning('ai', 'Could not read an attachment', e);
        }
      }
      // The reply and the graphic are independent, so fetch them together.
      final replyFuture = ai.designAgent(
        message: userMessage,
        design: currentDesign.toJson(),
        history: _history,
        images: images,
      );
      final imageFuture = ai.tryOnEnabled
          ? generateDesignImage(userMessage)
          : Future<String?>.value();
      final reply = await replyFuture;
      final imageBase64 = await imageFuture;

      _history
        ..add((fromUser: true, text: userMessage))
        ..add((fromUser: false, text: reply.text));

      final edit = reply.design;
      if (edit != null) {
        var design = CustomDesign.fromJson(edit);
        if (imageBase64 != null) {
          design = design.copyWith(designImageBase64: imageBase64);
        }
        return AgentResponse(text: reply.text, updatedDesign: design);
      }
      return AgentResponse(text: reply.text);
    } on AiUnavailable catch (e) {
      return AgentResponse(text: '$e');
    } on AiFailure catch (e) {
      return AgentResponse(text: e.message);
    } catch (e) {
      AppLog.instance.error('ai', 'Design assistant failed', e);
      return AgentResponse(text: 'Something went wrong. Please try again.');
    }
  }

  void clearHistory() => _history.clear();
}

class AgentResponse {
  final String text;
  final CustomDesign? updatedDesign;

  AgentResponse({required this.text, this.updatedDesign});
}
