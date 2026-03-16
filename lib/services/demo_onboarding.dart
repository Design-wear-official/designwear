import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../styles/app_colors.dart';
import '../config/demo_config.dart';

/// Demo onboarding and tutorial service
class DemoOnboarding {
  static final DemoOnboarding _instance = DemoOnboarding._internal();
  factory DemoOnboarding() => _instance;
  DemoOnboarding._internal();

  /// Show app introduction dialog for first-time users
  static Future<void> showAppIntroduction(BuildContext context) async {
    if (!DemoConfig().isDemoMode) return;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AppIntroductionDialog(),
    );
  }

  /// Show feature spotlight for specific features
  static void showFeatureSpotlight(
    BuildContext context,
    String feature,
    String title,
    String description, {
    Widget? icon,
    VoidCallback? onNext,
  }) {
    if (!DemoConfig().isDemoMode) return;

    showDialog(
      context: context,
      builder: (context) => FeatureSpotlightDialog(
        title: title,
        description: description,
        icon: icon,
        onNext: onNext,
      ),
    );
  }

  /// Show quick tutorial overlay
  static void showQuickTutorial(
    BuildContext context,
    List<TutorialStep> steps,
  ) {
    if (!DemoConfig().isDemoMode || steps.isEmpty) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            TutorialOverlay(steps: steps),
      ),
    );
  }
}

/// App introduction dialog
class AppIntroductionDialog extends StatefulWidget {
  const AppIntroductionDialog({super.key});

  @override
  State<AppIntroductionDialog> createState() => _AppIntroductionDialogState();
}

class _AppIntroductionDialogState extends State<AppIntroductionDialog> {
  int _currentPage = 0;
  late PageController _pageController;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': '👋',
      'title': 'Welcome to DesignWear!',
      'description': 'Create custom apparel with our intuitive design studio and explore premium products.',
    },
    {
      'icon': '🎨',
      'title': 'Design Studio',
      'description': 'Use our powerful design tools to create unique t-shirts with text, stickers, and templates.',
    },
    {
      'icon': '🛍️',
      'title': 'Shop & Customize',
      'description': 'Browse our collection, customize products, and add them to your cart seamlessly.',
    },
    {
      'icon': '🎭',
      'title': 'Demo Mode Active',
      'description': 'You\'re exploring with sample data. All features are available to try!',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentPage
                        ? AppColors.accentBlue
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        page['icon'],
                        style: const TextStyle(fontSize: 60),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        page['title'],
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        page['description'],
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),

            // Navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  TextButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Text(
                      'Previous',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    ),
                  )
                else
                  const SizedBox.shrink(),

                if (_currentPage < _pages.length - 1)
                  ElevatedButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(
                      'Next',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      DemoConfig().trackDemoAction('onboarding_completed');
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(
                      'Get Started!',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Feature spotlight dialog
class FeatureSpotlightDialog extends StatelessWidget {
  final String title;
  final String description;
  final Widget? icon;
  final VoidCallback? onNext;

  const FeatureSpotlightDialog({
    super.key,
    required this.title,
    required this.description,
    this.icon,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(height: 16),
            ],
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Skip',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onNext?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    'Try It',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tutorial step model
class TutorialStep {
  final String title;
  final String description;
  final Offset position;
  final Size highlightSize;

  const TutorialStep({
    required this.title,
    required this.description,
    required this.position,
    required this.highlightSize,
  });
}

/// Tutorial overlay widget
class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;

  const TutorialOverlay({super.key, required this.steps});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _currentStepIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentStep = widget.steps[_currentStepIndex];

    return Material(
      color: Colors.black54,
      child: Stack(
        children: [
          // Highlight area
          Positioned(
            left: currentStep.position.dx,
            top: currentStep.position.dy,
            child: Container(
              width: currentStep.highlightSize.width,
              height: currentStep.highlightSize.height,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accentBlue, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // Tutorial content
          Positioned(
            left: 20,
            right: 20,
            bottom: 80,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentStep.title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentStep.description,
                    style: GoogleFonts.outfit(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Skip'),
                      ),
                      Row(
                        children: [
                          if (_currentStepIndex > 0)
                            TextButton(
                              onPressed: () => setState(() => _currentStepIndex--),
                              child: const Text('Previous'),
                            ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (_currentStepIndex < widget.steps.length - 1) {
                                setState(() => _currentStepIndex++);
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            child: Text(
                              _currentStepIndex < widget.steps.length - 1
                                  ? 'Next'
                                  : 'Done',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}