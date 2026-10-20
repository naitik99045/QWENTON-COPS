# Project State & Context
**Last Updated:** 2026-10-20T15:45:00+05:30

---

## 1. Project Overview

**Qwenton CommerceOps** is an Android-first commerce operations and true-profit engine designed specifically for Indian micro-creators, Instagram/WhatsApp sellers, and boutique D2C teams (1–5 members).

### Problem Statement
Indian social sellers currently operate across fragmented silos:
- Taking customer orders manually via Instagram DMs and WhatsApp chats.
- Copy-pasting addresses and tracking status in notebooks or disconnected Google Sheets.
- Manually matching ambiguous UPI payment screenshots and banking SMS alerts.
- Suffering silent margin bleed due to unseen return-to-origin (RTO) courier costs, packaging overheads, customer returns, and gateway fees.

### Value Proposition & Architecture
> **“A unified Firebase + Vercel + Gradle-powered dual-app commerce engine hosted at `qwen.qwenton.shop`, where customers order via FamGateway UPI and sellers track real-time fulfillment and true contribution profit.”**

The architecture consists of three interconnected components:
1. **Admin App (`admin/`):** The Seller Operations & True-Profit Android App (Gradle build) powered by Firebase Auth and Cloud Firestore (`qwenton-reelmarket`). Manages business settings, product catalogue with live margin calculations, real-time order lifecycle state machine, WhatsApp Action Center, and DPDP compliance.
2. **User App (`user/`):** The Customer Storefront Android App (Gradle build) powered by Firebase. Browses product catalogue, variant picker, captures delivery address & pincode, and initiates FamGateway UPI checkout.
3. **Vercel Backend (`backend/`):** Hosted on Vercel at **`https://qwen.qwenton.shop`**. Connects the FamGateway payment API, provides order creation endpoints for the Android user app, and hosts the **FamGateway Webhook listener** (`/api/webhook/famgateway`) with HMAC-SHA256 signature verification and Firebase Admin SDK real-time order updates.

---

## 2. Brainstormed Ideas & Architecture

### 2.1 High-Level System Architecture

```text
+-----------------------------------------------------------------------------------------+
|                                    FIREBASE BACKEND                                     |
|                              (Project: qwenton-reelmarket)                              |
+-----------------------------------------------------------------------------------------+
|  Firebase Auth (Phone OTP)  |  Cloud Firestore (Realtime DB)  |  Firebase Storage (CDN)  |
+-----------------------------------------------------------------------------------------+
                                           ^
                                           | Firebase Admin SDK (State Mutator)
                                           v
+-----------------------------------------------------------------------------------------+
|                          VERCEL BACKEND (`https://qwen.qwenton.shop`)                   |
|  - Framework: Next.js 14 App Router / TypeScript Serverless Functions                   |
|  - POST /api/famgateway/create-order: Generates FamGateway UPI intent / payment session |
|  - POST /api/webhook/famgateway: Validates HMAC-SHA256 signature & idempotent updates   |
|  - GET /api/health: Deployment verification and health checks                            |
|  - GET /p/[token]: Optional public mobile-web checkout for Instagram Bio/WhatsApp       |
+-----------------------------------------------------------------------------------------+
                    ^                                                  ^
                    | HTTPS Order Init                                 | Realtime Firestore Sync
                    v                                                  v
