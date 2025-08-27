# Streamshort - Short Video Streaming Platform

A mobile-first Flutter application for streaming short videos with creator monetization features.

## 🚀 Features

### Authentication
- Phone number + OTP login flow
- JWT token management with automatic refresh
- Role-based access control (User, Creator, Admin)

### User Experience
- Browse series by language and category
- Watch episodes with HLS streaming
- Like, rate, and comment on content
- Manage watchlist and preferences

### Creator Tools
- Creator onboarding with KYC verification
- Series and episode management
- Analytics dashboard (views, earnings, watch time)
- Content upload and transcoding workflow
- Add "add episode" for the series created by the creator in user profile for creator
-remove likes and comments 
- add liked videos in the list of quick actions
-  add adulteration filter


### Monetization
- Subscription-based access control
- Razorpay payment integration
- Multiple subscription plans (monthly/yearly)
- Creator payout system

## 🏗 Architecture

- **Clean Architecture** with MVVM pattern
- **State Management**: Riverpod (hooks_riverpod)
- **Navigation**: Go Router
- **API Integration**: Retrofit + Dio with OpenAPI spec
- **Local Storage**: Hive for caching and offline support
- **UI Framework**: Material 3 design system

## 📱 Screenshots

*Screenshots will be added here once the app is running*

## 🛠 Tech Stack

- **Frontend**: Flutter 3.10+
- **Backend**: Go (OpenAPI 3.0.3 spec provided)
- **Database**: Neon (PostgreSQL-compatible)
- **CDN**: Signed HLS URLs for secure playback
- **Payments**: Razorpay integration
- **Storage**: AWS S3 for media uploads

## 📋 Prerequisites

- Flutter SDK 3.10.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code with Flutter extensions
- iOS development tools (for iOS builds)
- Git

## 🚀 Getting Started

### 1. Install Flutter

```bash
# macOS (using Homebrew)
brew install flutter

# Or download from https://flutter.dev/docs/get-started/install

# Verify installation
flutter doctor
```

### 2. Clone the Repository

```bash
git clone <repository-url>
cd streamshort-app
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Generate Code

```bash
# Generate API client and models
flutter packages pub run build_runner build --delete-conflicting-outputs

# Or use the build script
chmod +x build.sh
./build.sh
```

### 5. Run the App

```bash
# For iOS Simulator
flutter run -d ios

# For Android Emulator
flutter run -d android

# For connected device
flutter run
```

## 📁 Project Structure

```
lib/
├── core/                    # Core app configuration
│   ├── api/                # API client and interceptors
│   ├── app.dart           # Main app widget
│   ├── providers.dart     # Core providers
│   ├── router.dart        # Navigation configuration
│   └── theme.dart         # App theme and styling
├── features/               # Feature modules
│   ├── auth/              # Authentication
│   ├── content/           # Series and episodes
│   ├── creator/           # Creator tools
│   ├── engagement/        # Likes, ratings, comments
│   ├── payment/           # Payment processing
│   ├── profile/           # User profile management
│   └── subscription/      # Subscription management
└── main.dart              # App entry point
```

## 🔧 Configuration

### API Configuration

The app is configured to use the Streamshort API. Update the base URL in `lib/core/api/api_client.dart` if needed:

```dart
@RestApi(baseUrl: "https://api.streamshort.com/v1")
```

### Environment Variables

Create a `.env` file in the root directory for environment-specific configuration:

```env
API_BASE_URL=https://api.streamshort.com/v1
RAZORPAY_KEY_ID=your_razorpay_key
RAZORPAY_KEY_SECRET=your_razorpay_secret
```

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run widget tests
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

## 📦 Building for Production

### Android

```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

### iOS

```bash
# Build for iOS
flutter build ios --release

# Archive and distribute through Xcode
```

## 🔐 Security Features

- JWT token authentication
- Automatic token refresh
- Secure API communication
- Signed video URLs for content protection
- Role-based access control

## 📊 Analytics & Monitoring

- Creator analytics dashboard
- User engagement metrics
- Payment tracking
- Content performance insights

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

## 🗺 Roadmap

- [ ] Offline content caching
- [ ] Push notifications
- [ ] Social sharing features
- [ ] Advanced analytics
- [ ] Multi-language support
- [ ] Dark mode improvements
- [ ] Performance optimizations

## 📝 Changelog

### v1.0.0 (Current)
- Initial release
- Core authentication flow
- Series browsing and playback
- Creator onboarding
- Basic payment integration

---

**Built with ❤️ using Flutter**
