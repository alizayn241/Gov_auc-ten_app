# Gov Auction App

[![Flutter](https://img.shields.io/badge/Flutter-3.4+-02569B?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.4+-0175C2?logo=dart)](https://dart.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive Flutter mobile application for governmental auctions, built with MVVM architecture and modern state management.

## Features

- **Auction Browsing**: Browse and search through government auctions
- **Real-time Updates**: Live auction data via Supabase backend
- **Map Integration**: Location-based auction discovery with Flutter Map
- **Document Handling**: PDF generation and printing capabilities
- **Secure Storage**: Encrypted local storage for sensitive data
- **Multi-language Support**: Internationalization with Flutter Localizations
- **Charts & Analytics**: Visual data representation with FL Chart
- **Image Upload**: Auction item photo management

## Tech Stack

- **Framework**: Flutter (Dart)
- **Architecture**: MVVM (Model-View-ViewModel)
- **State Management**: Riverpod
- **Backend**: Supabase (Authentication, Database, Real-time)
- **Routing**: Go Router
- **Maps**: Flutter Map with LatLong2
- **Charts**: FL Chart
- **PDF/Printing**: PDF and Printing packages
- **Storage**: Flutter Secure Storage, Shared Preferences
- **Networking**: Dio with Pretty Dio Logger
- **Serialization**: Freezed, JSON Serializable
- **Animations**: Lottie

## Prerequisites

- Flutter SDK (>=3.4.0)
- Dart SDK (>=3.4.0)
- Android Studio / Xcode (for mobile development)
- Supabase account and project setup

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/gov-auction-app.git
   cd gov-auction-app
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code (Freezed, JSON Serializable)**
   ```bash
   flutter pub run build_runner build
   ```

4. **Set up Supabase**
   - Create a Supabase project
   - Copy your Supabase URL and anon key
   - Configure environment variables (see Environment Setup below)

5. **Run the app**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android
- Ensure Android SDK is installed
- Set up Android emulator or connect physical device
- Run: `flutter run` (Android will be selected automatically)

#### iOS
- macOS with Xcode installed required
- Run: `flutter run` (iOS simulator will be selected)

#### Web
- Run: `flutter run -d chrome`

## Environment Setup

Create a `.env` file in the root directory with your Supabase configuration:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

**Security Note**: Never commit `.env` files to version control. Add `.env` to your `.gitignore`.

## Project Structure

```
lib/
├── core/                    # Core utilities and configurations
├── features/               # Feature-based modules
│   ├── auctions/          # Auction-related screens and logic
│   ├── auth/             # Authentication features
│   └── ...               # Other features
├── main.dart              # App entry point
└── ...

assets/
├── images/               # Static images
│   ├── logos/           # App logos
│   ├── splash/          # Splash screen assets
│   ├── illustrations/   # UI illustrations
│   ├── auctions/        # Auction-related images
│   └── icons/           # App icons
└── lottie/              # Lottie animations

supabase/
└── notifications_setup.sql  # Database setup scripts

android/                  # Android platform code
ios/                     # iOS platform code
web/                     # Web platform code
```

## Usage

### Basic Usage

1. **Launch the app** on your device/emulator
2. **Sign up/Login** using your credentials
3. **Browse auctions** from the main dashboard
4. **View auction details** by tapping on auction items
5. **Participate in auctions** through the bidding interface

### Development

- **Hot Reload**: Press `r` in terminal while app is running
- **Hot Restart**: Press `R` in terminal
- **Debug Mode**: Use Flutter DevTools for debugging

### Testing

Run tests:
```bash
flutter test
```

Run tests with coverage:
```bash
flutter test --coverage
```

## API Documentation

The app integrates with Supabase for backend services. Key endpoints include:

- **Authentication**: User login/signup via Supabase Auth
- **Auctions**: CRUD operations on auction data
- **Bids**: Real-time bidding system
- **Notifications**: Push notifications setup

Refer to [Supabase Documentation](https://supabase.com/docs) for detailed API references.

## Contributing

We welcome contributions! Please follow these guidelines:

### Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes
4. Run tests: `flutter test`
5. Run analysis: `flutter analyze`
6. Format code: `flutter format .`
7. Commit changes: `git commit -m 'Add some feature'`
8. Push to branch: `git push origin feature/your-feature-name`
9. Open a Pull Request

### Code Style

- Follow Flutter's [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter format` for consistent formatting
- Run `flutter analyze` to check for issues
- Write tests for new features

### Commit Convention

Use conventional commits:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation
- `style:` for formatting
- `refactor:` for code restructuring
- `test:` for testing
- `chore:` for maintenance

## Testing

The project uses Flutter's built-in testing framework with Mocktail for mocking.

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/
```

### Test Structure

```
test/
├── unit/              # Unit tests
├── widget/           # Widget tests
└── integration/      # Integration tests
```

## CI/CD

This project uses GitHub Actions for continuous integration.

### Workflows

- **Build**: Runs on every push/PR
- **Test**: Executes test suite
- **Analyze**: Code analysis and linting
- **Deploy**: Automated deployment to stores (future)

## Deployment

### Android

1. Build APK: `flutter build apk --release`
2. Build App Bundle: `flutter build appbundle --release`
3. Upload to Google Play Store

### iOS

1. Build IPA: `flutter build ios --release`
2. Archive in Xcode
3. Upload to App Store Connect

### Web

1. Build web: `flutter build web --release`
2. Deploy to hosting service (Firebase, Vercel, etc.)

## Security

- **Data Encryption**: Sensitive data stored using Flutter Secure Storage
- **API Security**: Supabase handles authentication and authorization
- **Code Security**: Regular dependency updates and security audits
- **Environment Variables**: Never expose secrets in code

## Performance

- **State Management**: Efficient Riverpod implementation
- **Image Optimization**: Proper asset management
- **Network Efficiency**: Dio with logging and caching
- **Memory Management**: Proper disposal of resources

## Troubleshooting

### Common Issues

1. **Build Failures**
   - Run `flutter clean` then `flutter pub get`
   - Check Flutter version compatibility

2. **Supabase Connection Issues**
   - Verify `.env` file configuration
   - Check Supabase project status

3. **Platform-Specific Errors**
   - Android: Check Android SDK and emulator setup
   - iOS: Ensure Xcode and iOS Simulator are configured

### Debug Tools

- **Flutter DevTools**: `flutter pub global run devtools`
- **Supabase Dashboard**: Monitor database and auth
- **Android Studio Profiler**: Performance analysis

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Flutter](https://flutter.dev/) - UI toolkit
- [Supabase](https://supabase.com/) - Backend as a Service
- [Riverpod](https://riverpod.dev/) - State management
- [Go Router](https://gorouter.dev/) - Routing

## Support

For support, email support@govauctionapp.com or join our [Discord community](https://discord.gg/govauctionapp).

## Roadmap

- [ ] Offline mode support
- [ ] Advanced search filters
- [ ] Push notifications
- [ ] Multi-language support expansion
- [ ] Auction analytics dashboard

---

Made with ❤️ using Flutter
