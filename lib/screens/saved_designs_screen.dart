import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/services/services.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'design_studio_screen.dart';

class SavedDesignsScreen extends StatefulWidget {
  const SavedDesignsScreen({super.key});

  @override
  State<SavedDesignsScreen> createState() => _SavedDesignsScreenState();
}

class _SavedDesignsScreenState extends State<SavedDesignsScreen> {
  final DesignStorageService _storageService = DesignStorageService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'SAVED DESIGNS',
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
      ),
      body: FutureBuilder<List<SavedDesign>>(
        future: _storageService.getSavedDesigns(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final savedDesigns = snapshot.data ?? [];

          if (savedDesigns.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.design_services_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Saved Designs',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first design and save it!',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DesignStudioScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveSizes.horizontalPadding(context) + 12,
                        vertical: ResponsiveSizes.buttonPaddingVertical(context),
                      ),
                    ),
                    child: const Text('START DESIGNING'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: ResponsiveSizes.pagePadding(context),
            itemCount: savedDesigns.length,
            itemBuilder: (context, index) {
              final design = savedDesigns[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: ResponsiveSizes.contentPadding(context),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.accentBlue,
                    radius: 30,
                    child: Icon(
                      Icons.design_services,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    design.name,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Created: ${_formatDate(design.createdAt)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      if (design.updatedAt != design.createdAt) ...[
                        Text(
                          'Updated: ${_formatDate(design.updatedAt)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      _buildDesignPreview(design.design),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'open':
                          _openDesign(design);
                          break;
                        case 'duplicate':
                          _duplicateDesign(design);
                          break;
                        case 'delete':
                          _deleteDesign(design);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'open',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Open & Edit'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: ListTile(
                          leading: Icon(Icons.copy),
                          title: Text('Duplicate'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _openDesign(design),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DesignStudioScreen()),
          );
        },
        backgroundColor: AppColors.accentBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDesignPreview(CustomDesign design) {
    final previewElements = <String>[];

    if (design.text.isNotEmpty) {
      previewElements.add('Text: "${design.text}"');
    }

    if (design.sticker.isNotEmpty) {
      previewElements.add('Sticker: ${design.sticker}');
    }

    if (design.elements.isNotEmpty) {
      for (final element in design.elements) {
        if (element.type == DesignElementType.text) {
          previewElements.add('Text: "${element.content}"');
        } else if (element.type == DesignElementType.sticker) {
          previewElements.add('Sticker: ${element.content}');
        }
      }
    }

    if (previewElements.isEmpty) {
      previewElements.add('Empty design');
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Design Elements:',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          ...previewElements
              .take(3)
              .map(
                (element) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    element,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          if (previewElements.length > 3)
            Text(
              '...and ${previewElements.length - 3} more',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _openDesign(SavedDesign designInfo) {
    // NOTE: Implement navigation to Design Studio with loaded design
    // This would require modifying DesignStudioScreen to accept initial design
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Design loading functionality coming soon!'),
      ),
    );
  }

  void _duplicateDesign(SavedDesign original) {
    final duplicatedDesign = SavedDesign(
      id: _storageService.generateDesignId(),
      name: '${original.name} (Copy)',
      design: original.design,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _storageService.saveDesign(duplicatedDesign).then((_) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Design "${duplicatedDesign.name}" created! 📁'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _deleteDesign(SavedDesign design) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Design',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${design.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _storageService.deleteDesign(design.id).then((_) {
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Design "${design.name}" deleted! 🗑️'),
                    backgroundColor: Colors.red,
                  ),
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

