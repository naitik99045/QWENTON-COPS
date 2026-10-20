# Qwenton CommerceOps (COPS)

> **Android-First Commerce Operations & True-Profit Contribution Engine for Indian Social Sellers**

Qwenton CommerceOps is an end-to-end commerce system built specifically for Indian micro-creators, Instagram/WhatsApp merchants, and boutique D2C brands. It unifies order tracking, UPI payment collection via **FamGateway**, real-time **Firebase** data synchronization, and a **Next.js 14** backend hosted at `https://qwen.qwenton.shop`.

---

## 🏗️ Architecture Overview

The repository is organized into three decoupled, production-ready modules:

```text
QWENTON-COPS/
├── .github/workflows/        # Automated GitHub Actions APK compilation CI/CD
│   └── build-apks.yml
├── admin/                   # 📱 SELLER / ADMIN ANDROID APP (Gradle + Jetpack Compose)
│   ├── app/                 # Package: com.qwenton.cops.admin
│   ├── gradlew / gradlew.bat
│   └── gradle/libs.versions.toml
├── user/                    # 🛒 BUYER / STOREFRONT ANDROID APP (Gradle + Jetpack Compose)
│   ├── app/                 # Package: com.qwenton.cops.user
│   ├── gradlew / gradlew.bat
│   └── gradle/libs.versions.toml
├── backend/                 # ⚡ VERCEL BACKEND SERVICE (Next.js 14 / TypeScript)
│   ├── app/api/famgateway/  # POST /api/famgateway/create-order (UPI Intent Generator)
│   ├── app/api/webhook/     # POST /api/webhook/famgateway (HMAC-SHA256 & Firebase Admin)
│   └── vercel.json          # Deployment configuration for https://qwen.qwenton.shop
└── google-services.json     # Firebase project configuration (qwenton-reelmarket)
```

---

## 🚀 Pushing to GitHub

To push this repository to your GitHub account:

```bash
# 1. Initialize git (if not already initialized)
git init

# 2. Add all files (all build caches, .next, and node_modules are ignored via .gitignore)
git add .

# 3. Commit the codebase
git commit -m "feat: complete Qwenton CommerceOps ecosystem (admin + user + vercel backend)"

# 4. Set main branch
git branch -M main

# 5. Link your GitHub remote repository
git remote add origin https://github.com/<your-username>/<your-repo-name>.git

# 6. Push to GitHub
git push -u origin main
```

---

## 📦 Converting into APKs

You can compile and download the APKs in **two ways**:

### Method 1: Automatic Cloud Build via GitHub Actions (Recommended)
As soon as you push this code to GitHub:
1. Go to the **Actions** tab in your GitHub repository.
2. The workflow **"Build Android APKs (Admin & User)"** will trigger automatically.
3. Once completed (approx. 3-4 minutes), scroll down to the **Artifacts** section:
   - **`Qwenton-Admin-Seller-APK`**: Download `app-debug.apk` for the Seller Admin app.
   - **`Qwenton-Customer-Storefront-APK`**: Download `app-debug.apk` for the Customer Storefront app.
4. Transfer the `.apk` files directly to your Android device or share them with testers!

### Method 2: Local Build via Android Studio / Terminal
If you have Android Studio (Koala / Jellyfish) or Android SDK installed:

#### 1. Seller Admin App:
```bash
cd admin
./gradlew assembleDebug      # On Linux/macOS
gradlew.bat assembleDebug    # On Windows
```
*Output APK:* `admin/app/build/outputs/apk/debug/app-debug.apk`

#### 2. Customer Storefront App:
```bash
cd user
./gradlew assembleDebug      # On Linux/macOS
gradlew.bat assembleDebug    # On Windows
```
*Output APK:* `user/app/build/outputs/apk/debug/app-debug.apk`

---

## 🌐 Deploying the Vercel Backend (`qwen.qwenton.shop`)

1. Install dependencies and deploy:
   ```bash
   cd backend
   npm install
   npx vercel --prod
   ```
2. Configure environment variables in the Vercel Dashboard:
   - `NEXT_PUBLIC_APP_URL` = `https://qwen.qwenton.shop`
   - `FAMGATEWAY_MERCHANT_ID` = `<your_merchant_id>`
   - `FAMGATEWAY_API_KEY` = `<your_api_key>`
   - `FAMGATEWAY_WEBHOOK_SECRET` = `<your_webhook_secret>`
   - `FIREBASE_PROJECT_ID` = `qwenton-reelmarket`
   - `FIREBASE_CLIENT_EMAIL` = `<your_firebase_client_email>`
   - `FIREBASE_PRIVATE_KEY` = `<your_firebase_private_key>`
3. Set your CNAME DNS record:
   - **Name:** `qwen`
   - **Type:** `CNAME`
   - **Target:** `cname.vercel-dns.com`
4. Register the Webhook URL in your FamGateway Merchant Dashboard:
   - `https://qwen.qwenton.shop/api/webhook/famgateway`

---

## 🔒 Security & Precision Highlights
- **Zero Cost Leakage:** The `user/` application codebase possesses zero knowledge of wholesale COGS, packaging cost benchmarks, or profit margins.
- **HMAC-SHA256 Webhook Verification:** The Vercel webhook listener strictly verifies FamGateway signatures using constant-time comparison to prevent timing attacks and unauthorized order state transitions.
- **Idempotency Guard:** Duplicate webhook deliveries from network retries are deduplicated via Firestore.
- **Integer Paise Financial Precision:** Dual-engine contribution profit and RTO loss calculations operate exclusively on 64-bit integer `Long` minor units (Paise), completely eliminating IEEE 754 floating-point rounding errors.
- **DPDP Act 2023 Compliance:** Seller admin app provides RFC 4180 CSV exports and atomic customer PII permanent erasure.
