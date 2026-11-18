import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import '../../../models/design.dart';
import '../../../models/product.dart';
import '../../../services/community/community_service.dart';
import '../../ai/virtual_tryon_screen.dart';
import 'design_detail_screen.dart';

/// The navigator that links opened from outside a screen (the address of the web app) use.
final navigatorKey = GlobalKey<NavigatorState>();

/// Where share links point: SHARE_BASE_URL, else this web app's own address, else the public shop.
String shareBaseUrl() {
  final configured =
      (dotenv.isInitialized ? dotenv.env['SHARE_BASE_URL'] : null) ?? '';
  if (configured.isNotEmpty) return configured.replaceAll(RegExp(r'/+$'), '');
  if (kIsWeb && Uri.base.origin.startsWith('http')) return Uri.base.origin;
  return 'https://designwear-tawny.vercel.app';
}

/// What a link asks for: a design (with its private-link token, if any), shown in detail or tried on.
class ShareRequest {
  const ShareRequest(this.id, {this.token, this.tryOn = false});
  final String id;
  final String? token;
  final bool tryOn;
}

/// The link that opens a design's detail page. [token] is the private link's token (none for a public design).
String detailLink(String id, {String? token}) =>
    '${shareBaseUrl()}/?share=${Uri.encodeQueryComponent(shareCode(id, token))}';

/// The link that opens the virtual try-on with the design on.
String tryOnLink(String id, {String? token}) =>
    '${detailLink(id, token: token)}&view=tryon';

/// A request from a pasted link or code (`...?share=<code>&view=tryon`, or just the code), or null.
ShareRequest? parseShareRequest(String input) {
  final text = input.trim();
  final uri = Uri.tryParse(text);
  final fromQuery = uri?.queryParameters['share'];
  final code = parseShareCode(fromQuery ?? text);
  if (code == null) return null;
  return ShareRequest(
    code.id,
    token: code.token,
    tryOn: uri?.queryParameters['view'] == 'tryon',
  );
}

/// Opens a design from a link: its detail page, or the virtual try-on. Says so when it is not open to you.
Future<void> openShareRequest(
  BuildContext context,
  ShareRequest request,
) async {
  final service = context.read<CommunityService?>();
  final messenger = ScaffoldMessenger.of(context);
  if (service == null) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Opening shared designs needs the DesignWear API.'),
      ),
    );
    return;
  }
  try {
    final design = await service.get(request.id, token: request.token);
    if (!context.mounted) return;
    if (request.tryOn) {
      await openTryOn(context, design);
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DesignDetailScreen(design: design)),
      );
    }
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          "That design isn't available. The link may be off, or it isn't shared with you.",
        ),
      ),
    );
  }
}

/// The virtual try-on with this design on, from the pictures saved with it.
Future<void> openTryOn(BuildContext context, CommunityDesign design) async {
  Uint8List? decode(String? b64) {
    if (b64 == null || b64.isEmpty) return null;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  final front = decode(design.previewImage);
  final back = decode(design.backPreviewImage);
  if (front == null && back == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This design has no picture to try on yet.'),
      ),
    );
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => VirtualTryOnScreen(
        product: Product(
          id: 'design:${design.id}',
          title: design.name,
          price: design.price,
        ),
        customClothingBytes: front ?? back,
        customViews: {'front': ?front, 'back': ?back},
      ),
    ),
  );
}