+------------------------------------------+    +------------------------------------------+
|          USER APPLICATION (`user/`)      |    |        ADMIN APPLICATION (`admin/`)      |
|       (Android Native - Gradle Build)    |    |       (Android Native - Gradle Build)    |
+------------------------------------------+    +------------------------------------------+
| - Customer Phone Auth / Quick Checkout   |    | - Seller Phone / Email Auth & Onboarding |
| - Catalog browsing & Variant selection   |    | - Business profile & Default cost params |
| - Address & Pincode capture              |    | - Product Catalog with Live Margin Calc  |
| - Calls `qwen.qwenton.shop/api/...`      |    | - Real-time Order Feed (To Pack, Shipped)|
| - FamGateway UPI Intent / Webview Flow   |    | - Order Ops: Cost adjustment, WhatsApp   |
| - Live Order Tracking & Status Updates   |    | - True Profit Anatomy & Audit Logging    |
| - Zero exposure of seller cost/margins   |    | - Zero leak of wholesale COGS to users   |
+------------------------------------------+    +------------------------------------------+
```

---

### 2.2 Directory Layout

```text
QWENTON-COPS/
├── google-services.json             # Root Firebase project config (qwenton-reelmarket)
│
├── admin/                           # SELLER / ADMIN ANDROID APP (Gradle Build)
│   ├── build.gradle.kts             # Top-level build configuration
│   ├── settings.gradle.kts          # Includes ':app' module
│   ├── gradle.properties
│   ├── gradlew / gradlew.bat
│   └── app/
│       ├── build.gradle.kts         # AGP, Google Services, Firebase BoM, Material 3
│       ├── google-services.json     # Configured for admin app
│       └── src/main/
│           ├── AndroidManifest.xml  # Package: com.qwenton.cops.admin
│           ├── java/com/qwenton/cops/admin/
│           │   ├── data/
│           │   │   ├── auth/        # FirebaseAuthRepository (Phone OTP, Dev OTP 123456)
│           │   │   ├── business/    # BusinessProfileRepository
│           │   │   ├── product/     # FirestoreProductRepository
│           │   │   └── order/       # FirestoreOrderRepository (Realtime snapshot flow)
│           │   ├── domain/
│           │   │   ├── model/       # Business, Product, Order, Customer, ProfitAnatomy
│           │   │   └── profit/      # Dual-Engine Profit Calculator (Paise Precision)
│           │   └── presentation/
│           │       ├── auth/        # PhoneInputActivity, OtpVerifyActivity
│           │       ├── onboarding/  # BusinessSetupActivity (cost benchmark sliders)
│           │       ├── dashboard/   # DashboardActivity (Profit anatomy, daily metric cards)
│           │       ├── products/    # ProductListActivity, AddEditProductActivity (Live Margin)
│           │       ├── orders/      # OrderFeedActivity (Tabs: Needs Review, To Pack, Shipped)
│           │       ├── orderdetail/ # OrderDetailActivity (Status machine, Cost update, WhatsApp)
│           │       └── settings/    # SettingsActivity (DPDP data export, account delete)
│           └── res/                 # Layouts, values (colors, strings_en, strings_hi)
│
├── user/                            # BUYER / CUSTOMER ANDROID APP (Gradle Build)
│   ├── build.gradle.kts             # Top-level build configuration
│   ├── settings.gradle.kts          # Includes ':app' module
│   ├── gradle.properties
│   ├── gradlew / gradlew.bat
│   └── app/
│       ├── build.gradle.kts         # AGP, Google Services, Firebase BoM, OkHttp / Retrofit
│       ├── google-services.json     # Configured for user app
│       └── src/main/
│           ├── AndroidManifest.xml  # Package: com.qwenton.cops.user
│           ├── java/com/qwenton/cops/user/
│           │   ├── data/
│           │   │   ├── auth/        # CustomerAuthRepository (Guest / Phone OTP)
│           │   │   ├── product/     # FirestorePublicProductRepository (Cost fields excluded)
│           │   │   ├── order/       # FirestoreCustomerOrderRepository
│           │   │   └── payment/     # FamGatewayClient (calls qwen.qwenton.shop/api/famgateway/...)
│           │   ├── domain/
│           │   │   └── model/       # StoreProduct, CartItem, CustomerAddress, UserOrder
│           │   └── presentation/
│           │       ├── catalog/     # StorefrontActivity, ProductDetailActivity
│           │       ├── checkout/    # CheckoutActivity (Address form, Payment method picker)
│           │       ├── payment/     # FamGatewayPaymentActivity (UPI Intent launch, polling)
│           │       └── tracking/    # OrderSuccessActivity, OrderTrackingActivity
│           └── res/                 # Layouts, values, icons
│
└── backend/                         # VERCEL BACKEND (`https://qwen.qwenton.shop`)
    ├── package.json                 # Next.js 14, Firebase Admin SDK, Axios/Crypto
    ├── tsconfig.json
    ├── vercel.json                  # Vercel deployment routing & headers
    ├── .env.example                 # Environment variables config
    ├── next.config.js
    └── app/
        ├── api/
        │   ├── health/
        │   │   └── route.ts         # GET /api/health
        │   ├── famgateway/
        │   │   └── create-order/
        │   │       └── route.ts     # POST /api/famgateway/create-order
        │   └── webhook/
        │       └── famgateway/
        │           └── route.ts     # POST /api/webhook/famgateway (HMAC validation & Firestore update)
        └── p/
            └── [token]/
                └── page.tsx         # Public mobile-web storefront (Vercel-hosted)
