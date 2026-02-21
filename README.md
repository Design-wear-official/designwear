# Designwear 🎨👕

**Designwear** is a cutting-edge Flutter e-commerce application that revolutionizes the way users shop for custom apparel. It features an AI-powered Design Studio, Virtual Try-On capabilities, and a seamless checkout experience.

![CI Status](https://github.com/kasinadhsarma1/designwear/actions/workflows/flutter_ci.yml/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

## ✨ Key Features

-   **🎨 Design Studio**: Customize t-shirts with colors, text, graphics, and emojis using the built-in **Sticker Picker**.
-   **🤖 Agentic AI Assistant**: Meet **DesignBot**, your personal fashion assistant powered by **Google Gemini 2.0**.
    -   *Conversational Design*: Ask the bot to "Design a spooky shirt" or "Make it blue", and watch the design update instantly.
-   **👗 Virtual Try-On**: Visualize how clothes look on you before buying using our AI-powered Virtual Try-On feature (Gemini API).
-   **🛒 Seamless Shopping**: Complete e-commerce flow with Cart, Checkout, and Order management.
-   **🌗 Dark/Bright Mode Toggle**: Switch between system, light, or dark themes with user preference persistence.
-   **⚡ High Performance**: Built with Flutter for smooth, native performance on Android and iOS.
-   **☁️ Cloud Powered**:
    -   **Firebase**: Authentication (Email/Password, Phone) and Backend services.
    -   **Sanity.io**: Headless CMS for managing dynamic product content.
    -   **GoKwik**: Integrated checkout solution.

## 🛠️ Tech Stack

-   **Frontend**: Flutter (Dart)
-   **AI & ML**: Google Gemini 2.0 Flash (via API)
-   **Backend**: Firebase (Auth, Firestore), Sanity.io (CMS)
-   **State Management**: Provider
-   **CI/CD**: GitHub Actions

## 🚀 Getting Started

### Prerequisites
-   Flutter SDK (v3.10+)
-   Dart SDK
-   Android Studio / VS Code
-   Sanity CLI (for backend management)

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/kasinadhsarma1/designwear.git
    cd designwear
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Environment Setup**
    Create a `.env` file in the root directory:
    ```env
    # AI Configuration
    GEMINI_API_KEY=your_gemini_api_key

    # Sanity Configuration
    SANITY_PROJECT_ID=your_sanity_project_id
    SANITY_DATASET=production

    # GoKwik Configuration
    GOKWIK_MERCHANT_ID=your_merchant_id
    GOKWIK_API_KEY=your_api_key
    ```
    *Note: You need to obtain API keys from Google AI Studio and Sanity.io.*
    
    5.  **Sanity Studio Setup**
    Navigate to the `studio` directory and create a `.env` file:
    ```bash
    cd studio
    ```
    Create `studio/.env`:
    ```env
    SANITY_STUDIO_PROJECT_ID=your_sanity_project_id
    SANITY_STUDIO_DATASET=production
    ```

4.  **Run the App**
    ```bash
    flutter run
    ```

## 🏗️ Architecture

The app follows a clean architecture pattern:
-   `lib/models`: Data models (Product, CustomDesign, Cart).
-   `lib/screens`: UI Screens (Home, Design Studio, Checkout).
-   `lib/services`: Business logic and API calls (AIAgentService, VirtualTryOnService, SanityService).
-   `lib/widgets`: Reusable UI components (AgentChatWidget, ProductCard).

## 🧪 Testing

Run unit and widget tests:
```bash
flutter test
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
