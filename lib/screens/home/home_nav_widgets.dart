import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'package:designwear/services/services.dart';
import 'package:designwear/screens/cart_screen.dart';
import 'package:designwear/screens/login_screen.dart';
import 'package:designwear/screens/profile_screen.dart';
import 'package:designwear/screens/search_results_screen.dart';
import 'package:designwear/screens/design_studio_screen.dart';

/// Mobile bottom navigation bar.
class HomeBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const HomeBottomNav({super.key, required this.currentIndex, required this.onTap});

  static const _items = [
    {'icon': Icons.home_outlined,        'activeIcon': Icons.home_rounded,          'label': 'Home'},
    {'icon': Icons.search_outlined,      'activeIcon': Icons.search_rounded,        'label': 'Search'},
    {'icon': Icons.brush_outlined,       'activeIcon': Icons.brush_rounded,         'label': 'Design'},
    {'icon': Icons.shopping_bag_outlined,'activeIcon': Icons.shopping_bag_rounded,  'label': 'Cart'},
    {'icon': Icons.person_outline,       'activeIcon': Icons.person_rounded,        'label': 'Profile'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.07))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60.h,
          child: Row(
            children: List.generate(_items.length, (i) {
              final active = currentIndex == i;
              final icon = active ? _items[i]['activeIcon'] as IconData : _items[i]['icon'] as IconData;
              final label = _items[i]['label'] as String;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _handleTap(context, i),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: active ? AppColors.accentBlue.withOpacity(0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(icon, size: 22, color: active ? AppColors.accentBlue : Theme.of(context).colorScheme.onSurface.withOpacity(0.45)),
                    ),
                    const SizedBox(height: 2),
                    Text(label,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? AppColors.accentBlue : Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                        )),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, int i) {
    switch (i) {
      case 1:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchResultsScreen(initialQuery: '')));
        break;
      case 2:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DesignStudioScreen(), settings: const RouteSettings(name: '/design-studio')));
        break;
      case 3:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen(), settings: const RouteSettings(name: '/cart')));
        break;
      case 4:
        final auth = context.read<AuthService>();
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => auth.isLoggedIn ? const ProfileScreen() : const LoginScreen(),
          settings: RouteSettings(name: auth.isLoggedIn ? '/profile' : '/login'),
        ));
        break;
      default:
        onTap(i);
    }
  }
}

/// Sub-nav category tab bar.
class HomeSubNavBar extends StatelessWidget {
  final bool isDesktop;
  final double hp;
  final int selectedIndex;
  final ValueChanged<int> onTabTap;
  final List<String> tabs;

  const HomeSubNavBar({
    super.key,
    required this.isDesktop,
    required this.hp,
    required this.selectedIndex,
    required this.onTabTap,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 42.h,
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.07),
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? hp + 12 : hp),
        itemCount: tabs.length,
        itemBuilder: (context, i) {
          final selected = selectedIndex == i;
          return GestureDetector(
            onTap: () => onTabTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? AppColors.accentBlue : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  tabs[i],
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected
                        ? AppColors.accentBlue
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                    letterSpacing: selected ? 0.1 : 0,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

