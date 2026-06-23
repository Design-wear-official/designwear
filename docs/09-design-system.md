# 09 · Design System

The design system lives in [`lib/presentation/`](../lib/presentation) and is the
single source of truth for colors, typography, themes, spacing, shadows, and
responsive behavior. Import everything via the barrel
[`styles.dart`](../lib/presentation/styles/styles.dart).

```dart
import 'package:designwear/presentation/styles/styles.dart';
```

---

## Colors — `AppColors`

[`app_colors.dart`](../lib/presentation/styles/app_colors.dart). A static,
non-instantiable palette. Highlights:

### Brand
| Token | Hex | Meaning |
|-------|-----|---------|
| `black` / `background` | `#0D0D12` | Deep charcoal (primary) |
| `gold` | `#FFD700` | Vibrant gold (premium) |
| `purple` | `#8A2BE2` | Neon purple accent |
| `accentBlue` | `#00F0FF` | Neon blue accent |

### Neutrals
`surface #1E1E2A`, `backgroundLight #1A1A24`, and a `gray50`…`gray900` ramp
(tuned for dark mode—`gray50` is darkest, `gray900` lightest).

### Semantic
`success`, `error`, `warning`, `info` each with `*Light` / `*Dark` variants.

### Text & borders
`textPrimary`, `textSecondary`, `textDisabled`, `textHint`, `textOnDark`,
`textOnGold`; glass borders `border` (20% white), `borderLight` (10%),
`borderDark` (30%), `borderFocus` (= accentBlue).

### Demo design tokens
Tokens that mirror the demo studio (`docs/demosamples/designwear_studio.html`):
`marigold #E2A33C`, `marigoldInk`, `like #E5654B`, `garmentDefault #27314F`,
`paperLight/paperDark`, `cardLight/cardDark`, `inkLight/inkDark`,
`hairLight/hairDark`, `stone`.

### Gradients & helpers
`heroGradient`, `goldGradient`, `neonGradient`; opacity helpers
`blackOpacity()`, `whiteOpacity()`, `goldOpacity()`, `withOpacity()`.

---

## Typography — `AppTextStyles`

[`app_text_styles.dart`](../lib/presentation/styles/app_text_styles.dart).
All styles are built on **Outfit** via `GoogleFonts.outfit(...)` (Poppins is also
a project font for select surfaces). Scale:

| Group | Styles |
|-------|--------|
| Display | `displayLarge`, `displayMedium`, `displaySmall` |
| Headings | `h1`…`h6` |
| Body | `bodyLarge`, `bodyMedium`, `bodySmall` |
| Controls | `button`, `buttonSmall`, `label`, `labelSmall` |
| Meta | `caption`, `overline` |
| Links/states | `link`, `linkSmall`, `error`, `success` |

> Responsive typography helpers live in
> [`responsive_typography_pattern.dart`](../lib/presentation/patterns/responsive_typography_pattern.dart).

---

## Theme — `AppTheme`

[`app_theme.dart`](../lib/presentation/styles/app_theme.dart). Material 3 themes
consumed in `main.dart`:

```dart
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: themeProvider.themeMode,   // system | light | dark
)
```

- `lightTheme` — `Brightness.light`, `ColorScheme.light(...)`, Outfit text theme.
- `darkTheme` — `Brightness.dark`, `ColorScheme.dark(...)`, Outfit text theme.

`ThemeMode` is owned by [`ThemeProvider`](../lib/services/theme_provider.dart) and
persisted (`AppConstants.prefKeyThemeMode`). See
[Services & State](07-services-and-state.md).

---

## Spacing, shadows, styles

| File | Provides |
|------|----------|
| [`app_dimensions.dart`](../lib/presentation/styles/app_dimensions.dart) | Spacing/radius/size constants |
| [`app_shadows.dart`](../lib/presentation/styles/app_shadows.dart) | Reusable `BoxShadow` presets |
| [`app_styles.dart`](../lib/presentation/styles/app_styles.dart) | Composite decorations / common widget styles |

---

## Responsive system

[`responsive_utils.dart`](../lib/presentation/utils/responsive_utils.dart),
backed by `flutter_screenutil` (design canvas **390×844**). Use the `.w`, `.h`,
`.sp`, `.r` extensions for new code.

### Breakpoints — `ResponsiveBreakpoints`
| Name | Width |
|------|-------|
| `mobile` | 480 |
| `tablet` | 768 |
| `desktop` | 1024 |
| `largeDesktop` | 1400 |
| phone sub-breaks | `phoneSmall 360`, `phoneMedium 390`, `phoneLarge 412` |

### Device classification — `ResponsiveUtils`
- `getDeviceType(ctx)` → `mobile` (<768) / `tablet` (<1024) / `desktop` (≥1024)
- `getPhoneSize(ctx)` → `small`/`medium`/`large`/`xlarge`
- `isMobile/isTablet/isDesktop(ctx)`
- `getResponsiveValue<T>(ctx, mobile:, tablet:, desktop:)`
- `getPhoneValue<T>(...)` for fine-grained phone tuning
- width helpers: `getScreenWidth/Height`, `isWidthGreaterThan/LessThan`

### Common sizes — `ResponsiveSizes`
`contentPadding`, `pagePadding`, `horizontalPadding` (16.w),
`verticalPadding` (12.h), `buttonPaddingVertical` (14.h),
`cardBorderRadius` (12.r), `iconSize` (24.w), `bannerHeight` (160.h),
`carouselHeight` (260.h).

### Global max-width clamp
The `MaterialApp.builder` in `main.dart` centers content and clamps it to
**max 1440px** on very wide screens, so desktop/web don't stretch full-bleed.

---

## Shared widgets

[`lib/presentation/widgets/`](../lib/presentation/widgets) (barrel
[`widgets.dart`](../lib/presentation/widgets/widgets.dart)):

| Widget | Purpose |
|--------|---------|
| `SafeNetworkImage` | Network image with placeholder/error handling (`cached_network_image`) |
| `GarmentTile` | Product/garment card tile for grids & rows |
| `AgentChatWidget` | DesignBot chat UI (used in the Design Studio) |
| `AiImageAttachmentWidget` | Image picker/preview for DesignBot attachments |
| `LineageNode` | Renders a remix-lineage node/chip |

---

## Conventions

- **Never hard-code colors/sizes** in screens—reference `AppColors`,
  `AppTextStyles`, `ResponsiveSizes`.
- Use `.w/.h/.sp/.r` for new sizing rather than raw logical pixels.
- For overflow-safe layouts on small screens, follow
  [Flutter Overflow Pixel Prevention Guide.md](Flutter%20Overflow%20Pixel%20Prevention%20Guide.md).
