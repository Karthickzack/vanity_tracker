# ✨ Vanity Tracker

> **"Stop using expired skincare and buying duplicates of products you already own."**

Vanity Tracker is a premium mobile app for iOS and Android built with Flutter and Firebase. It tracks skincare and cosmetics expiration dates based on **Period After Opening (PAO)**, schedules smart local notifications, logs finished empties with repurchase ratings, and provides detailed budget and cost-per-day analytics.

---

## 📱 Features

### 🌸 Increment 1: Core Freshness & Expiry Loop
- **Firebase Authentication**: Email and password registration, secure login, plus a 1-click Demo Mode.
- **Barcode Scanner with Open Beauty Facts API**: Instant barcode scanning using `mobile_scanner` that queries the Open Beauty Facts `v2` REST API to auto-fill brand, product name, volume, and category.
- **Smart Category & PAO Defaults**: Pre-configured with standard cosmetics expiration lifespans:
  - *Mascara*: 3 months
  - *Eye Cream*: 6 months
  - *Serum*: 12 months
  - *Sunscreen*: 12 months
  - *Moisturizer*: 12 months
  - *Cleanser*: 12 months
  - *Foundation*: 12 months
  - *Lipstick*: 24 months
- **One-Tap "Opened Today"**: Sets the opened date to today and computes `expiry_date = opened_date + category pao_months`.
- **Dynamic Color-Coded Vanity Dashboard**:
  - 🟢 **Green (Fresh)**: > 30 days remaining
  - 🟡 **Amber (Expiring Soon)**: 0 to 30 days remaining
  - 🔴 **Red (Expired)**: < 0 days (PAO overdue)
  - ⚪ **Unopened**: Clear indicator for sealed backups
- **Local Device Notifications**: Uses `flutter_local_notifications` to schedule alerts 30 days before expiration and on the expiry day (cancelled automatically when finished).

### ♻️ Increment 2: Empties & Budget Analytics
- **Empties Graveyard**: Mark items as finished with a *"Would you repurchase this?"* prompt (Yes 👍 / No 👎).
- **Cost-Per-Day Calculation**: Computes `price ÷ days between opened_date and finished_date`.
- **Vanity Budget Dashboard**:
  - Total Current Vanity Valuation ($)
  - Average Cost Per Day across finished empties
  - Repurchase Satisfaction Rate (%)
  - Cost-per-day leaderboard

---

## 🛠️ Architecture & Tech Stack

- **Frontend**: Flutter (Dart) with Material 3 & custom luxury skincare design system
- **State Management**: Provider (`ChangeNotifierProvider`)
- **Backend / Database**: Cloud Firestore
- **Authentication**: Firebase Auth (with automatic offline demo fallback)
- **Barcode Scanning**: `mobile_scanner`
- **Product Database**: Open Beauty Facts API (`https://world.openbeautyfacts.org/api/v2/product/{barcode}.json`)
- **Local Notifications**: `flutter_local_notifications` & `timezone`

---

## 🚀 Getting Started

### 1. Prerequisites
- Flutter SDK `>=3.10.0`
- Android Studio / Xcode for mobile emulators or connected devices

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run Automated Tests
```bash
flutter test
```

### 4. Run the App
```bash
flutter run
```

---

## 🔥 Firebase Setup (Optional for Live Cloud Mode)

The app includes an **in-memory fallback repository**, allowing instant evaluation without cloud setup. To connect your live Firebase project:

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
2. Enable **Authentication** (Email/Password provider).
3. Enable **Cloud Firestore** and deploy the following collections:
   - `users`
   - `products`
   - `vanity_items`
   - `categories`
   - `notifications`
4. Run `flutterfire configure` to generate `lib/firebase_options.dart`, or add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
