# Qwenton CommerceOps — Execution Roadmap (Vercel Backend + Dual Gradle Apps)

## Phase 1: Vercel Backend Service (`backend/`) on `qwen.qwenton.shop` [COMPLETED]
- [x] Initialize Next.js 14 / TypeScript serverless backend in `backend/` with `package.json`, `vercel.json`, and `.env.example`
- [x] Build `POST /api/famgateway/create-order` endpoint configured with `https://qwen.qwenton.shop/api/webhook/famgateway`
- [x] Build `POST /api/webhook/famgateway` endpoint with HMAC-SHA256 signature verification, idempotency handling, and Firebase Admin SDK Firestore updates
- [x] Build `GET /api/health` deployment verification endpoint
- [x] Verify Vercel production build (`npm run build`) — Tested: 0 errors, endpoints verified via HTTP requests

## Phase 2: Dual Android Gradle Scaffolding (`admin/` & `user/`) [COMPLETED]
- [x] Initialize `admin/` Android Gradle project structure
  - [x] Root `build.gradle.kts`, `settings.gradle.kts`, `gradle.properties`, Gradle wrapper
  - [x] `gradle/libs.versions.toml` version catalog
  - [x] `app/build.gradle.kts` with AGP, Kotlin, Material 3, Firebase BoM (Auth, Firestore, Storage)
  - [x] Place `google-services.json` in `admin/app/`
  - [x] `AndroidManifest.xml` (package `com.qwenton.cops.admin`)
  - [x] `MainActivity.kt` with Material 3 Dashboard, Order Feed, Catalogue view
  - [x] `domain/profit/ProfitCalculator.kt` (Pure Kotlin dual-engine profit calculator with integer Paise precision)
  - [x] `domain/model/Order.kt`, `Product.kt`, `Business.kt`
  - [x] `data/FirestoreAdminRepository.kt` (real-time order stream, status state machine, cost recalculation)
- [x] Initialize `user/` Android Gradle project structure
  - [x] Root `build.gradle.kts`, `settings.gradle.kts`, `gradle.properties`, Gradle wrapper
  - [x] `gradle/libs.versions.toml` with OkHttp & Retrofit
  - [x] `app/build.gradle.kts` with AGP, Kotlin, Material 3, Firebase BoM, OkHttp/Retrofit for Vercel API
  - [x] Place `google-services.json` in `user/app/`
  - [x] `AndroidManifest.xml` (package `com.qwenton.cops.user`, `qwenton://payment/callback` deep link)
  - [x] `MainActivity.kt` with product catalog, delivery details form, and one-tap "Pay via FamGateway UPI" button
  - [x] `data/FamGatewayClient.kt` (calls `https://qwen.qwenton.shop/api/famgateway/create-order`)
  - [x] `data/FirestoreUserRepository.kt` (public catalog stream with zero-cost leakage, order creation, and real-time status listener)
  - [x] `domain/model/StoreProduct.kt` (public view excluding COGS and internal costs)

## Phase 3: Admin Android App (`admin/`) Core Features [COMPLETED]
- [x] Firebase Authentication (Phone OTP with Dev mock bypass `123456` in `PhoneAuthScreen.kt` & `AuthRepository.kt`)
- [x] Business Onboarding Wizard (store profile, default shipping & packaging cost benchmarks in `BusinessOnboardingScreen.kt`)
- [x] Product Catalogue with Live True-Profit Calculator Preview Widget (`AddEditProductScreen.kt`)
- [x] Real-time Order Operations Center (Status tabs: Needs Review, To Pack, Shipped, Delivered, RTO in `MainActivity.kt`)
- [x] Order Detail Operational Screen (state transitions, cost adjustment dialog in `OrderDetailScreen.kt`)
- [x] WhatsApp Action Center (bilingual English/Hindi templates, live preview, direct `wa.me` intent in `WhatsAppActionSheet.kt`)
- [x] DPDP Act compliance & CSV Export (RFC 4180 export for Tally/Excel, permanent account erasure dialog in `SettingsScreen.kt`)

## Phase 4: User Android App (`user/`) Core Features [COMPLETED]
- [x] Customer Authentication (Phone OTP & 1-tap Guest checkout in `CustomerAuthRepository.kt` & `CustomerAuthScreen.kt`)
- [x] Storefront Catalogue & Variant Selector (`StorefrontCatalogScreen.kt` with zero-cost leakage)
- [x] Single-screen Delivery Address & Pincode capture (`CheckoutScreen.kt`)
- [x] FamGateway Payment Flow (calls `https://qwen.qwenton.shop/api/famgateway/create-order`, launches UPI Intent in `PaymentProcessingScreen.kt`)
- [x] Live Order Status & Tracking Stepper (`OrderTrackingScreen.kt` with real-time Firestore snapshot listener)
- [x] Root navigation shell in `MainActivity.kt` unifying Catalog -> Checkout -> UPI Payment -> Live Tracking

## Phase 5: End-to-End Verification & Pilot Hardening [COMPLETED]
- [x] End-to-end integration test: User places order in `user` app -> Calls `qwen.qwenton.shop` -> Simulates FamGateway webhook callback -> Firebase updates order -> Admin app receives real-time notification in "To Pack" (Verified via `backend/scripts/verify-e2e-flow.mjs`)
- [x] Mathematical profit engine precision test: Pure Kotlin integer Paise across delivered profit (₹435.02 / 43502 Paise) & RTO loss (-₹135.00 / -13500 Paise)
- [x] Security pentest review verifying HMAC-SHA256 signature verification, idempotency replay defense, zero cost leakage, and DPDP Act compliance (Updated in `.agent/security_report.md`)
