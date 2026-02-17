import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/responsive_utils.dart';
import '../patterns/responsive_grid_pattern.dart';
import '../patterns/responsive_spacing_pattern.dart';
import '../patterns/responsive_typography_pattern.dart';
import '../patterns/responsive_layout_pattern.dart';

/// Example screen demonstrating all responsive patterns
/// This file shows how to use the responsive patterns module
class ResponsivePatternsExample extends StatelessWidget {
  const ResponsivePatternsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Responsive Patterns Examples')),
      body: SingleChildScrollView(
        padding: ResponsiveSpacing.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Example 1: Device Type Detection
            _buildSection(
              context,
              title: '1. Device Type Detection',
              child: ResponsiveBuilder(
                builder: (context, deviceType) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Device: ${deviceType.name.toUpperCase()}',
                          style: ResponsiveTypography.h4(context),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Width: ${ResponsiveUtils.getScreenWidth(context).toStringAsFixed(0)}px',
                          style: ResponsiveTypography.body(context),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            ResponsiveGap.vertical(context, size: 'lg'),

            // Example 2: Responsive Typography
            _buildSection(
              context,
              title: '2. Responsive Typography',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Display Text',
                    style: ResponsiveTypography.display(context),
                  ),
                  Text('Heading 1', style: ResponsiveTypography.h1(context)),
                  Text('Heading 2', style: ResponsiveTypography.h2(context)),
                  Text('Heading 3', style: ResponsiveTypography.h3(context)),
                  Text('Heading 4', style: ResponsiveTypography.h4(context)),
                  Text(
                    'Body Large',
                    style: ResponsiveTypography.bodyLarge(context),
                  ),
                  Text('Body', style: ResponsiveTypography.body(context)),
                  Text(
                    'Body Small',
                    style: ResponsiveTypography.bodySmall(context),
                  ),
                  Text('Caption', style: ResponsiveTypography.caption(context)),
                  Text('₹999.00', style: ResponsiveTypography.price(context)),
                ],
              ),
            ),

            ResponsiveGap.vertical(context, size: 'lg'),

            // Example 3: Responsive Spacing
            _buildSection(
              context,
              title: '3. Responsive Spacing',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSpacingExample(
                    context,
                    'xs',
                    ResponsiveSpacing.xs(context),
                  ),
                  _buildSpacingExample(
                    context,
                    'sm',
                    ResponsiveSpacing.sm(context),
                  ),
                  _buildSpacingExample(
                    context,
                    'md',
                    ResponsiveSpacing.md(context),
                  ),
                  _buildSpacingExample(
                    context,
                    'lg',
                    ResponsiveSpacing.lg(context),
                  ),
                  _buildSpacingExample(
                    context,
                    'xl',
                    ResponsiveSpacing.xl(context),
                  ),
                  _buildSpacingExample(
                    context,
                    'xxl',
                    ResponsiveSpacing.xxl(context),
                  ),
                ],
              ),
            ),

            ResponsiveGap.vertical(context, size: 'lg'),

            // Example 4: Responsive Grid
            _buildSection(
              context,
              title: '4. Responsive Grid',
              child: ResponsiveGridPattern(
                children: List.generate(
                  8,
                  (index) => Container(
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      border: Border.all(color: Colors.green),
                    ),
                    child: Center(
                      child: Text(
                        'Item ${index + 1}',
                        style: ResponsiveTypography.body(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            ResponsiveGap.vertical(context, size: 'lg'),

            // Example 5: Responsive Layout (Row/Column)
            _buildSection(
              context,
              title: '5. Responsive Row/Column',
              child: ResponsiveRowColumn(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildColorBox(context, Colors.red, 'Box 1'),
                  _buildColorBox(context, Colors.blue, 'Box 2'),
                  _buildColorBox(context, Colors.green, 'Box 3'),
                ],
              ),
            ),

            ResponsiveGap.vertical(context, size: 'lg'),

            // Example 6: Responsive Value
            _buildSection(
              context,
              title: '6. Responsive Value',
              child: ResponsiveValue<int>(
                mobile: 1,
                tablet: 2,
                desktop: 3,
                builder: (context, columns) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'This layout uses $columns column(s)',
                      style: ResponsiveTypography.body(context),
                    ),
                  );
                },
              ),
            ),

            ResponsiveGap.vertical(context, size: 'lg'),

            // Example 7: Code Examples
            _buildSection(
              context,
              title: '7. Usage Examples',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Detection:',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ResponsiveUtils.isMobile(context)',
                      style: GoogleFonts.sourceCodePro(fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Responsive Value:',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ResponsiveUtils.getResponsiveValue<int>(\n  context,\n  mobile: 2,\n  tablet: 3,\n  desktop: 4,\n)',
                      style: GoogleFonts.sourceCodePro(fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Typography:',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ResponsiveTypography.h1(context)',
                      style: GoogleFonts.sourceCodePro(fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Spacing:',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ResponsiveSpacing.md(context)\nResponsiveGap.vertical(context, size: \'lg\')',
                      style: GoogleFonts.sourceCodePro(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            ResponsiveGap.vertical(context, size: 'xxl'),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ResponsiveTypography.h3(
            context,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildSpacingExample(
    BuildContext context,
    String label,
    double spacing,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: ResponsiveTypography.body(
                context,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(width: spacing, height: 20, color: Colors.orange),
          const SizedBox(width: 8),
          Text(
            '${spacing.toStringAsFixed(0)}px',
            style: ResponsiveTypography.bodySmall(context),
          ),
        ],
      ),
    );
  }

  Widget _buildColorBox(BuildContext context, Color color, String label) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          label,
          style: ResponsiveTypography.bodySmall(
            context,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