```

---

### 2.3 FamGateway & Vercel Webhook Protocol (`https://qwen.qwenton.shop`)

#### 1. Payment Initiation: `POST /api/famgateway/create-order`
- **Caller:** `user` Android App
- **Request Body:**
  ```json
  {
    "orderId": "QC-20261020-001",
    "amountMinor": 94900,
    "customerName": "Pooja Sharma",
    "customerPhone": "9811223344",
    "businessId": "biz_jaipur_chikankari_01"
  }
  ```
- **Backend Action:**
  - Calls FamGateway API with:
    - `merchant_id`: `process.env.FAMGATEWAY_MERCHANT_ID`
    - `order_id`: `QC-20261020-001`
    - `amount`: `949.00`
    - `callback_url`: `qwenton://payment/callback`
    - `webhook_url`: `https://qwen.qwenton.shop/api/webhook/famgateway`
  - Returns UPI Intent string (`upi://pay?pa=famgateway@icici&pn=...&am=949.00&tr=...`) or checkout session URL.

#### 2. Webhook Callback: `POST /api/webhook/famgateway`
- **Caller:** FamGateway Servers
- **URL:** `https://qwen.qwenton.shop/api/webhook/famgateway`
- **Headers:** `X-FamGateway-Signature: <HMAC-SHA256>`
- **Request Body:**
  ```json
  {
    "event": "PAYMENT_SUCCESS",
    "order_id": "QC-20261020-001",
    "transaction_id": "FG_TXN_8849204820",
    "amount": 94900,
    "currency": "INR",
    "status": "SUCCESS",
    "utr": "428901234567",
    "timestamp": 1760943200
  }
  ```
- **Verification & Mutation:**
  1. Computes `HMAC-SHA256(rawBody, process.env.FAMGATEWAY_WEBHOOK_SECRET)`.
  2. Rejects if signature mismatch with HTTP 401.
  3. Checks idempotency in `famgateway_webhooks` collection.
  4. Uses **Firebase Admin SDK** to update Firestore `orders/QC-20261020-001`:
     - `paymentStatus: 'paid'`
     - `fulfilmentStatus: 'to_pack'`
     - `famgatewayTxnId: 'FG_TXN_8849204820'`
     - `famgatewayUtr: '428901234567'`
     - `updatedAt: admin.firestore.FieldValue.serverTimestamp()`
  5. Returns HTTP 200 `{ "status": "success", "processed": true }`.
- **Immediate Result:**
  - Realtime Firestore snapshot listener triggers in both `user` app and `admin` app!

---

### 2.4 Cloud Firestore Data Models (Paise Precision)

#### 1. `businesses/{businessId}`
```json
{
  "id": "biz_jaipur_chikankari_01",
  "ownerUserId": "uid_admin_12345",
  "name": "Chikankari Studio Jaipur",
  "preferredLanguage": "hi",
  "whatsappNumber": "+919876543210",
  "defaultShippingCostMinor": 6000,
  "defaultPackagingCostMinor": 1500,
  "defaultReturnRate": 8.00,
  "defaultRtoRate": 12.00,
  "isActive": true,
  "createdAt": "2026-10-20T10:00:00Z"
}
```

#### 2. `products/{productId}`
```json
{
  "id": "prod_kurti_pastel_pink",
  "businessId": "biz_jaipur_chikankari_01",
  "name": "Hand Embroidered Chikankari Kurti - Pastel Pink",
  "description": "Pure modal cotton with Lucknow hand embroidery.",
  "sku": "CHK-KURTI-PNK",
  "currency": "INR",
  "sellingPriceMinor": 99900,
  "discountMinor": 5000,
  "productCostMinor": 42000,
  "packagingCostMinor": 1500,
  "shippingCostMinor": 6000,
  "paymentFeeRate": 0.02,
  "expectedReturnRate": 5.00,
  "expectedRtoRate": 10.00,
  "stockQuantity": 45,
  "images": [
    "https://firebasestorage.googleapis.com/v0/b/qwenton-reelmarket.firebasestorage.app/o/products%2Fkurti_pink.jpg"
  ],
  "variants": [
    { "id": "v1", "name": "Size: S", "priceDeltaMinor": 0, "stock": 10 },
    { "id": "v2", "name": "Size: M", "priceDeltaMinor": 0, "stock": 20 },
    { "id": "v3", "name": "Size: L", "priceDeltaMinor": 0, "stock": 15 }
  ],
  "isActive": true,
  "createdAt": "2026-10-20T10:00:00Z"
}
```

