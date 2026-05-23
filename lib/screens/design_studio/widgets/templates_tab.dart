import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/design_template_service.dart';
import '../../../presentation/styles/app_colors.dart';

class TemplatesTab extends StatelessWidget {
  final DesignTemplateService templateService;
  final Function(DesignTemplate) onApplyTemplate;

  const TemplatesTab({
    super.key,
    required this.templateService,
    required this.onApplyTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Templates',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<DesignTemplate>>(
            future: templateService.getAllTemplates(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final templates = (snapshot.data ?? []).take(6).toList();
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return GestureDetector(
                    onTap: () => onApplyTemplate(template),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.style,
                            size: 32,
                            color: AppColors.accentBlue,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            template.name,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

