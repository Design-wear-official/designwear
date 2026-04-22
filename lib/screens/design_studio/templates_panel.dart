import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/design_template_service.dart';
import '../../styles/app_colors.dart';
import 'design_studio_constants.dart';

class TemplatesPanel extends StatelessWidget {
  final DesignTemplateService templateService;
  final Function(DesignTemplate) onApplyTemplate;
  final VoidCallback onClose;

  const TemplatesPanel({
    super.key,
    required this.templateService,
    required this.onApplyTemplate,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      width: DesignStudioConstants.templatesPanelWidth,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TEMPLATES',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<DesignTemplate>>(
                future: templateService.getAllTemplates(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final templates = snapshot.data ?? [];
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.accentBlue,
                            child: Text(
                              template.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            template.name,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            template.description,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          trailing: Chip(
                            label: Text(
                              template.category.toUpperCase(),
                              style: const TextStyle(fontSize: 10),
                            ),
                            backgroundColor: AppColors.gold.withValues(
                              alpha: 0.2,
                            ),
                          ),
                          onTap: () => onApplyTemplate(template),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
