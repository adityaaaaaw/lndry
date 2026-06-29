# LNDRY — Production Flutter Project Foundation

This repository contains the production-grade clean architecture project foundation for **LNDRY**, a premium laundry marketplace application built with Flutter.

---

## 🛠 Technology Stack

- **Flutter version**: Latest Stable
- **Design System**: Material 3
- **State Management**: Riverpod (`flutter_riverpod` + `riverpod_annotation`)
- **Navigation**: GoRouter (`go_router` with StatefulShellRoute tabs)
- **Responsiveness**: ScreenUtil (`flutter_screenutil`)
- **Typography**: Google Fonts Outfit (`google_fonts`)
- **Serialization**: Freezed (`freezed_annotation` + `json_annotation`)
- **Local Storage**: SharedPreferences + Flutter Secure Storage (unified)
- **Utilities**: fpdart, collection, intl, gap, mocktail

---

## 📂 RESTURED FOLDER STRUCTURE

The project is structured according to SOLID and Clean Architecture principles, tailored to a modularized **feature-first** scheme:

```
lib/
├── main.dart                    ← App entry point (initializes SharedPreferences & Riverpod)
│
├── config/                      ← Environments & Flavors
│   ├── config.dart              ← config barrel
│   ├── env.dart                 ← Env configurations & feature flags (useMocks)
│   └── flavors.dart             ← AppFlavor (dev, staging, prod) via --dart-define
│
├── core/                        ← Shared framework & layout infrastructure
│   ├── core.dart                ← core barrel
│   ├── constants/               ← Typed App & Asset constants
│   ├── extensions/              ← context, string, date, double extensions
│   ├── router/                  ← GoRouter configuration & routes paths/names
│   ├── services/                ← Unified SharedPreferences + SecureStorage
│   ├── theme/                   ← M3 Light/Dark Theme & Typography
│   │   └── tokens/              ← Design Tokens (spacing, radius, elevation, durations, etc.)
│   └── widgets/                 ← Reusable Design System Widgets (AppButton, AppTextField, etc.)
│
├── features/                    ← Split modular features (independent)
│   ├── auth/                    ← Auth flow
│   ├── onboarding/              ← Onboarding sliders
│   ├── home/                    ← Main dashboard home screen
│   ├── search/                  ← Search & filter options
│   ├── category/                ← Service category detail screens
│   ├── vendor_listing/          ← Local laundry vendors overview
│   ├── vendor_details/          ← Vendor services menu & info
│   ├── cart/                    ← Shopping cart management
│   ├── checkout/                ← Checkout, slots, & payment choices
│   ├── orders/                  ← User orders list & details tracker
│   ├── profile/                 ← Settings & user profile
│   ├── address/                 ← Address manager
│   └── notifications/           ← Inbox & alerts
│
├── models/                      ← Unified Freezed domain models
│   ├── models.dart              ← models barrel
│   ├── user_model.dart          ← UserModel + UserRole
│   ├── address_model.dart       ← AddressModel + LatLng + AddressType
│   ├── order_model.dart         ← OrderModel + OrderStatus + PaymentMethod + OrderItem
│   ├── service_model.dart       ← ServiceModel + ServiceCategory
│   └── vendor_model.dart        ← VendorModel + CategoryModel + CartModel
│
├── providers/                   ← Global app-wide Riverpod providers
│   ├── providers.dart           ← providers barrel
│   ├── auth_provider.dart       ← AuthNotifier & state management
│   └── theme_provider.dart      ← ThemeModeNotifier (persisted setting)
│
└── shared/                      ← Cross-cutting widgets and repo specifications
    ├── shared.dart              ← shared barrel
    ├── repositories/            ← BaseRepository & Pagination definitions
    └── widgets/                 ← SectionHeader, StatusBadge, RatingRow, etc.
```

---

## 🎨 Design System & Tokens

All components pull parameters directly from core design tokens instead of using hardcoded variables:
- **Spacing (`spacing.dart`)**: 4pt modular scale (e.g. `AppSpacing.md` = 16, `lg` = 24).
- **Radius (`radius.dart`)**: Preset border radii (e.g. `AppRadius.button` = 16, `card` = 16).
- **Elevation (`elevation.dart`)**: Shadow presets (e.g. `AppElevation.cardShadow`, `primaryGlow`).
- **Durations & Curves (`durations.dart`)**: Timing and spring motion curves (e.g. `AppDurations.normal` = 250ms).
- **Breakpoints (`breakpoints.dart`)**: Responsive grid layout width thresholds.
- **Icons (`icons.dart`)**: Unified icon map (enables switching icon sets globally).

---

## 💾 Storage & Mocking System

### Storage Service
A unified key-value and secure storage API that uses **SharedPreferences** for non-sensitive settings (like theme selection) and **Flutter Secure Storage** (Keychain/Keystore) for tokens.

### Mock Repositories (`repositories/mock/`)
To support offline development before the backend is finished, the application implements abstract interfaces with local mock data read from JSON files:
- **Mock Data Assets**: `assets/mock/categories.json`, `vendors.json`, `services.json`, `orders.json`.
- **Abstract Contracts**: `CustomerRepository` & `VendorRepository`.
- **Mock Implementation**: `MockCustomerRepository` & `MockVendorRepository` handle all reads, writes, cart manipulation, and scheduling with artificial delays.
- **Seamless Migration**: To swap to real endpoints later, simply write an `ApiCustomerRepository` implementing the contract and update the Riverpod provider override. No changes to the UI layer are required.

---

## 🚀 Running the App

### 1. Retrieve Packages
```bash
flutter pub get
```

### 2. Generate Code (Freezed & Riverpod generated files)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Build & Run (Dev / Staging / Prod)
```bash
# Run Development (Default)
flutter run --dart-define=FLAVOR=development

# Run Staging
flutter run --dart-define=FLAVOR=staging

# Run Production
flutter run --dart-define=FLAVOR=production
```
