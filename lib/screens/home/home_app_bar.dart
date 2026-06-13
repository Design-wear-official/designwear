import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'package:designwear/services/services.dart';
import 'package:provider/provider.dart';
import 'package:designwear/screens/cart_screen.dart';
import 'package:designwear/screens/login_screen.dart';
import 'package:designwear/screens/profile_screen.dart';
import 'home_search_bar.dart';

class HomeAppBar extends StatelessWidget {
  final bool isDesktop;
  final double hp;
  final bool searchFocused;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback onSearch;

  const HomeAppBar({
    super.key,
    required this.isDesktop,
    required this.hp,
    required this.searchFocused,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outerPad = isDesktop ? hp + 12 : hp;

    return SafeArea(
      child: Container(
        height: isDesktop ? 68.h : 62.h,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06),
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: outerPad, vertical: isDesktop ? 10 : 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo mark
              Container(
                width: isDesktop ? 36.r : 32.r,
                height: isDesktop ? 36.r : 32.r,
                decoration: BoxDecoration(
                  gradient: AppColors.neonGradient,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.style, color: Colors.white, size: isDesktop ? 19.r : 17.r),
              ),
              SizedBox(width: isDesktop ? 10 : 7),
              // Brand name — desktop only
              if (isDesktop)
                Text(
                  'Design Wear',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: 0.2,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              SizedBox(width: isDesktop ? 18 : 8),

              // Search bar — flex fill
              Expanded(
                child: HomeSearchBar(
                  isDesktop: isDesktop,
                  isDark: isDark,
                  searchFocused: searchFocused,
                  controller: searchController,
                  focusNode: searchFocusNode,
                  onSearch: onSearch,
                ),
              ),
              const SizedBox(width: 10),

              // Action buttons group
              Consumer<ThemeProvider>(
                builder: (context, tp, _) => _iconBtn(
                  tp.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  () => tp.toggleTheme(!tp.isDarkMode),
                  context,
                ),
              ),
              const SizedBox(width: 6),
              Consumer<AuthService>(
                builder: (context, auth, _) => _iconBtn(
                  auth.isLoggedIn ? Icons.person_rounded : Icons.person_outline_rounded,
                  () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => auth.isLoggedIn ? const ProfileScreen() : const LoginScreen(),
                    settings: RouteSettings(name: auth.isLoggedIn ? '/profile' : '/login'),
                  )),
                  context,
                ),
              ),
              const SizedBox(width: 6),
              Consumer<CartService>(
                builder: (context, cart, _) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _iconBtn(
                      Icons.shopping_bag_outlined,
                      () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen(), settings: const RouteSettings(name: '/cart'))),
                      context,
                    ),
                    if (cart.itemCount > 0)
                      Positioned(
                        right: 1, top: 1,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(gradient: AppColors.neonGradient, shape: BoxShape.circle),
                          child: Text('${cart.itemCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38.r,
        height: 38.r,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20.r, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}

