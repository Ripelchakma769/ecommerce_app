# Implementation Plan: Flutter Provider Pattern E-Commerce Architecture

**Target Project:** `/Users/kays/dev/flutter/ecommerce_app`  
**Architecture:** Feature-first Flutter Architecture with Provider, GoRouter, Dio & SharedPreferences  
**Date:** September 2026  

---

## 1. Executive Summary

This plan outlines the end-to-end upgrade of the initial `ecommerce_app` project from a default counter starter into a robust, production-ready, feature-first e-commerce mobile application. It applies proven patterns established in the `flutter-provider-pattern` skill:

- **State Management & DI:** `provider` (`ChangeNotifier`, constructor injection, `autoFetch: false` test isolation, `UnmodifiableListView` encapsulation).
- **Declarative Navigation:** `go_router` (deep linking, cold-start resilience for `state.extra == null`, declarative route parameters, branded 404 handler).
- **Networking:** `dio` (configured singleton with base options, timeouts, logging/auth interceptors, typed `ApiException` error mapping).
- **Local Persistence & Offline Cache:** `shared_preferences` (`PreferenceService` wrapper for product catalog caching and cart storage).
- **Clean Feature-First Slices:** Strict separation across `core/` and `features/{product, cart}/`.

---

## 2. Target Directory Structure

```
lib/
├── main.dart                               # App initialization & service bootstrap
├── app.dart                                # MultiProvider + MaterialApp.router
├── core/
│   ├── constants/
│   │   ├── api_constants.dart              # Base URLs (DummyJSON), timeouts, storage keys
│   │   └── app_colors.dart                 # Design tokens & modern e-commerce palette
│   ├── network/
│   │   ├── api_exceptions.dart             # Typed domain exception hierarchy
│   │   └── dio_client.dart                 # Configured Dio singleton + interceptors
│   ├── router/
│   │   └── app_router.dart                 # GoRouter route table, 404 builder & deep link helpers
│   ├── storage/
│   │   └── preference_service.dart         # SharedPreferences wrapper for cache & preferences
│   └── theme/
│       └── app_theme.dart                  # Material 3 light & dark theme definitions
└── features/
    ├── product/
    │   ├── models/
    │   │   └── product_model.dart          # Immutable entity (refactored from lib/product.dart with defensive null-checks)
    │   ├── repository/
    │   │   └── product_repository.dart     # ProductRepository interface + ProductRepositoryImpl (Dio + offline cache)
    │   ├── provider/
    │   │   └── product_provider.dart       # ProductProvider with search, category filter, autoFetch guard
    │   └── presentation/
    │       ├── screens/
    │       │   ├── product_list_screen.dart   # Product catalog grid, search bar, category chips, cart badge
    │       │   └── product_detail_screen.dart # Cold-start resilient detail view, gallery, specs, reviews
    │       └── widgets/
    │           ├── category_chip_bar.dart     # Horizontal category selector
    │           └── product_card.dart          # Product card with discount badge, price, ratings
    └── cart/
        ├── models/
        │   └── cart_item_model.dart        # CartItemModel with quantity and item totals
        ├── repository/
        │   └── cart_repository.dart        # CartRepository interface + CartRepositoryImpl (local cache)
        ├── provider/
        │   └── cart_provider.dart          # CartProvider managing item addition, quantities, total calculation
        └── presentation/
            └── screens/
                └── cart_screen.dart        # Cart list screen with checkout summary
```

---

## 3. Phased Implementation Roadmap

### Phase 1: Core Scaffolding & Dependencies
- **Objectives:**
  1. Add dependencies to `pubspec.yaml`: `provider: ^6.1.5+1`, `go_router: ^18.0.1`, `dio: ^5.11.1`, `shared_preferences: ^2.5.5`.
  2. Run `flutter pub get` and verify dependency tree resolution.
  3. Create core infrastructure:
     - `lib/core/constants/api_constants.dart`: DummyJSON base URL (`https://dummyjson.com`), endpoint paths, cache keys, timeout configs.
     - `lib/core/constants/app_colors.dart`: Primary, accent, card background, ratings star colors.
     - `lib/core/network/api_exceptions.dart`: Domain hierarchy (`NetworkException`, `ServerException`, `NotFoundException`, `UnauthorizedException`, `CacheException`).
     - `lib/core/network/dio_client.dart`: Dio singleton with timeouts, request/response logging, and error conversion.
     - `lib/core/storage/preference_service.dart`: Encapsulated SharedPreferences client with string and string list caching methods.
     - `lib/core/theme/app_theme.dart`: Material 3 light and dark themes.
- **Verification:** Run `flutter analyze` to ensure core compiles cleanly with zero warnings.
- **Git Commit:** `feat(core): scaffold core networking, storage, constants, and themes`.

---

