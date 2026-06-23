import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'package:designwear/services/services.dart';
import 'package:designwear/screens/cart_screen.dart';
import 'package:designwear/screens/login_screen.dart';
import 'package:designwear/screens/profile_screen.dart';
import 'package:designwear/screens/design_studio_screen.dart';

/// Top sticky app bar matching demo `.top` element.
/// Contains: brand wordmark, search field, Create button, avatar, settings gear.
class HomeAppBar extends StatelessWidget {
  final bool isDesktop;
  final double hp;
  final bool searchFocused;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback onSearch;
  final VoidCallback onOpenSettings;

  const HomeAppBar({
    super.key,
    required this.isDesktop,
    required this.hp,
    required this.searchFocused,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearch,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? AppColors.paperDark : AppColors.paperLight;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;
    final ink = isDark ? AppColors.inkDark : AppColors.inkLight;
    final outerPad = isDesktop ? hp + 12.0 : hp;

    return Container(
      decoration: BoxDecoration(
        color: paper.withOpacity(0.92),
        border: Border(bottom: BorderSide(color: hair)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main top row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: outerPad, vertical: isDesktop ? 14 : 12),
              child: Row(
                children: [
                  // Brand wordmark
                  _buildBrand(ink, isDesktop),
                  const SizedBox(width: 14),

                  // Search bar (expands)
                  Expanded(child: _DemoSearchBar(
                    isDark: isDark,
                    focused: searchFocused,
                    controller: searchController,
                    focusNode: searchFocusNode,
                    onSearch: onSearch,
                    isDesktop: isDesktop,
                  )),

                  const SizedBox(width: 10),

                  // Action buttons
                  _buildActions(context, isDark, ink, isDesktop),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrand(Color ink, bool isDesktop) {
    final fontSize = isDesktop ? 17.0 : 13.0;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'DESIGN',
            style: GoogleFonts.archivo(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.13 * fontSize,
              fontSize: fontSize,
              color: ink,
            ),
          ),
          TextSpan(
            text: 'WEAR',
            style: GoogleFonts.archivo(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.13 * fontSize,
              fontSize: fontSize,
              color: AppColors.marigold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isDark, Color ink, bool isDesktop) {
    return Row(
      children: [
        // Create button
        _CreateButton(isDark: isDark, isMini: !isDesktop),
        const SizedBox(width: 8),

        // Avatar / profile
        Consumer<AuthService>(
          builder: (context, auth, _) => _AvatarButton(
            auth: auth,
            isDark: isDark,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => auth.isLoggedIn ? const ProfileScreen() : const LoginScreen(),
              settings: RouteSettings(name: auth.isLoggedIn ? '/profile' : '/login'),
            )),
          ),
        ),
        const SizedBox(width: 6),

        // Cart
        Consumer<CartService>(
          builder: (context, cart, _) => _IconActionBtn(
            icon: Icons.shopping_bag_outlined,
            badge: cart.itemCount > 0 ? '${cart.itemCount}' : null,
            isDark: isDark,
            ink: ink,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartScreen(), settings: const RouteSettings(name: '/cart')),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Settings gear
        _IconActionBtn(
          icon: Icons.settings_outlined,
          isDark: isDark,
          ink: ink,
          onTap: onOpenSettings,
        ),
      ],
    );
  }
}

// ── Create button ─────────────────────────────────────────────────────────────

class _CreateButton extends StatelessWidget {
  final bool isDark;
  final bool isMini;
  const _CreateButton({required this.isDark, this.isMini = false});

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppColors.inkDark : AppColors.inkLight;
    final paper = isDark ? AppColors.inkLight : AppColors.inkDark;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const DesignStudioScreen(),
          settings: const RouteSettings(name: '/design-studio'),
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMini ? 10 : 14,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: paper, size: 14),
            if (!isMini) ...[
              const SizedBox(width: 5),
              Text(
                'Create',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: paper,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Avatar button ──────────────────────────────────────────────────────────────

class _AvatarButton extends StatelessWidget {
  final AuthService auth;
  final bool isDark;
  final VoidCallback onTap;

  const _AvatarButton({required this.auth, required this.isDark, required this.onTap});

  String _initials() {
    final name = auth.currentUser?.name;
    if (name != null && name.trim().isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      return parts.first[0].toUpperCase();
    }
    final email = auth.currentUser?.email;
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = auth.currentUser?.photoUrl;
    final hasPhoto = auth.isLoggedIn &&
        photoUrl != null &&
        photoUrl.startsWith('http');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: (!hasPhoto && auth.isLoggedIn)
              ? const LinearGradient(
                  colors: [Color(0xFF5a6cff), Color(0xFF9b6cff)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: !auth.isLoggedIn
              ? (isDark ? AppColors.cardDark : AppColors.cardLight)
              : null,
          border: !auth.isLoggedIn
              ? Border.all(
                  color: isDark ? AppColors.hairDark : AppColors.hairLight,
                  width: 1.4,
                )
              : null,
        ),
        alignment: Alignment.center,
        child: hasPhoto
            ? CachedNetworkImage(
                imageUrl: photoUrl,
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _initialsText(),
              )
            : auth.isLoggedIn
                ? _initialsText()
                : Icon(
                    Icons.person_outline,
                    size: 18,
                    color: isDark ? AppColors.inkDark : AppColors.inkLight,
                  ),
      ),
    );
  }

  Widget _initialsText() => Text(
        _initials(),
        style: GoogleFonts.archivo(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: Colors.white,
        ),
      );
}

// ── Icon action button ────────────────────────────────────────────────────────

class _IconActionBtn extends StatelessWidget {
  final IconData icon;
  final String? badge;
  final bool isDark;
  final Color ink;
  final VoidCallback onTap;

  const _IconActionBtn({
    required this.icon,
    required this.isDark,
    required this.ink,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;
    final card = isDark ? AppColors.cardDark : AppColors.cardLight;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: card,
              border: Border.all(color: hair, width: 1.4),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: ink),
          ),
          if (badge != null)
            Positioned(
              right: -3, top: -3,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  gradient: AppColors.neonGradient,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Demo-style search bar ─────────────────────────────────────────────────────

class _DemoSearchBar extends StatelessWidget {
  final bool isDark;
  final bool focused;
  final bool isDesktop;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSearch;

  const _DemoSearchBar({
    required this.isDark,
    required this.focused,
    required this.isDesktop,
    required this.controller,
    required this.focusNode,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final card = isDark ? AppColors.cardDark : AppColors.cardLight;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;
    final ink = isDark ? AppColors.inkDark : AppColors.inkLight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 40,
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: focused ? ink : hair,
          width: focused ? 1.6 : 1.4,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 13, right: 7),
            child: Icon(Icons.search, size: 15, color: AppColors.stone),
          ),
          Expanded(
            child: TextField(
              focusNode: focusNode,
              controller: controller,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ink,
              ),
              textAlignVertical: TextAlignVertical.center,
              textInputAction: TextInputAction.search,
              cursorColor: ink,
              decoration: InputDecoration(
                hintText: isDesktop
                    ? 'Search designs, creators…'
                    : 'Search designs, creators…',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.stone,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.only(bottom: 1),
                isDense: true,
              ),
              onSubmitted: (_) => onSearch(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
