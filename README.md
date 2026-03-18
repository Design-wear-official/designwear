# Designwear 🎨👕

**Designwear** is a cutting-edge e-commerce platform that revolutionizes the way users shop for custom apparel. It features an AI-powered Design Studio, Virtual Try-On capabilities, and a seamless checkout experience.

This repository serves as a monorepo containing the main Flutter application, a scalable Next.js backend, and a TypeScript SDK for interacting with the platform.

![CI Status](https://github.com/kasinadhsarma1/designwear/actions/workflows/flutter_ci.yml/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

## 📁 Repository Structure

The project is divided into three main components:

- **`lib/` & `android/` & `ios/`**: The core **Flutter Application** for Android and iOS.
- **`designwear-backend/`**: A **Next.js & Sanity** backend API and CMS for managing the catalog, orders, and payments (Razorpay API).
- **`designwear-sdk/`**: A **TypeScript SDK** for interacting natively with the Designwear backend infrastructure and integrating it into other services.

## ✨ Key Features

- **🎨 Design Studio**: Customize t-shirts with colors, text, graphics, and emojis using the built-in **Sticker Picker**.
- **🤖 Agentic AI Assistant**: Meet **DesignBot**, your personal fashion assistant powered by **Google Gemini 2.0**.
  - *Conversational Design*: Ask the bot to "Design a spooky shirt" or "Make it blue", and watch the design update instantly.
- **👗 Virtual Try-On**: Visualize how clothes look on you before buying using our AI-powered Virtual Try-On feature (Gemini API).
- **🛒 Seamless Shopping**: Complete e-commerce flow with Cart, Checkout, and Order management.
- **🌗 Dark/Bright Mode Toggle**: Switch between system, light, or dark themes with user preference persistence.
- **⚡ High Performance**: Built with Flutter for smooth, native performance on Android and iOS.
- **☁️ Cloud Powered**:
  - **Firebase**: Authentication (Email/Password) and Backend services.
  - **Sanity.io**: Headless CMS for managing dynamic product content.
  - **Razorpay**: Integrated checkout and payment solutions.

## 🛠️ Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend / API**: Next.js (TypeScript), Sanity.io (CMS), Node.js, Razorpay
- **SDK**: TypeScript, npm ecosystem
- **AI & ML**: Google Gemini 3.1 Flash (via API)
- **State Management**: Provider
- **CI/CD**: GitHub Actions

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (v3.10+)
- Dart SDK
- Node.js (v18+) & App Package Manager (`npm` / `yarn`)
- Android Studio / VS Code

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/kasinadhsarma1/designwear.git
   cd designwear
   ```

2. **Install Flutter Dependencies**
   ```bash
   flutter pub get
   ```

3. **Install Backend & SDK Dependencies**
   ```bash
   cd designwear-backend && npm install
   cd ../designwear-sdk && npm install
   ```

### Running the App (Flavors)

The Flutter app supports flavors. To run the app with the `internal` flavor:

```bash
flutter run --flavor internal -t lib/main.dart
```

*(You can also use other flavors as defined in your build setup like `dev` or `prod` if applicable).*

### Environment Setup

Create a `.env` file in the root directory for the app:
```env
# AI Configuration
GEMINI_API_KEY=your_gemini_api_key

# Sanity Configuration
SANITY_PROJECT_ID=your_sanity_project_id
SANITY_DATASET=production
```

For the backend, set up `.env.local` inside `designwear-backend/`:
```env
NEXT_PUBLIC_SANITY_PROJECT_ID=your_project_id
NEXT_PUBLIC_SANITY_DATASET=production
```

## 🏗️ App Architecture

The Flutter app follows a clean architecture pattern:
- `lib/models`: Data models (Product, CustomDesign, Cart).
- `lib/screens`: UI Screens (Home, Design Studio, Checkout).
- `lib/services`: Business logic and API calls (AIAgentService, API Services).
- `lib/widgets`: Reusable UI components (AgentChatWidget, ProductCard).

## 🧪 Testing

Run unit and widget tests for the Flutter application:
```bash
flutter test
```

For the SDK, go to `designwear-sdk/` and run its specific test commands.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
