import 'package:flutter/material.dart';
import '../../../models/custom_design.dart';
import '../design_studio_utils.dart';

class DesignElementWidget extends StatelessWidget {
  final DesignElement element;

  const DesignElementWidget({super.key, required this.element});

  @override
  Widget build(BuildContext context) {
    switch (element.type) {
      case 'text':
        return _buildTextElement();
      case 'sticker':
        return _buildStickerElement();
      default:
        return Container();
    }
  }

  Widget _buildTextElement() {
    final props = element.properties;
    return Text(
      element.content,
      style: DesignStudioUtils.getTextStyle(
        element.size,
        element.color,
        props['fontFamily'] ?? 'Outfit',
        props['bold'] ?? false,
        props['italic'] ?? false,
        props['shadow'] ?? false,
        props['shadowColor'],
        props['shadowOffset'],
      ),
    );
  }

  Widget _buildStickerElement() {
    return Text(element.content, style: TextStyle(fontSize: element.size));
  }
}
