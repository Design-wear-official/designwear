import 'dart:convert';
import 'dart:io';

import 'package:designwear/models/models.dart';

import '../../logging/app_log.dart';
import '../../screens/studio/editor/canvas/garment_registry.dart';
import 'ai_service.dart';
import 'layers.dart';

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
    DesignSide side, {
    String style = 'crew',
  }) {
    if (side.isSleeve) return (x: -40, y: -25, w: 90, h: 90);
    // Polo and henley fronts have a placket: the print area starts below it.
    if (side == DesignSide.front && (style == 'polo' || style == 'henley')) {
      return (x: -90, y: 15, w: 180, h: 200);
    }
    return (x: -100, y: -20, w: 200, h: 240);
  }

  /// Pictures for the front, back and sleeves, as editable image layers (empty when nothing could be
  /// drawn), the faces that failed, and the layers job they came from (null on the one-picture-per-face
  /// fallback). A refusal the customer should read (a protected name) comes back in [error].
  Future<
    ({
      List<DesignElement> layers,
      List<String> failed,
      LayerJob? job,
      String? error,
    })
  >
  generateSideLayers(
    String prompt, {
    List<List<int>> references = const [],
    String? garment,
    String? color,
    String? name,
    String style = 'crew',
    List<String> sides = const ['front', 'back', 'left', 'right'],
  }) async {
    const none = (
      layers: <DesignElement>[],
      failed: <String>[],
      job: null,
      error: null,
    );
    try {
      final ai = AiService.instance;
      final stamp = DateTime.now().microsecondsSinceEpoch;
      try {
        final job = await ai.designLayers(
          prompt,
          images: references,
          garment: garment,
          color: color,
          name: name,
          sides: sides,
        );
        final layers = <DesignElement>[];
        final failed = <String>[];
        for (final l in job.layers) {
          final side = l.side == null ? null : DesignSide.fromString(l.side);
          // A print area with no studio side (the neck label) is skipped.
          if (side == null || l.side != side.value) continue;
          if (!l.ok || l.url == null) {
            failed.add(side.value);
            continue;
          }
          try {
            final bytes = await ai.fetchLayerImage(l.url!);
            final p = _placement(side, style: style);
            layers.add(
              DesignElement(
                id: 'ai_${side.value}_$stamp',
                type: DesignElementType.image,
                content: base64Encode(bytes),
                x: p.x,
                y: p.y,
                width: p.w,
                height: p.h,
                side: side,
              ),
            );
          } catch (e) {
            AppLog.instance.info('ai', 'Layer ${l.key} not downloaded: $e');
            failed.add(side.value);
          }
        }
        return (layers: layers, failed: failed, job: job, error: null);
      } on LayersUnsupported {
        // An older API: one picture per face.
      }
      final result = await ai.designSides(prompt, images: references);
      final layers = <DesignElement>[];
      for (final side in DesignSide.values) {
        final data = result.images[side.value];
        if (data == null || data.isEmpty) continue;
        final p = _placement(side, style: style);
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
      return (layers: layers, failed: result.failed, job: null, error: null);
    } on AiFailure catch (e) {
      return (
        layers: const <DesignElement>[],
        failed: const <String>[],
        job: null,
        error: e.message,
      );
    } catch (e) {
      AppLog.instance.info('ai', 'Side artwork unavailable: $e');
      return none;
    }
  }

  Future<AgentResponse> sendMessage(
    String userMessage,
    CustomDesign currentDesign, {
    List<File>? imageAttachments,
    bool trends = false,
    String? garment,
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
        trends: trends,
      );
      // Artwork for every face only when the assistant actually changed the design; the pass the
      // reply carries makes all of it part of the same creation.
      // A picture-only request ("generate a dragon") has an art brief but no design edit: the pictures
      // are then added to the current design.
      final brief = reply.art ?? (reply.design != null ? userMessage : null);
      final art = brief != null && ai.tryOnEnabled
          ? await generateSideLayers(
              brief,
              references: images,
              garment: garment,
              color: _hexColor(currentDesign.baseColor),
              name: currentDesign.name,
              style: _garmentOf(garment).style,
              // A tank top has no sleeves.
              sides: _garmentOf(garment).hasSleeves
                  ? const ['front', 'back', 'left', 'right']
                  : const ['front', 'back'],
            )
          : (
              layers: const <DesignElement>[],
              failed: const <String>[],
              job: null,
              error: null,
            );
      final refusal = art.error == null ? '' : '\n\n${art.error}';
      final preview = art.layers.isEmpty
          ? null
          : (art.layers.where((l) => l.side == DesignSide.front).firstOrNull ??
                    art.layers.first)
                .content;

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
        final missing =
            refusal +
            (art.failed.isEmpty
                ? ''
                : "\n\nI couldn't draw the ${art.failed.join(', ')} this time; you can add art there yourself.");
        return AgentResponse(
          text: reply.text + missing,
          updatedDesign: design,
          trends: reply.trends,
          previewBase64: preview,
          layerJob: art.job,
        );
      }
      if (art.layers.isNotEmpty) {
        final missing =
            refusal +
            (art.failed.isEmpty
                ? ''
                : "\n\nI couldn't draw the ${art.failed.join(', ')} this time.");
        return AgentResponse(
          text: reply.text + missing,
          updatedDesign: currentDesign.copyWith(
            elements: [...art.layers, ...currentDesign.elements],
          ),
          trends: reply.trends,
          previewBase64: preview,
          layerJob: art.job,
        );
      }
      return AgentResponse(text: reply.text + refusal, trends: reply.trends);
    } on AiUnavailable catch (e) {
      return AgentResponse(text: '$e');
    } on AiFailure catch (e) {
      return AgentResponse(text: e.message);
    } catch (e) {
      AppLog.instance.error('ai', 'Design assistant failed', e);
      return AgentResponse(text: 'Something went wrong. Please try again.');
    }
  }

  static Garment _garmentOf(String? id) => GarmentRegistry.byId(id ?? 'tshirt');

  /// '0xFF112233' as the API wants it, or null when it is not one.
  static String? _hexColor(String c) =>
      RegExp(r'^0x[0-9A-Fa-f]{8}$').hasMatch(c) ? c : null;

  void clearHistory() => _history.clear();
}

class AgentResponse {
  final String text;
  final CustomDesign? updatedDesign;

  /// Set when the answer drew on the server's web search for trends.
  final TrendsInfo? trends;

  /// The generated front picture (base64 PNG), shown as a thumbnail in the chat.
  final String? previewBase64;

  /// The print-layers job the pictures came from (mock-up views, contact sheet), when there was one.
  final LayerJob? layerJob;

  AgentResponse({
    required this.text,
    this.updatedDesign,
    this.trends,
    this.previewBase64,
    this.layerJob,
  });
}
