import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'package:designwear/services/auth/auth_service.dart';
import 'package:designwear/services/shop/cart_service.dart';
import 'package:designwear/screens/cart/cart_screen.dart';
import 'package:designwear/screens/account/auth_screens.dart' show LoginScreen;
import 'package:designwear/screens/account/profile_screen.dart';
import 'package:designwear/screens/studio/editor/design_studio_screen.dart';

/// Top header: brand, a flexible search field, Create, profile and cart.
///
/// Content is capped at 1440px and centred; the bar's background spans the
/// window. Phones (<640px) show a compact "+" instead of the Create pill and
/// drop the search filter button, like the web reference design.
class HomeAppBar extends StatelessWidget {
  final bool isDesktop;
  final double hp;
  final bool searchFocused;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback onSearch;

  /// Words to suggest while typing (product titles, tags, types).
  final List<String> suggestionPool;

  const HomeAppBar({
    super.key,
    required this.isDesktop,
    required this.hp,
    required this.searchFocused,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearch,
    this.suggestionPool = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 640; // phone
    final wide = width >= 1024;

    // Header surface and hairline (dark values from the web reference).
    final bg = isDark ? const Color(0xFF17171D) : AppColors.paperLight;
    final line = isDark ? const Color(0x1FFFFFFF) : AppColors.hairLight;
    final ink = isDark ? AppColors.inkDark : AppColors.inkLight;
    final sidePad = compact ? 16.0 : (wide ? 92.0 : 24.0);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: line)),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440, minHeight: 72),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: sidePad, vertical: 12),
              child: Row(
                children: [
                  _Brand(ink: ink, compact: compact),
                  SizedBox(width: compact ? 10 : 16),
                  Expanded(
                    child: _SearchField(
                      isDark: isDark,
                      compact: compact,
                      controller: searchController,
                      focusNode: searchFocusNode,
                      onSearch: onSearch,
                      suggestionPool: suggestionPool,
                    ),
                  ),
                  SizedBox(width: compact ? 10 : 16),
                  ..._actions(context, isDark, ink, compact),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _actions(
    BuildContext context,
    bool isDark,
    Color ink,
    bool compact,
  ) {
    final gap = SizedBox(width: compact ? 8 : 12);
    return [
      _CreateButton(isDark: isDark, isMini: compact),
      gap,
      Consumer<AuthService>(
        builder: (context, auth, _) => _AvatarButton(
          auth: auth,
          isDark: isDark,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  auth.isSignedIn ? const ProfileScreen() : const LoginScreen(),
              settings: RouteSettings(
                name: auth.isSignedIn ? '/profile' : '/login',
              ),
            ),
          ),
        ),
      ),
      gap,
      Consumer<CartService>(
        builder: (context, cart, _) => _IconActionBtn(
          icon: Icons.shopping_bag_outlined,
          badge: cart.count > 0 ? '${cart.count}' : null,
          isDark: isDark,
          ink: ink,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CartScreen(),
              settings: const RouteSettings(name: '/cart'),
            ),
          ),
        ),
      ),
    ];
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.ink, required this.compact});
  final Color ink;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 13.0 : 17.0;
    final style = GoogleFonts.archivo(
      fontWeight: FontWeight.w900,
      letterSpacing: 0.1 * size,
      fontSize: size,
    );
    return Semantics(
      label: 'DesignWear home',
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'DESIGN',
              style: style.copyWith(color: ink),
            ),
            TextSpan(
              text: 'WEAR',
              style: style.copyWith(color: AppColors.marigold),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create pill ───────────────────────────────────────────────────────────────

class _CreateButton extends StatelessWidget {
  final bool isDark;
  final bool isMini;
  const _CreateButton({required this.isDark, this.isMini = false});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFFF1F0ED) : AppColors.inkLight;
    final fg = isDark ? const Color(0xFF28272B) : Colors.white;
    return Tooltip(
      message: 'Create a design',
      child: Material(
        color: bg,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const DesignStudioScreen(),
              settings: const RouteSettings(name: '/design-studio'),
            ),
          ),
          child: Container(
            height: 40,
            width: isMini ? 40 : null,
            padding: isMini ? null : const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: isMini
                ? Icon(Icons.add, size: 20, color: fg)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 17, color: fg),
                      const SizedBox(width: 6),
                      Text(
                        'Create',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  final AuthService auth;
  final bool isDark;
  final VoidCallback onTap;

  const _AvatarButton({
    required this.auth,
    required this.isDark,
    required this.onTap,
  });

  String _initials() {
    final name = auth.user?.name;
    if (name != null && name.trim().isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return parts.first[0].toUpperCase();
    }
    final email = auth.user?.email;
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    const String? photoUrl = null; // accounts have no profile photo yet
    final hasPhoto =
        auth.isSignedIn && photoUrl != null && photoUrl.startsWith('http');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: (!hasPhoto && auth.isSignedIn)
              ? const LinearGradient(
                  colors: [Color(0xFF5a6cff), Color(0xFF9b6cff)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: !auth.isSignedIn
              ? (isDark ? AppColors.cardDark : AppColors.cardLight)
              : null,
          border: !auth.isSignedIn
              ? Border.all(
                  color: isDark ? const Color(0xFF383842) : AppColors.hairLight,
                )
              : null,
        ),
        alignment: Alignment.center,
        child: hasPhoto
            ? CachedNetworkImage(
                imageUrl: photoUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _initialsText(),
              )
            : auth.isSignedIn
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
    final hair = isDark ? const Color(0xFF383842) : AppColors.hairLight;
    final card = isDark ? AppColors.cardDark : AppColors.cardLight;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: card,
              border: Border.all(color: hair, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: ink),
          ),
          if (badge != null)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  gradient: AppColors.goldGradient,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Demo-style search bar ─────────────────────────────────────────────────────

// ── Search field with suggestions ─────────────────────────────────────────────

/// Rounded search field: a leading icon, a clear button while there is text, a
/// filter button on wider screens, and a "Suggested searches" dropdown while
/// typing. Escape clears; Enter searches.
class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.isDark,
    required this.compact,
    required this.controller,
    required this.focusNode,
    required this.onSearch,
    required this.suggestionPool,
  });

  final bool isDark;
  final bool compact;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSearch;
  final List<String> suggestionPool;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _link = LayerLink();
  final _overlay = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
    widget.focusNode.addListener(_sync);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    widget.focusNode.removeListener(_sync);
    super.dispose();
  }

  List<String> get _matches {
    final q = widget.controller.text.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final seen = <String>{};
    return [
      for (final s in widget.suggestionPool)
        if (s.toLowerCase().contains(q) && seen.add(s.toLowerCase())) s,
    ].take(5).toList();
  }

  bool get _open => widget.focusNode.hasFocus && _matches.isNotEmpty;

  void _sync() {
    if (!mounted) return;
    setState(() {});
    if (_open && !_overlay.isShowing) {
      _overlay.show();
    } else if (!_open && _overlay.isShowing) {
      _overlay.hide();
    }
  }

  void _pick(String value) {
    widget.controller.text = value;
    widget.controller.selection = TextSelection.collapsed(offset: value.length);
    widget.focusNode.unfocus();
    widget.onSearch();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDark;
    final focused = widget.focusNode.hasFocus;
    final fill = dark ? const Color(0xFF202027) : AppColors.cardLight;
    final border = focused
        ? (dark
              ? const Color(0xFF777783)
              : AppColors.inkLight.withValues(alpha: 0.55))
        : (dark ? const Color(0xFF373743) : AppColors.hairLight);
    final icon = dark ? const Color(0xFF878791) : AppColors.stone;
    final hint = dark ? const Color(0xFF777780) : AppColors.stone;
    final text = dark ? Colors.white : AppColors.inkLight;
    final hasText = widget.controller.text.isNotEmpty;

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlay,
        overlayChildBuilder: (context) => CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.bottomLeft,
          offset: const Offset(0, 8),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: (_link.leaderSize?.width ?? 320),
              // Taps inside count as inside the field, so the field keeps focus
              // until the suggestion has been chosen.
              child: TextFieldTapRegion(
                child: _Suggestions(dark: dark, items: _matches, onPick: _pick),
              ),
            ),
          ),
        ),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () {
              widget.controller.clear();
              widget.focusNode.unfocus();
            },
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 40,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: border),
              boxShadow: focused
                  ? [
                      BoxShadow(
                        color: (dark ? Colors.white : Colors.black).withValues(
                          alpha: 0.10,
                        ),
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 4),
                  child: Icon(Icons.search, size: 16, color: icon),
                ),
                Expanded(
                  child: TextField(
                    focusNode: widget.focusNode,
                    controller: widget.controller,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.2,
                      color: text,
                    ),
                    textAlignVertical: TextAlignVertical.center,
                    strutStyle: const StrutStyle(
                      fontSize: 13,
                      height: 1.2,
                      forceStrutHeight: true,
                    ),
                    textInputAction: TextInputAction.search,
                    cursorColor: AppColors.marigold,
                    onSubmitted: (_) => widget.onSearch(),
                    decoration: InputDecoration(
                      hintText: 'Search designs, creators...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.2,
                        color: hint,
                      ),
                      // Collapsed: no built-in vertical padding, so the text is
                      // centred in the bar and lines up with the icons.
                      isCollapsed: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
                if (hasText)
                  _FieldIconButton(
                    tooltip: 'Clear search',
                    icon: Icons.close_rounded,
                    color: icon,
                    onTap: widget.controller.clear,
                  ),
                if (!widget.compact)
                  _FieldIconButton(
                    tooltip: 'Filter search',
                    icon: Icons.tune_rounded,
                    color: icon,
                    onTap: widget.onSearch,
                  ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldIconButton extends StatelessWidget {
  const _FieldIconButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    icon: Icon(icon, size: 16, color: color),
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints.tightFor(width: 30, height: 30),
    padding: EdgeInsets.zero,
    splashRadius: 16,
  );
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({
    required this.dark,
    required this.items,
    required this.onPick,
  });
  final bool dark;
  final List<String> items;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final panel = dark ? const Color(0xFF222229) : AppColors.cardLight;
    final line = dark ? const Color(0x1AFFFFFF) : AppColors.hairLight;
    final label = dark ? const Color(0xFF85858E) : AppColors.stone;
    final textColor = dark ? const Color(0xFFD8D7DC) : AppColors.inkLight;
    return Material(
      color: panel,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Text(
                'SUGGESTED SEARCHES',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.6,
                  color: label,
                ),
              ),
            ),
            for (final item in items)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                hoverColor: (dark ? Colors.white : Colors.black).withValues(
                  alpha: 0.08,
                ),
                onTap: () => onPick(item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 16, color: label),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
