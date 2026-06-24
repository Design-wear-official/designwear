import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import 'package:designwear/models/models.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'design_canvas.dart';
import 'garment_registry.dart';

/// Builds a self-contained binary glTF (`.glb`) at runtime by combining the
/// bundled garment mesh with a freshly composited design texture, returned as
/// a `data:` URI that `<model-viewer>` can load directly. No JS, no temp files.
///
/// Mesh metadata mirrors `tools/generate_tshirt_glb.py` — keep them in sync.
class Garment3DModel {
  static const int _vertexCount = 1650;
  static const int _indexCount = 9216;
  static const int _oPos = 0;
  static const int _oNor = 19800;
  static const int _oUv = 39600;
  static const int _oInd = 52800;
  static const int _geomLen = 71232;
  static const List<double> _posMin = [-0.425, -0.5, -0.16];
  static const List<double> _posMax = [0.425, 0.5, 0.16];

  static Uint8List? _meshCache;

  static Future<String> buildGlbDataUri(Uint8List atlasPng) async {
    final mesh = _meshCache ??=
        (await rootBundle.load('assets/models/tshirt_mesh.bin'))
            .buffer
            .asUint8List();

    // Buffer = geometry (fixed) followed by the texture PNG.
    final buffer = BytesBuilder()
      ..add(mesh)
      ..add(atlasPng);
    final bufBytes = buffer.toBytes();

    final gltf = <String, dynamic>{
      'asset': {'version': '2.0', 'generator': 'designwear-runtime'},
      'scene': 0,
      'scenes': [
        {'nodes': [0]}
      ],
      'nodes': [
        {'mesh': 0, 'name': 'Garment'}
      ],
      'meshes': [
        {
          'primitives': [
            {
              'attributes': {'POSITION': 0, 'NORMAL': 1, 'TEXCOORD_0': 2},
              'indices': 3,
              'material': 0,
            }
          ],
        }
      ],
      'materials': [
        {
          'name': 'GarmentMat',
          'doubleSided': true,
          'pbrMetallicRoughness': {
            'baseColorTexture': {'index': 0},
            'metallicFactor': 0.0,
            'roughnessFactor': 0.85,
          },
        }
      ],
      'textures': [
        {'source': 0, 'sampler': 0}
      ],
      'images': [
        {'bufferView': 4, 'mimeType': 'image/png'}
      ],
      'samplers': [
        {'magFilter': 9729, 'minFilter': 9987, 'wrapS': 33071, 'wrapT': 33071}
      ],
      'accessors': [
        {
          'bufferView': 0,
          'componentType': 5126,
          'count': _vertexCount,
          'type': 'VEC3',
          'min': _posMin,
          'max': _posMax,
        },
        {'bufferView': 1, 'componentType': 5126, 'count': _vertexCount, 'type': 'VEC3'},
        {'bufferView': 2, 'componentType': 5126, 'count': _vertexCount, 'type': 'VEC2'},
        {'bufferView': 3, 'componentType': 5123, 'count': _indexCount, 'type': 'SCALAR'},
      ],
      'bufferViews': [
        {'buffer': 0, 'byteOffset': _oPos, 'byteLength': 19800, 'target': 34962},
        {'buffer': 0, 'byteOffset': _oNor, 'byteLength': 19800, 'target': 34962},
        {'buffer': 0, 'byteOffset': _oUv, 'byteLength': 13200, 'target': 34962},
        {'buffer': 0, 'byteOffset': _oInd, 'byteLength': 18432, 'target': 34963},
        {'buffer': 0, 'byteOffset': _geomLen, 'byteLength': atlasPng.length},
      ],
      'buffers': [
        {'byteLength': bufBytes.length}
      ],
    };

    final glb = _wrapGlb(utf8.encode(jsonEncode(gltf)), bufBytes);
    return 'data:model/gltf-binary;base64,${base64Encode(glb)}';
  }

  static Uint8List _wrapGlb(List<int> jsonBytes, Uint8List bin) {
    Uint8List pad(List<int> b, int fill) {
      final p = (4 - b.length % 4) % 4;
      return Uint8List.fromList([...b, ...List.filled(p, fill)]);
    }

    final json = pad(jsonBytes, 0x20); // space-padded
    final binP = pad(bin, 0x00);
    final total = 12 + 8 + json.length + 8 + binP.length;
    final out = BytesBuilder();
    final header = ByteData(12)
      ..setUint32(0, 0x46546C67, Endian.little) // 'glTF'
      ..setUint32(4, 2, Endian.little)
      ..setUint32(8, total, Endian.little);
    out.add(header.buffer.asUint8List());
    final jh = ByteData(8)
      ..setUint32(0, json.length, Endian.little)
      ..setUint32(4, 0x4E4F534A, Endian.little); // 'JSON'
    out.add(jh.buffer.asUint8List());
    out.add(json);
    final bh = ByteData(8)
      ..setUint32(0, binP.length, Endian.little)
      ..setUint32(4, 0x004E4942, Endian.little); // 'BIN\0'
    out.add(bh.buffer.asUint8List());
    out.add(binP);
    return out.toBytes();
  }
}

