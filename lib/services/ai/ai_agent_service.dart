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

  /// Where the picture for each face goes, in the studio's element coordinates (the print area): a large
  /// picture on the front and back, a small emblem on each sleeve.
  static ({double x, double y, double w, double h}) _placement(
    DesignSide side,
  ) => side.isSleeve
      ? (x: -40, y: -25, w: 90, h: 90)
      : (x: -100, y: -20, w: 200, h: 240);

  /// Pictures for the front, back and sleeves, as editable image layers (empty when nothing could be
  /// drawn), plus the faces that failed.
  Future<({List<DesignElement> layers, List<String> failed})>
  generateSideLayers(
    String prompt, {
    List<List<int>> references = const [],
  }) async {
    try {
      final result = await AiService.instance.designSides(
        prompt,
        images: references,
      );
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final layers = <DesignElement>[];
      for (final side in DesignSide.values) {
        final data = result.images[side.value];
        if (data == null || data.isEmpty) continue;
        final p = _placement(side);
        layers.add(
          DesignElement(
            id: 'ai_${side.value}_$stamp',
            type: DesignElementType.image,
            content: data,
            x: p.x,
            y: p.y,
            width: p.w,
            height: p.h,
            side: side,
          ),
        );
      }
      return (layers: layers, failed: result.failed);
    } catch (e) {
      AppLog.instance.info('ai', 'Side artwork unavailable: $e');
      return (layers: const <DesignElement>[], failed: const <String>[]);
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
      final reply = await ai.designAgent(
        message: userMessage,
        design: currentDesign.toJson(),
        history: _history,
        images: images,
      );
      // Artwork for every face only when the assistant actually changed the design; the pass the
      // reply carries makes all of it part of the same creation.
      final art = reply.design != null && ai.tryOnEnabled
          ? await generateSideLayers(userMessage, references: images)
          : (layers: const <DesignElement>[], failed: const <String>[]);

      _history
        ..add((fromUser: true, text: userMessage))
        ..add((fromUser: false, text: reply.text));

      final edit = reply.design;
      if (edit != null) {
        var design = CustomDesign.fromJson(edit);
        // The pictures go underneath the assistant's own text and stickers.
        if (art.layers.isNotEmpty) {
          design = design.copyWith(
            elements: [...art.layers, ...design.elements],
          );
        }
        final missing = art.failed.isEmpty
            ? ''
            : "\n\nI couldn't draw the ${art.failed.join(', ')} this time; you can add art there yourself.";
        return AgentResponse(text: reply.text + missing, updatedDesign: design);
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
