import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/presentation/styles/styles.dart';

/// Weekly challenge banner matching the demo `.challenge` element.
/// Shows a label, title, description, remix count + deadline, and a CTA.
class HomeChallengeBanner extends StatelessWidget {
  final bool isDesktop;
  final double hp;
  final VoidCallback? onRemix;

  const HomeChallengeBanner({
    super.key,
    required this.isDesktop,
    required this.hp,
    this.onRemix,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF202436) : AppColors.inkLight;
    final textColor = isDark ? Colors.white : Colors.white;
    final subtitleColor = isDark ? const Color(0xFFAAB0CF) : const Color(0xFF8E8EA0);

    return Padding(
      padding: EdgeInsets.fromLTRB(hp, 16, hp, 0),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 30 : 18,
          vertical: 18,
        ),
        child: isDesktop
            ? _buildDesktopLayout(context, textColor, subtitleColor)
            : _buildMobileLayout(context, textColor, subtitleColor),
      ),
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, Color textColor, Color subtitleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._contentWidgets(textColor, subtitleColor),
        const SizedBox(height: 14),
        _remixButton(),
      ],
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context, Color textColor, Color subtitleColor) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _contentWidgets(textColor, subtitleColor),
          ),
        ),
        const SizedBox(width: 24),
        _remixButton(),
      ],
    );
  }

  List<Widget> _contentWidgets(Color textColor, Color subtitleColor) => [
        Text(
          "This week's challenge",
          style: GoogleFonts.spaceMonoTextTheme().bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.2,
                color: AppColors.marigold,
              ),
        ),
        const SizedBox(height: 9),
        Text(
          'Monsoon — remix a rain-ready tee',
          style: GoogleFonts.archivo(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            height: 1.1,
            color: textColor,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Fork any design, give it a monsoon twist, and publish before Sunday. '
          'Top remixes get featured.',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            height: 1.4,
            color: subtitleColor,
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 2),
        Text(
          '⑂ 248 remixes · ends in 3 days',
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: subtitleColor,
          ),
        ),
      ];

  Widget _remixButton() {
    return ElevatedButton(
      onPressed: onRemix,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.marigold,
        foregroundColor: AppColors.marigoldInk,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        shadowColor: AppColors.marigold.withOpacity(0.9),
      ).copyWith(
        elevation: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.hovered) ? 8 : 0,
        ),
      ),
      child: Text(
        'Join & remix',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: AppColors.marigoldInk,
        ),
      ),
    );
  }
}
