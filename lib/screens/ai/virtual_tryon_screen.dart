import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/product.dart';
import '../../presentation/widgets/ai_allowance_chip.dart';
import '../../services/ai/ai_service.dart';
import '../../services/ai/ai_usage_service.dart';
import '../catalog/product_image.dart';

class VirtualTryOnScreen extends StatefulWidget {
  const VirtualTryOnScreen({
    super.key,
    required this.product,
    this.customClothingBytes,
  });
  final Product product;

  /// The customer's own design as an image, used instead of the product photo.
  final Uint8List? customClothingBytes;

  @override
  State<VirtualTryOnScreen> createState() => _VirtualTryOnScreenState();
}

class _VirtualTryOnScreenState extends State<VirtualTryOnScreen> {
  Uint8List? _photo;
  Uint8List? _result;
  String? _message;
  bool _busy = false;

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _photo = bytes;
        _result = null;
        _message = null;
      });
    } catch (_) {
      setState(
        () => _message = "Couldn't open the photo. Check app permissions.",
      );
    }
  }

  Future<void> _run() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final custom = widget.customClothingBytes;
      final out = await AiService.instance.tryOn(
        personPhoto: _photo!,
        productId: custom == null ? widget.product.id : null,
        garmentImage: custom,
        title: widget.product.title,
      );
      _result = Uint8List.fromList(out);
    } on AiUnavailable catch (e) {
      _message = '$e';
    } on AiFailure catch (e) {
      _message = e.message;
    } catch (_) {
      _message = 'Try-on failed. Please try again.';
    }
    if (mounted) {
      setState(() => _busy = false);
      maybeAiUsage(context, listen: false)?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Virtual try-on')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: SizedBox(
            width: 56,
            height: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ProductImage(url: widget.product.displayImageUrl),
            ),
          ),
          title: Text(widget.product.title),
        ),
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: _result != null
                ? Image.memory(_result!, fit: BoxFit.cover)
                : _photo != null
                ? Image.memory(_photo!, fit: BoxFit.cover)
                : const Center(
                    child: Text('Add a full-length photo of yourself'),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pick(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Camera'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Center(child: AiAllowanceChip()),
        FilledButton(
          onPressed:
              _photo == null ||
                  _busy ||
                  (maybeAiUsage(context)?.exhausted ?? false)
              ? null
              : _run,
          child: Text(_busy ? 'Working…' : 'Try it on'),
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_message!, textAlign: TextAlign.center),
          ),
      ],
    ),
  );
}