/// Rotatable 3D preview of the current design. Renders clean front/back garment
/// captures, composites them into a texture atlas, bakes a GLB and shows it in
/// `<model-viewer>`. Read-only — editing stays in the 2D studio.
class Garment3DPreviewScreen extends StatefulWidget {
  final CustomDesign design;
  final String garmentType;

  const Garment3DPreviewScreen({
    super.key,
    required this.design,
    required this.garmentType,
  });

  @override
  State<Garment3DPreviewScreen> createState() => _Garment3DPreviewScreenState();
}

class _Garment3DPreviewScreenState extends State<Garment3DPreviewScreen> {
  final GlobalKey _frontKey = GlobalKey();
  final GlobalKey _backKey = GlobalKey();

  String? _modelUri;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    try {
      final garment = GarmentRegistry.byId(widget.garmentType);
      // Make sure garment art is decoded before we rasterise the boundaries.
      for (final asset in [garment.frontAsset, garment.backAsset]) {
        if (asset != null && mounted) {
          await precacheImage(AssetImage(asset), context);
        }
      }
      await WidgetsBinding.instance.endOfFrame;

      final front = await _capture(_frontKey);
      final back = garment.hasAsset(DesignSide.back)
          ? await _capture(_backKey)
          : front; // no back art yet → mirror the front
      final atlas = await _composeAtlas(front, back);
      final uri = await Garment3DModel.buildGlbDataUri(atlas);
      if (mounted) setState(() => _modelUri = uri);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<Uint8List> _capture(GlobalKey key) async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }

  /// Side-by-side [front | back] atlas matching the mesh UV layout.
  Future<Uint8List> _composeAtlas(Uint8List front, Uint8List back) async {
    final fImg = await decodeImageFromList(front);
    final bImg = await decodeImageFromList(back);
    final w = fImg.width, h = fImg.height;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..filterQuality = FilterQuality.high;
    final full = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
    canvas.drawImageRect(fImg, full, full, paint);
    canvas.drawImageRect(
        bImg, Rect.fromLTWH(0, 0, bImg.width.toDouble(), bImg.height.toDouble()),
        Rect.fromLTWH(w.toDouble(), 0, w.toDouble(), h.toDouble()), paint);
    final atlas = await recorder.endRecording().toImage(w * 2, h);
    final bytes = await atlas.toByteData(format: ui.ImageByteFormat.png);
    fImg.dispose();
    bImg.dispose();
    atlas.dispose();
    return bytes!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.view_in_ar, size: 18),
            const SizedBox(width: 8),
            Text('3D Preview',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Offscreen clean garment renders — painted, then covered by the UI.
          _captureSource(_frontKey, DesignSide.front),
          if (GarmentRegistry.byId(widget.garmentType).hasAsset(DesignSide.back))
            _captureSource(_backKey, DesignSide.back),

          Positioned.fill(
            child: Container(
              color: cs.surface,
              child: _buildContent(cs),
            ),
          ),
        ],
      ),
    );
  }

  Widget _captureSource(GlobalKey key, DesignSide side) {
    return Positioned(
      left: 0,
      top: 0,
      child: RepaintBoundary(
        key: key,
        child: DesignCanvas(
          bare: true,
          design: widget.design,
          selectedElementId: null,
          garmentType: widget.garmentType,
          side: side,
          onElementSelected: (_) {},
          onElementPreview: (_) {},
          onElementCommit: () {},
          onElementDelete: (_) {},
          onSideChanged: (_) {},
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme cs) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined,
                  size: 48, color: cs.onSurface.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text('Could not build the 3D preview',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 6),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5))),
            ],
          ),
        ),
      );
    }

    if (_modelUri == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.marigold),
            const SizedBox(height: 16),
            Text('Building 3D model…',
                style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.7))),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ModelViewer(
            key: ValueKey(_modelUri!.length),
            src: _modelUri!,
            alt: '3D garment preview',
            cameraControls: true,
            autoRotate: true,
            disableZoom: false,
            backgroundColor: cs.surface,
            cameraOrbit: '0deg 82deg 2.4m',
            minCameraOrbit: 'auto auto 1.6m',
            maxCameraOrbit: 'auto auto 3.5m',
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Text(
            'Drag to orbit · scroll to zoom · auto-rotates to show front & back',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
        ),
      ],
    );
  }
}
