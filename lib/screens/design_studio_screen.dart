import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/custom_design.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../styles/app_colors.dart';

import '../widgets/agent_chat_widget.dart';

class DesignStudioScreen extends StatefulWidget {
  const DesignStudioScreen({super.key});

  @override
  State<DesignStudioScreen> createState() => _DesignStudioScreenState();
}

class _DesignStudioScreenState extends State<DesignStudioScreen> {
  CustomDesign _design = CustomDesign();

  // Dummy product for the base t-shirt
  final Product _baseProduct = Product(
    id: "custom-tee-001",
    title: "Men's Custom T-Shirt",
    slug: "mens-custom-tee",
    description: "A unique T-Shirt designed by you.",
    price: 29.99,
    imageUrl:
        "https://raw.githubusercontent.com/yemon/react-native-tshirt-design/master/assets/images/tshirt_white.png",
    categoryId: "custom",
    stockStatus: 'inStock',
  );

  final List<Color> _tShirtColors = [
    Colors.white,
    Colors.black,
    Colors.grey,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'DESIGN STUDIO',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              context.read<CartService>().addToCart(
                _baseProduct,
                customDesign: _design,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Design added to cart! 🎨')),
              );
              Navigator.pop(context);
            },
            child: Text(
              'ADD TO CART',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: AppColors.accentBlue,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Canvas Area
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.surface,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Base T-Shirt Image (Using a color filter for tinting)
                        ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Color(int.parse(_design.baseColor)),
                            BlendMode.modulate,
                          ),
                          child: Image.asset(
                            'assets/images/tshirt_white.png',
                            width: 300,
                            fit: BoxFit.contain,
                          ),
                        ),

                        // Design Overlay (Text)
                        if (_design.text.isNotEmpty)
                          Positioned(
                            left: 100 + _design.textX,
                            top: 100 + _design.textY,
                            child: Draggable(
                              feedback: Material(
                                color: Colors.transparent,
                                child: _buildTextOverlay(),
                              ),
                              childWhenDragging: Container(),
                              onDragEnd: (details) {},
                              child: _buildTextOverlay(),
                            ),
                          ),

                        // Design Overlay (Sticker)
                        if (_design.sticker.isNotEmpty)
                          Positioned(
                            left: 100 + _design.stickerX,
                            top: 150 + _design.stickerY,
                            child: Draggable(
                              feedback: Material(
                                color: Colors.transparent,
                                child: _buildStickerOverlay(),
                              ),
                              childWhenDragging: Container(),
                              onDragEnd: (details) {},
                              child: _buildStickerOverlay(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tools Panel
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(0, -5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CUSTOMIZE',
                          style: GoogleFonts.outfit(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Color Selector
                        SizedBox(
                          height: 50,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _tShirtColors.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final color = _tShirtColors[index];
                              final isSelected =
                                  Color(int.parse(_design.baseColor)).value ==
                                  color.value;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _design = _design.copyWith(
                                      baseColor:
                                          '0x${color.value.toRadixString(16).toUpperCase()}',
                                    );
                                  });
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.gold
                                          : Colors.grey.shade300,
                                      width: isSelected ? 3 : 1,
                                    ),
                                    boxShadow: [
                                      if (isSelected)
                                        BoxShadow(
                                          color: color.withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showTextEditor,
                                icon: Icon(
                                  Icons.text_fields,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                label: Text(
                                  'ADD TEXT',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.2),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showStickerPicker,
                                icon: Icon(
                                  Icons.emoji_emotions_outlined,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                label: Text(
                                  'STICKER',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.2),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // AI Agent Chat Widget
          AgentChatWidget(
            currentDesign: _design,
            onDesignUpdate: (newDesign) {
              setState(() {
                _design = newDesign;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextOverlay() {
    return Text(
      _design.text,
      style: GoogleFonts.outfit(
        fontSize: _design.fontSize,
        fontWeight: FontWeight.bold,
        color: Color(int.parse(_design.textColor)),
      ),
    );
  }

  void _showTextEditor() {
    final textController = TextEditingController(text: _design.text);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Text',
              style: GoogleFonts.outfit(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Enter your text',
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _design = _design.copyWith(text: textController.text);
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'APPLY',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStickerOverlay() {
    return Text(
      _design.sticker,
      style: TextStyle(fontSize: _design.stickerSize),
    );
  }

  void _showStickerPicker() {
    final List<String> stickers = [
      '⭐',
      '🔥',
      '❤️',
      '🎸',
      '👑',
      '😎',
      '💀',
      '🍕',
      '🎉',
      '⚽',
      '🚀',
      '🌈',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Sticker',
              style: GoogleFonts.outfit(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: stickers.map((sticker) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _design = _design.copyWith(sticker: sticker);
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(sticker, style: const TextStyle(fontSize: 32)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
