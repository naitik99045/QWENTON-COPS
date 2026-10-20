# Qwenton CommerceOps — Vercel Backend Service
**Target Domain:** [https://qwen.qwenton.shop](https://qwen.qwenton.shop)

This service is the operational backend for **Qwenton CommerceOps**, serving both the **Admin App (`admin/`)** and **User App (`user/`)** while processing real-time payment webhooks from **FamGateway**.

---

## 1. Features & Endpoints

| Endpoint | Method | Description |
|:---|:---|:---|
| `/api/health` | `GET` | Health check and deployment status |
| `/api/famgateway/create-order` | `POST` | Generates FamGateway payment sessions & UPI Intent deep links |
| `/api/webhook/famgateway` | `POST` | HMAC-SHA256 verified webhook listener updating Firestore in real-time |
| `/p/[token]` | `GET` | Mobile-responsive customer checkout web page for Instagram Bio/WhatsApp |

---

## 2. Deploy to Vercel (1-Click or CLI)

### Option A: Via GitHub & Vercel Dashboard
1. Push this repository to GitHub.
2. In Vercel, click **Add New Project** and select this repo.
3. In **Root Directory**, select `backend`.
4. Add the **Environment Variables** (see section below).
5. Deploy!

### Option B: Via Vercel CLI
```bash
cd backend
npm install -g vercel
vercel deploy --prod
```

---

## 3. Custom Domain Configuration (`qwen.qwenton.shop`)

In your Vercel Project Settings -> **Domains**:
1. Add domain: `qwen.qwenton.shop`.
2. In your DNS provider (e.g., Cloudflare, GoDaddy, Namecheap):
   - **Type:** `CNAME`
   - **Name:** `qwen`
   - **Target / Content:** `cname.vercel-dns.com`
   - **Proxy:** DNS only (or standard DNS)

---

## 4. Environment Variables

Set these in your **Vercel Project Settings -> Environment Variables**:

| Variable | Recommended / Default Value | Purpose |
|:---|:---|:---|
| `NEXT_PUBLIC_BASE_URL` | `https://qwen.qwenton.shop` | Base public URL for webhooks and deep links |
| `FAMGATEWAY_MERCHANT_ID` | `FG_MERCHANT_XXXX` | Your FamGateway Merchant ID |
| `FAMGATEWAY_API_KEY` | `fg_live_...` | FamGateway Live API Key |
| `FAMGATEWAY_SECRET` | `fg_sec_...` | FamGateway API Secret |
| `FAMGATEWAY_WEBHOOK_SECRET`| `fg_whsec_...` | Webhook verification secret (HMAC-SHA256) |
| `FIREBASE_PROJECT_ID` | `qwenton-reelmarket` | Firebase Project ID |
| `FIREBASE_CLIENT_EMAIL` | `firebase-adminsdk@...` | Service Account Client Email |
| `FIREBASE_PRIVATE_KEY` | `-----BEGIN PRIVATE KEY-----\n...` | Service Account Private Key |
| `FIREBASE_DATABASE_URL` | `https://qwenton-reelmarket-default-rtdb.firebaseio.com` | Realtime Database URL |

---

## 5. FamGateway Dashboard Webhook Setup

In your **FamGateway Merchant Dashboard**:
1. Navigate to **Developer Settings / Webhooks**.
2. Enter Webhook URL:
   ```text
   https://qwen.qwenton.shop/api/webhook/famgateway
   ```
3. Copy the **Webhook Secret Key** and paste it into Vercel as `FAMGATEWAY_WEBHOOK_SECRET`.
4. Enable events: `PAYMENT_SUCCESS`, `PAYMENT_FAILED`.
