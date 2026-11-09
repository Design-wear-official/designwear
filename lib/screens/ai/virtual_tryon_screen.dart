import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/product.dart';
import '../../presentation/widgets/ai_allowance_chip.dart';
import '../../services/ai/ai_service.dart';
import '../../services/ai/ai_usage_service.dart';
import '../../services/app/image_export.dart';
import '../catalog/product_image.dart';

class VirtualTryOnScreen extends StatefulWidget {
  const VirtualTryOnScreen({
    super.key,
    required this.product,
    this.customClothingBytes,
    this.initialPhoto,
    this.initialResult,
  });
  final Product product;

  /// A photo to start with (tests); normally the customer picks one.
  @visibleForTesting
  final Uint8List? initialPhoto;

  /// A finished try-on picture to start with (tests).
  @visibleForTesting
  final Uint8List? initialResult;

  /// The customer's own design as an image, used instead of the product photo.
  final Uint8List? customClothingBytes;

  @override
  State<VirtualTryOnScreen> createState() => _VirtualTryOnScreenState();
}

class _VirtualTryOnScreenState extends State<VirtualTryOnScreen> {
  late Uint8List? _photo = widget.initialPhoto;
  late Uint8List? _result = widget.initialResult;
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

  String get _fileName {
    final slug = widget.product.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return 'designwear-tryon${slug.isEmpty ? '' : '-$slug'}.png';
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _download() async {
    final out = _result;
    if (out == null) return;
    final ok = await ImageExport.download(out, _fileName);
    _toast(ok ? 'Picture saved' : "Couldn't save the picture");
  }

  Future<void> _share() async {
    final out = _result;
    if (out == null) return;
    final ok = await ImageExport.share(
      out,
      _fileName,
      text: 'Me in ${widget.product.title} — made with DesignWear',
    );
    if (!ok) _toast('Sharing is not available here. Use Download instead.');
  }

  /// The photo (or the result) on a soft card. The whole person is shown (`contain`), never cropped to a
  /// face, and the card is capped in size so it stays a sensible picture on a wide desktop window.
  Widget _preview(BuildContext context, {required double maxHeight}) {
    final cs = Theme.of(context).colorScheme;
    final picture = _result ?? _photo;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (picture != null)
                  Image.memory(
                    picture,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                  )
                else
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Add a full-length photo of yourself',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                if (_busy)
                  ColoredBox(
                    color: Colors.black45,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(
                            'Trying it on…',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _productTile() => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: SizedBox(
      width: 56,
      height: 56,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ProductImage(url: widget.product.displayImageUrl),
      ),
    ),
    title: Text(widget.product.title),
  );

  /// Gallery / Camera, the allowance, the Try it on button and any message.
  List<Widget> _controls(BuildContext context) => [
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
    if (_result != null) ...[
      Row(
        children: [
          Expanded(
            child: FilledButton.tonalIcon(
              key: const ValueKey('tryon-download'),
              onPressed: _download,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.tonalIcon(
              key: const ValueKey('tryon-share'),
              onPressed: _share,
              icon: const Icon(Icons.ios_share),
              label: const Text('Share'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
    ],
    const Center(child: AiAllowanceChip()),
    FilledButton(
      onPressed:
          _photo == null || _busy || (maybeAiUsage(context)?.exhausted ?? false)
          ? null
          : _run,
      child: Text(_busy ? 'Working…' : 'Try it on'),
    ),
    if (_message != null)
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(_message!, textAlign: TextAlign.center),
      ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Virtual try-on')),
    body: LayoutBuilder(
      builder: (context, box) {
        // Wide window: the picture on the left, the controls beside it, all on one screen.
        if (box.maxWidth >= 860) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _preview(context, maxHeight: box.maxHeight - 48),
                    ),
                    const SizedBox(width: 32),
                    SizedBox(
                      width: 340,
                      child: ListView(
                        children: [
                          _productTile(),
                          const SizedBox(height: 12),
                          ..._controls(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        // Phone / narrow: one column; the picture is never taller than most of the screen so the
        // buttons stay reachable.
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _productTile(),
            _preview(context, maxHeight: box.maxHeight * 0.68),
            const SizedBox(height: 12),
            ..._controls(context),
          ],
        );
      },
    ),
  );
}
