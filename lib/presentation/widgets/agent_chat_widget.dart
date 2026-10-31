import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/services/services.dart';
import 'package:designwear/presentation/styles/styles.dart';

import '../../services/ai/ai_usage_service.dart';
import 'ai_allowance_chip.dart';
import 'ai_image_attachment_widget.dart';

class AgentChatWidget extends StatefulWidget {
  final CustomDesign currentDesign;
  final Function(CustomDesign) onDesignUpdate;

  /// Distance from the bottom of the screen for the floating launcher/chat.
  /// Raised on mobile so the button clears the bottom tools row / open panel
  /// instead of overlapping it.
  final double bottomOffset;

  const AgentChatWidget({
    super.key,
    required this.currentDesign,
    required this.onDesignUpdate,
    this.bottomOffset = 20,
  });

  @override
  State<AgentChatWidget> createState() => _AgentChatWidgetState();
}

class _AgentChatWidgetState extends State<AgentChatWidget> {
  final AIAgentService _aiService = AIAgentService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isOpen = false;
  bool _isLoading = false;
  List<File> _selectedImages = [];
  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'agent',
      'text': 'Hi! I\'m DesignBot. Tell me what you want to design! 🎨\n\nYou can also upload reference images for design inspiration!',
      'hasImages': false,
    },
  ];

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty && _selectedImages.isEmpty) return;
    // Nothing left today: the chip says so; don't spend a request the server will refuse.
    if (maybeAiUsage(context, listen: false)?.exhausted ?? false) return;

    final messageText = text.trim().isEmpty ? '[Image attachment]' : text;
    final hasImages = _selectedImages.isNotEmpty;
    final imagesToSend = List<File>.from(_selectedImages);

    _textController.clear();
    _selectedImages.clear();
    setState(() {
      _messages.add({
        'role': 'user',
        'text': messageText,
        'hasImages': hasImages,
        'imageCount': imagesToSend.length,
      });
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _aiService.sendMessage(
        messageText,
        widget.currentDesign,
        imageAttachments: imagesToSend.isNotEmpty ? imagesToSend : null,
      );

      setState(() {
        _isLoading = false;
        _messages.add({
          'role': 'agent',
          'text': response.text,
          'hasImages': false,
        });
      });
      _scrollToBottom();
      if (mounted) maybeAiUsage(context, listen: false)?.refresh();

      if (response.updatedDesign != null) {
        widget.onDesignUpdate(response.updatedDesign!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Design updated by AI! ✨')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add({
          'role': 'agent',
          'text': 'Oops, something went wrong. Please try again.',
          'hasImages': false,
        });
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screenW = MediaQuery.sizeOf(context).width;
    final screenH = MediaQuery.sizeOf(context).height;
    final chatW = (screenW * 0.82).clamp(240.0, 340.0);
    final chatH = (screenH * 0.45).clamp(280.0, 480.0);

    return Positioned(
      bottom: widget.bottomOffset,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Chat Window
          if (_isOpen)
            Container(
              width: chatW,
              height: chatH,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DesignBot AI',
                          style: GoogleFonts.outfit(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: colorScheme.onPrimary,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _isOpen = false),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // Messages
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isUser = msg['role'] == 'user';
                        final hasImages = msg['hasImages'] as bool? ?? false;
                        final imageCount = msg['imageCount'] as int? ?? 0;
                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12).copyWith(
                                bottomLeft: isUser
                                    ? const Radius.circular(12)
                                    : const Radius.circular(0),
                                bottomRight: isUser
                                    ? const Radius.circular(0)
                                    : const Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (hasImages && imageCount > 0)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isUser
                                          ? colorScheme.onPrimary.withValues(
                                              alpha: 0.2,
                                            )
                                          : colorScheme.primary.withValues(
                                              alpha: 0.1,
                                            ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.image,
                                          size: 14,
                                          color: isUser
                                              ? colorScheme.onPrimary
                                              : colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$imageCount image${imageCount > 1 ? 's' : ''} attached',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isUser
                                                ? colorScheme.onPrimary
                                                : colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Text(
                                  msg['text']!,
                                  style: TextStyle(
                                    color: isUser
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurface,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Loading Indicator
                  if (_isLoading)
                    Container(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),

                  // Input
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AiAllowanceChip(),
                        // Image attachment widget
                        AIImageAttachmentWidget(
                          selectedImages: _selectedImages,
                          onImagesSelected: (images) {
                            setState(() {
                              _selectedImages = images;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        // Text input row
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  hintText: _selectedImages.isNotEmpty
                                      ? 'Add a message or send images...'
                                      : (maybeAiUsage(context)?.exhausted ??
                                            false)
                                      ? 'Daily AI limit reached'
                                      : 'Type a message...',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor:
                                      colorScheme.surfaceContainerHighest,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                onSubmitted: _handleSubmitted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor:
                                  (_textController.text.isNotEmpty ||
                                      _selectedImages.isNotEmpty)
                                  ? colorScheme.primary
                                  : colorScheme.primary.withValues(alpha: 0.5),
                              radius: 18,
                              child: IconButton(
                                icon: Icon(
                                  Icons.send,
                                  color: colorScheme.onPrimary,
                                  size: 16,
                                ),
                                onPressed: () =>
                                    _handleSubmitted(_textController.text),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Floating AI assistant launcher — 48x48 solid-accent circle with a
          // sparkle icon, per the Design Studio mockup spec.
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => setState(() => _isOpen = !_isOpen),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.dsAccent,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4D000000), // rgba(0,0,0,0.3)
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: AppColors.dsAccentInk,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
