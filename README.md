# DesignWear 🎨👕

**DesignWear** is an AI-powered custom apparel e-commerce platform built with Flutter. Design unique t-shirts, hoodies, and more using an interactive Design Studio, get instant AI design help from DesignBot, virtually try on clothes before buying, and checkout with a full e-commerce flow.

[![CI Status](https://github.com/kasinadhsarma1/designwear/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/kasinadhsarma1/designwear/actions)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0%2B-blue?logo=dart)

---

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| **Design Studio** | Drag-and-drop canvas with text, stickers, shapes, colors, and templates |
| **DesignBot AI** | Conversational AI assistant (Gemini) — "Make it blue", "Add a spooky logo" |
| **Virtual Try-On** | AI-generated preview of how the design looks on you |
| **E-Commerce Flow** | Cart, coupon codes, checkout, order tracking, Razorpay payments |
| **Auth** | Firebase email/password + Google Sign-In |
| **Themes** | System / Light / Dark mode with persistence |
| **Responsive UI** | Adapts to mobile, tablet, and desktop layouts |
| **Demo Mode** | Fully functional offline demo with sample data |

---

## 🏗️ Architecture

The app follows **Clean Architecture** with a layered structure:

```
lib/
├── config/                    # App-wide configuration
│   ├── app_config.dart        # Env loader (dotenv + dart-define)
│   ├── app_constants.dart     # App-wide constants & keys
│   ├── app_routes.dart        # Named route constants
│   └── demo_config.dart       # Demo mode setup
│
├── models/                    # Pure data models (no Flutter deps)
│   ├── product.dart           # Product with rating, images, discount
│   ├── category.dart          # Category with icon and count
│   ├── cart.dart              # Cart, CartItem, Coupon
│   ├── custom_design.dart     # DesignElement + CustomDesign
│   ├── order.dart             # Order, OrderItem, OrderStatus
│   ├── user.dart              # AppUser with addresses & payment methods
│   ├── address.dart           # Shipping address
│   └── payment_method.dart    # Saved payment method
│
├── domain/
│   └── usecases/              # Business rules (single-responsibility)
│       └── product_use_cases.dart
│
├── data/
│   └── repositories/          # Data access layer
│       ├── product_repository.dart       # Abstract interface
│       └── product_repository_impl.dart  # Sanity/API implementation
│
├── services/                  # Stateful services (ChangeNotifier / singletons)
│   ├── ai_agent_service.dart  # Google Gemini integration
│   ├── auth_service.dart      # Firebase Auth + Google Sign-In
│   ├── cart_service.dart      # Cart state with coupon support
│   ├── order_service.dart     # Order creation
│   ├── sanity_service.dart    # Sanity CMS queries
│   ├── razorpay_service.dart  # Payment processing
│   ├── theme_provider.dart    # Theme state (system/light/dark)
│   ├── design_storage_service.dart
│   ├── design_history_service.dart
│   ├── design_template_service.dart
│   ├── virtual_tryon_service.dart
│   ├── demo_data_service.dart
│   └── api_service.dart
│
├── screens/                   # Full-screen UI
│   ├── home_screen.dart
│   ├── product_detail_screen.dart
│   ├── design_studio_screen.dart
│   ├── cart_screen.dart       # Cart with coupon input
│   ├── checkout_screen.dart
│   ├── profile_screen.dart    # Stats + menu sections
│   ├── settings_screen.dart   # Notifications, language, theme
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── my_orders_screen.dart
│   ├── saved_designs_screen.dart
│   ├── search_results_screen.dart
│   ├── virtual_tryon_screen.dart
│   ├── shipping_addresses_screen.dart
│   └── payment_methods_screen.dart
│
└── presentation/              # Design system
    ├── styles/
    │   ├── app_colors.dart    # Brand + semantic colors
    │   ├── app_theme.dart     # Material 3 light/dark themes
    │   ├── app_text_styles.dart
    │   ├── app_shadows.dart
    │   └── app_dimensions.dart
    ├── widgets/               # Reusable UI components
    └── utils/
        └── responsive_utils.dart
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **UI** | Flutter 3.10+, Material Design 3 |
| **State** | Provider 6.1+ |
| **CMS** | Sanity.io |
| **Auth** | Firebase Auth, Google Sign-In |
| **Payments** | Razorpay |
| **AI** | Google Gemini 2.0 Flash |
| **Notifications** | Firebase Cloud Messaging |
| **Storage** | SharedPreferences, SQLite |
| **HTTP** | `http` package |
| **Fonts** | Google Fonts |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK **3.10+** (`flutter --version`)
- Dart **3.0+**
- Android Studio / VS Code with Flutter extension
- Node.js **18+** (for the backend)

### 1. Clone the Repository

```bash
git clone https://github.com/kasinadhsarma1/designwear.git
cd designwear
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Configure Environment Variables

Copy the example environment file and fill in your keys:

```bash
cp .env.example .env
```

Edit `.env`:

```env
# ── Google Gemini AI ─────────────────────────────────────────────────────────
GEMINI_API_KEY=your_gemini_api_key_here

# ── Sanity CMS ───────────────────────────────────────────────────────────────
SANITY_PROJECT_ID=your_sanity_project_id
SANITY_DATASET=production

# ── Backend API ──────────────────────────────────────────────────────────────
WEB_API_BASE_URL=https://your-backend.com/api
USE_WEB_API=false
API_TIMEOUT_SECONDS=30

# ── Razorpay ─────────────────────────────────────────────────────────────────
RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxx

# ── Feature Flags ────────────────────────────────────────────────────────────
DEBUG_MODE=true
DATA_SOURCE=sanity
ENABLE_FALLBACK=true
```

> **Note:** If no `.env` is present, the app automatically enters **Demo Mode** with sample data. All features are functional without any API keys.

### 4. Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add Android and iOS apps
3. Download `google-services.json` (Android) → `android/app/`
4. Download `GoogleService-Info.plist` (iOS) → `ios/Runner/`
5. Enable **Email/Password** and **Google** sign-in methods in Firebase Authentication

### 5. Run the App

```bash
# Run with internal flavor (development)
flutter run --flavor internal -t lib/main.dart

# Run with external flavor (production)
flutter run --flavor external -t lib/main_external.dart

# Run on web
flutter run -d chrome --dart-define=USE_WEB_API=true --dart-define=WEB_API_BASE_URL=http://localhost:3000/api
```

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

---

## 🔑 API Keys Guide

| Key | Where to get it |
|-----|----------------|
| `GEMINI_API_KEY` | [Google AI Studio](https://aistudio.google.com/app/apikey) |
| `SANITY_PROJECT_ID` | [Sanity Dashboard](https://www.sanity.io/manage) → your project |
| `RAZORPAY_KEY_ID` | [Razorpay Dashboard](https://dashboard.razorpay.com) → Settings → API Keys |
| Firebase config | [Firebase Console](https://console.firebase.google.com) |

---

## 📦 Backend & SDK

This monorepo also contains:

- **`designwear-backend/`** — Next.js + Sanity backend API for products, orders, and Razorpay payments
- **`designwear-sdk/`** — TypeScript SDK for interacting with the DesignWear backend

### Running the Backend

```bash
cd designwear-backend
npm install
cp .env.local.example .env.local   # fill in Sanity + Razorpay keys
npm run dev
```

---

## 🎨 Design System

The app uses a **Material Design 3** design system with custom overrides:

- **Colors**: `lib/presentation/styles/app_colors.dart` — brand palette (deep charcoal, gold, neon purple/blue)
- **Typography**: `lib/presentation/styles/app_text_styles.dart` — Outfit + Poppins fonts
- **Themes**: `lib/presentation/styles/app_theme.dart` — full light/dark theme definitions
- **Spacing**: `lib/presentation/styles/app_dimensions.dart`
- **Responsive**: `lib/presentation/utils/responsive_utils.dart` — mobile/tablet/desktop breakpoints

---

## 🗺️ App Routes

All named routes are in `lib/config/app_routes.dart`:

| Route | Screen |
|-------|--------|
| `/` | Home |
| `/login` | Login |
| `/register` | Register |
| `/product` | Product Detail |
| `/cart` | Cart |
| `/checkout` | Checkout |
| `/design-studio` | Design Studio |
| `/profile` | Profile |
| `/settings` | Settings |
| `/my-orders` | My Orders |
| `/saved-designs` | Saved Designs |
| `/virtual-try-on` | Virtual Try-On |

---

## 🤖 Demo Mode

When no API keys are configured, the app runs in **Demo Mode**:

- All screens are fully functional
- Sample products, categories, and designs are pre-loaded
- The Design Studio, DesignBot, and Virtual Try-On all work with demo responses
- No real payments are processed

To force demo mode, set `DATA_SOURCE=demo` in your `.env`.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Commit your changes: `git commit -m 'feat: add my feature'`
4. Push to the branch: `git push origin feat/my-feature`
5. Open a Pull Request