### Phase 2: Feature Domain & Data Layer (Products & Cart)
- **Objectives:**
  1. **Product Model:**
     - Refactor `lib/product.dart` into `lib/features/product/models/product_model.dart`.
     - Implement defensive null checks for DummyJSON payloads (optional `isFavourite`, `sold`, `colors`, `sizes`, nullable `brand`).
     - Provide `fromJson`, `toJson`, `copyWith`, `decodeList`, and `encodeList`.
  2. **Product Repository:**
     - `ProductRepository` interface declaring `getProducts({bool forceRefresh, String? category, String? query})` and `getProductById(int id)`.
     - `ProductRepositoryImpl` executing Dio network requests with SharedPreferences cache write and fallback on network failure.
  3. **Cart Model & Repository:**
     - `CartItemModel` representing item in cart with product reference and quantity.
     - `CartRepository` saving and retrieving cart items to/from SharedPreferences.
  4. **Providers:**
     - `ProductProvider`: Extends `ChangeNotifier`, constructor with `autoFetch` flag, `UnmodifiableListView<ProductModel>`, category filter state, live search filter, favorite toggle, and `@visibleForTesting reset()`.
     - `CartProvider`: Extends `ChangeNotifier`, cart items management, quantity modification, subtotal/total calculations, and item count badge getter.
  5. **Unit Tests:**
     - `test/features/product/provider/product_provider_test.dart` (testing loading state, data arrival, search filtering, error handling with `autoFetch: false`).
     - `test/features/cart/provider/cart_provider_test.dart` (testing adding items, quantity updates, total calculation).
- **Verification:** Run `flutter test` and `flutter analyze`.
- **Git Commit:** `feat(domain): implement product and cart models, repositories, and providers with unit tests`.

---

### Phase 3: Presentation Layer (UI, Screens, Widgets & Navigation)
- **Objectives:**
  1. **Router:**
     - `lib/core/router/app_router.dart`:
       - `/` -> `ProductListScreen`
       - `/products/:id` -> `ProductDetailScreen` (extracts `pathParameters['id']`, uses `state.extra` if present, falls back to repository fetch if `state.extra == null` for deep links)
       - `/cart` -> `CartScreen`
       - Branded 404 `errorBuilder`.
  2. **Product UI:**
     - `ProductCard`: Image thumbnail with error fallback, discount badge, title, price with original strike-through, rating stars, quick add-to-cart button.
     - `CategoryChipBar`: Scrollable category selector.
     - `ProductListScreen`: App bar with search field and cart action badge; category chips; pull-to-refresh; 4 distinct view states (loading skeleton/spinner, empty, error with retry, populated responsive grid).
     - `ProductDetailScreen`: Image gallery carousel/page view, discount chips, warranty/shipping metadata, customer reviews section, bottom action bar with quantity and Add to Cart.
  3. **Cart UI:**
     - `CartScreen`: List of cart items with quantity increment/decrement, remove swipe/action, order pricing breakdown, and Checkout button.
  4. **Bootstrap Integration:**
     - `lib/app.dart`: Configures `MultiProvider` providing `PreferenceService`, `DioClient`, `ProductRepository`, `CartRepository`, `ProductProvider`, and `CartProvider`. Connects `MaterialApp.router` to `AppRouter.router` and `AppTheme`.
     - `lib/main.dart`: Bootstraps bindings, initializes `PreferenceService`, constructs `DioClient`, and launches `MyApp`.
  5. **Widget Smoke Tests:**
     - Update `test/widget_test.dart` to test app mounting, catalog rendering, and interaction.
- **Verification:** Run `flutter test` and `flutter analyze`.
- **Git Commit:** `feat(presentation): implement responsive UI screens, widgets, and GoRouter navigation`.

---

### Phase 4: Cleanup & Final Verification
- **Objectives:**
  1. Delete legacy `lib/product.dart` (now cleanly organized under `lib/features/product/models/product_model.dart`).
  2. Run `flutter analyze` (must return `No issues found!`).
  3. Run `flutter test` (all unit and widget tests passing).
  4. Review git diff and ensure code cleanliness.
- **Git Commit:** `refactor: clean up legacy starter files and finalize architecture`.

---

## 4. Key Architectural Safeguards
1. **No Async Leaks in Constructors:** Every provider accepts `autoFetch: false` for test isolation.
2. **Encapsulated State:** All mutable collections exposed exclusively via `UnmodifiableListView`.
3. **Cold-Start Resilience:** Detail screen gracefully falls back to repository fetch when deep linked with `state.extra == null`.
4. **Dio 5.x Exhaustive Error Mapping:** Switch statements include `default` fallback to prevent compile issues with newer Dio versions.
5. **Pure Dart Providers:** Zero `BuildContext` stored in Providers. All navigation and SnackBars remain strictly in the presentation layer.
