# G-Fit

A modern, minimalist gym tracking app built with Flutter.

## Features

- 🔐 **Authentication** - Login and signup with mock data
- 💪 **Exercise Library** - 20+ exercises with muscle-specific animations
- 📊 **Workout Tracking** - Track sets, reps, and weights
- 📈 **Statistics** - View workout history and progress
- 🔔 **Notifications** - Stay updated with workout reminders and achievements
- ⚙️ **Settings** - Customize your experience
- 🎨 **Dark Theme** - Modern minimalist design with blue accents

## Demo Credentials

- **Email**: demo@gym.com
- **Password**: password123

## Getting Started

### Prerequisites

- Flutter SDK (>=3.1.0 <4.0.0)
- Dart SDK

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/g-fit.git
cd g-fit
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

## Tech Stack

- **Framework**: Flutter
- **State Management**: Provider
- **Database**: SQLite (sqflite)
- **Charts**: FL Chart
- **Icons**: flutter_launcher_icons

## Project Structure

```
lib/
├── models/          # Data models
├── providers/       # State management
├── screens/         # UI screens
├── services/        # Business logic and data services
├── widgets/         # Reusable widgets
└── main.dart        # App entry point
```

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Windows
```bash
flutter build windows --release
```

### Web
```bash
flutter build web --release
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.

---

Built with ❤️ using Flutter
