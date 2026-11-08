# Amar Hisab — Flutter starter

A bilingual (Bangla/English) personal finance app starter for Bangladesh.

## Included in this first working prototype
- Android and iOS Flutter project structure
- Bangla/English toggle
- Guest-style use (no account or OTP)
- Add income and expense entries
- Balance, income and expense totals
- Recent transaction list
- Local persistence using SharedPreferences

## Run it
1. Install Flutter SDK and Android Studio (for Android) or Xcode (for iOS).
2. Unzip this project.
3. Open a terminal in the project folder.
4. Run `flutter pub get`
5. Run `flutter run`

For iOS builds, a Mac with Xcode is required.

## Important limitations
- This is an initial prototype, not a production-ready financial product.
- Data is stored locally on the device. Uninstalling the app or losing the device can lose data; add encrypted export/backup before public release.
- Statistics, savings goals, DPS/FDR calculators, AI advice, cloud sync, PIN/biometric lock, and app-store publishing are not implemented yet.
- Do not enter bank passwords, card details, or other highly sensitive credentials.