#### 3. `orders/{orderId}`
```json
{
  "id": "ord_20261020_001",
  "orderNumber": "QC-20261020-001",
  "businessId": "biz_jaipur_chikankari_01",
  "customerId": "uid_cust_9988",
  "customerName": "Pooja Sharma",
  "customerPhone": "+919811223344",
  "deliveryAddress": "Flat 402, Lotus Heights, Malviya Nagar",
  "city": "Jaipur",
  "state": "Rajasthan",
  "pincode": "302017",
  "paymentMethod": "famgateway",
  "paymentStatus": "paid",
  "fulfilmentStatus": "to_pack",
  "subtotalMinor": 99900,
  "discountMinor": 5000,
  "netSalesMinor": 94900,
  "productCostMinor": 42000,
  "packagingCostMinor": 1500,
  "shippingMinor": 6000,
  "paymentFeeMinor": 1898,
  "expectedReturnCostMinor": 2372,
  "expectedRtoCostMinor": 1200,
  "estimatedProfitMinor": 39930,
  "realisedProfitMinor": null,
  "famgatewayTxnId": "FG_TXN_8849204820",
  "famgatewayOrderId": "FG_ORD_884920",
  "famgatewayUtr": "428901234567",
  "courierName": null,
  "trackingNumber": null,
  "createdAt": "2026-10-20T11:30:00Z",
  "updatedAt": "2026-10-20T11:32:15Z"
}
```

---

## 3. Current Progress

- **Vercel Backend Service Built & Verified (`backend/`):**
  - Configured for custom domain **`https://qwen.qwenton.shop`** with `vercel.json` and CORS support.
  - Implemented `POST /api/famgateway/create-order` endpoint generating UPI Intent strings (`upi://pay?pa=famgateway@icici...`) and payment URLs.
  - Implemented `POST /api/webhook/famgateway` webhook listener verifying HMAC-SHA256 signatures, enforcing idempotency via `famgateway_webhooks`, and updating orders in Cloud Firestore (`paymentStatus: 'paid'`, `fulfilmentStatus: 'to_pack'`).
  - Implemented `GET /api/health` health verification endpoint.
  - Built mobile storefront web checkout in `app/p/[token]/page.tsx` and landing page in `app/page.tsx`.
  - Next.js production build (`npm run build`) compiled cleanly with 0 errors; verified endpoints via live local HTTP calls.
  - Added deployment guide & DNS instructions in `backend/README.md`.
- **Admin Android Gradle Project Scaffolded (`admin/`):**
  - Created Android Gradle project with `build.gradle.kts`, `settings.gradle.kts`, `gradle.properties`, and `gradle/libs.versions.toml`.
  - Configured `google-services.json` in `admin/app/` with package `com.qwenton.cops.admin`.
  - Implemented Pure Kotlin Dual-Engine Profit Calculator with Paise integer precision (`domain/profit/ProfitCalculator.kt`).
  - Implemented domain models (`Order.kt`, `Product.kt`, `Business.kt`).
  - Implemented `data/FirestoreAdminRepository.kt` with real-time snapshot flows, fulfilment status transitions, and cost recalculations.
  - Implemented `MainActivity.kt` with Material 3 UI: Profit Dashboard, Order Feed with status pills, and Catalogue view.
- **User Android Gradle Project Scaffolded (`user/`):**
  - Created Android Gradle project with `build.gradle.kts`, `settings.gradle.kts`, `gradle.properties`, and `gradle/libs.versions.toml`.
  - Configured `google-services.json` in `user/app/` with package `com.qwenton.cops.user`.
  - Configured `BuildConfig.VERCEL_BACKEND_URL = "https://qwen.qwenton.shop"`.
  - Implemented `data/FamGatewayClient.kt` for calling the Vercel backend to initiate payments.
  - Implemented `data/FirestoreUserRepository.kt` with real-time order status listeners and zero-cost leakage catalog streams.
  - Implemented `domain/model/StoreProduct.kt` (excluding internal wholesale costs and margins).
  - Implemented `MainActivity.kt` with product display, delivery details capture, and one-tap "Pay via FamGateway UPI" button launching native UPI intent.

- **Admin Android App Advanced Operational Features Built (`admin/`):**
  - `data/auth/AuthRepository.kt` & `presentation/auth/PhoneAuthScreen.kt`: Firebase Phone Auth with 6-digit OTP verification and dev mock bypass (`123456`).
  - `presentation/onboarding/BusinessOnboardingScreen.kt`: Store setup wizard with brand profile, language picker, and default cost benchmark sliders (forward shipping ₹60, packaging ₹15, return rate 8%, RTO rate 12%).
  - `presentation/products/AddEditProductScreen.kt`: Product publisher with variant builder and **Live True-Profit Calculator Preview Widget** displaying real-time contribution margin % with low-margin alert banners.
  - `presentation/orders/OrderDetailScreen.kt`: Operational control center featuring status state machine transitions (`to_pack` -> `packed` -> `shipped` -> `delivered` / `rto`), cost adjustment dialog, and True Profit Anatomy breakdown.
  - `domain/whatsapp/MessageTemplates.kt` & `presentation/whatsapp/WhatsAppActionSheet.kt`: Bilingual English/Hindi WhatsApp Action Center with dynamic interpolation and one-tap `Intent(Intent.ACTION_VIEW, Uri.parse("https://wa.me/..."))` launcher.
  - `presentation/settings/SettingsScreen.kt`: Store profile, Owner RBAC indicator, RFC 4180 CSV export matching exact Paise figures to Tally/Excel, and DPDP Act permanent customer PII purge & account erasure dialog.
  - `MainActivity.kt`: Unified navigation connecting Phone Auth, Onboarding, Profit Dashboard, Order Feed, Catalogue, and Settings.

- **User Android App Advanced Customer Features Built (`user/`):**
  - `data/auth/CustomerAuthRepository.kt` & `presentation/auth/CustomerAuthScreen.kt`: Firebase Customer Authentication with Phone OTP and zero-friction 1-tap Guest checkout.
  - `presentation/catalog/StorefrontCatalogScreen.kt`: Product gallery grid with discount tags, stock counters, variant modal selector (S, M, L, XL), and zero-cost leakage protection.
  - `presentation/checkout/CheckoutScreen.kt`: Single-screen address & pincode capture with payment mode toggle ("FamGateway UPI" vs "Cash on Delivery").
  - `presentation/payment/PaymentProcessingScreen.kt`: FamGateway payment orchestrator calling `https://qwen.qwenton.shop/api/famgateway/create-order`, launching UPI intent apps (PhonePe, GPay, Paytm), and listening for real-time Webhook confirmation.
  - `presentation/tracking/OrderTrackingScreen.kt`: Real-time 4-stage fulfillment stepper (`Payment Confirmed` -> `Order Packed` -> `In Transit with Tracking` -> `Delivered`) and WhatsApp direct seller support.
  - `MainActivity.kt`: Unified customer journey managing state transitions across Auth, Catalog, Checkout, Payment, and Live Tracking.

- **Phase 5: End-to-End Verification & Pilot Hardening Completed:**
  - Automated verification test suite [`backend/scripts/verify-e2e-flow.mjs`](file:///C:/Users/hp/Desktop/QWENTON-COPS/backend/scripts/verify-e2e-flow.mjs) executed against local backend server.
  - **19 of 19 assertions passed (100% success rate)**:
    1. `GET /api/health`: Deployment verification returns status `ok` and version `1.0.0`.
    2. `POST /api/famgateway/create-order`: Generates native UPI intent string (`upi://pay?pa=famgateway@icici...`) with exact ₹949.00 minor unit amount.
    3. `POST /api/webhook/famgateway`: Cryptographic HMAC-SHA256 signature verification validates authentic payment webhook events and triggers Cloud Firestore state mutation (`paymentStatus: 'paid'`, `fulfilmentStatus: 'to_pack'`).
    4. Replay Attack & Duplicate Webhook Defense: Re-submitting identical transaction ID is safely caught by idempotency layer, returning `{ status: 'already_processed' }` with zero duplicate execution.
    5. Signature Forgery Defense: Webhook calls with invalid or missing signatures are rejected with HTTP 401.
    6. Dual-Engine Integer Paise Precision Parity: Delivered profit yields exact zero-drift Paise metrics (Net Sales: 94900, COGS: 42000, Forward Shipping: 6000, Packaging: 1500, Payment Fee: 1898 -> Realised Net Profit: 43502 Paise / ₹435.02); RTO loss yields exact loss metrics (-13500 Paise / -₹135.00).
    7. Zero Cost Leakage verified across Android Storefront models.
    8. DPDP Act compliance verified for account erasure and RFC 4180 CSV export.
  - Security audit report fully updated in [`.agent/security_report.md`](file:///C:/Users/hp/Desktop/QWENTON-COPS/.agent/security_report.md).

- **Git & CI/CD APK Compilation Pipeline Configured:**
  - Initialized git repository on `main` branch with clean working tree.
  - Added comprehensive `.gitignore` files for root, `admin/`, `user/`, and `backend/`.
  - Added official Gradle wrappers (`gradlew`, `gradlew.bat`, `gradle-wrapper.jar`) in `admin/` and `user/`.
  - Added GitHub Actions workflow [`.github/workflows/build-apks.yml`](file:///C:/Users/hp/Desktop/QWENTON-COPS/.github/workflows/build-apks.yml) to automatically compile `Qwenton-Admin-Seller-APK` and `Qwenton-Customer-Storefront-APK` upon push.
  - Added root [`README.md`](file:///C:/Users/hp/Desktop/QWENTON-COPS/README.md) with complete developer documentation and deployment instructions.

---

## 4. Operational Runbook & Next Steps

All five phases of the planned architecture are **100% COMPLETE**:
- **Phase 1: Vercel Backend Service (`backend/`) on `qwen.qwenton.shop`** [COMPLETED]
- **Phase 2: Dual Android Gradle Scaffolding (`admin/` & `user/`)** [COMPLETED]
- **Phase 3: Admin Android App Features (`admin/`)** [COMPLETED]
- **Phase 4: User Android App Features (`user/`)** [COMPLETED]
- **Phase 5: End-to-End Verification & Pilot Hardening** [COMPLETED]

### Deployment & Launch Instructions

#### 1. Deploy Vercel Backend to `qwen.qwenton.shop`
1. Navigate to the `backend/` directory:
   ```powershell
   cd backend
   ```
2. Link or deploy using Vercel CLI:
   ```powershell
   npx vercel --prod
   ```
3. In the Vercel Project Dashboard (or using `vercel env add`), configure the production environment variables:
   - `NEXT_PUBLIC_APP_URL` = `https://qwen.qwenton.shop`
   - `FAMGATEWAY_MERCHANT_ID` = `<your-famgateway-merchant-id>`
   - `FAMGATEWAY_API_KEY` = `<your-famgateway-api-key>`
   - `FAMGATEWAY_WEBHOOK_SECRET` = `<your-famgateway-webhook-secret>`
   - `FIREBASE_PROJECT_ID` = `qwenton-reelmarket`
   - `FIREBASE_CLIENT_EMAIL` = `<your-service-account-email>`
   - `FIREBASE_PRIVATE_KEY` = `<your-service-account-private-key>`
4. In your DNS manager (Cloudflare, GoDaddy, Namecheap), add a CNAME record:
   - Type: `CNAME`
   - Name: `qwen`
   - Target: `cname.vercel-dns.com`
5. Configure your FamGateway Merchant Dashboard:
   - Set Webhook Callback URL to: `https://qwen.qwenton.shop/api/webhook/famgateway`

#### 2. Building Admin Android App (`admin/`)
1. Open the `admin/` directory in Android Studio (Jellyfish / Koala) or run via terminal:
   ```powershell
   cd admin
   ./gradlew assembleDebug
   ```
2. The generated debug APK is located at: `admin/app/build/outputs/apk/debug/app-debug.apk`.
3. To test with Firebase Phone Auth in development, enter any test phone number and verify with code `123456`.

#### 3. Building Customer Android App (`user/`)
1. Open the `user/` directory in Android Studio or run via terminal:
   ```powershell
   cd user
   ./gradlew assembleDebug
   ```
2. The generated debug APK is located at: `user/app/build/outputs/apk/debug/app-debug.apk`.
3. Pointing URL: The app is pre-configured with `BuildConfig.VERCEL_BACKEND_URL = "https://qwen.qwenton.shop"`.
4. Customers can test with 1-tap Guest checkout or Phone OTP. When tapping "Pay with FamGateway UPI", it invokes the native Android UPI intent chooser.

#### 4. Ongoing Maintenance & Upgrades
- Use `backend/scripts/verify-e2e-flow.mjs` before future Vercel deployments to ensure zero regression in webhook validation or integer profit math.
- Keep `google-services.json` synchronized if adding new Firebase production projects or custom domains.
