# Qwenton CommerceOps — Implementation Guide

## 1. Recommended architecture

```text
Flutter Android app
        |
        | HTTPS / typed API
        v
Backend API or Supabase Edge Functions
        |
        +-- PostgreSQL database
        +-- Object storage for images/evidence
        +-- Auth/OTP provider
        +-- Payment-provider adapter
        +-- Analytics and crash reporting
        +-- Background job queue for reminders
```

A managed PostgreSQL backend such as Supabase reduces infrastructure work for the first release. Keep payment and courier integrations behind interfaces so they can be replaced later.

## 2. Suggested repository structure

```text
qwenton-commerceops/
├── apps/
│   └── android/
│       ├── lib/
│       │   ├── core/
│       │   ├── features/
│       │   │   ├── auth/
│       │   │   ├── onboarding/
│       │   │   ├── products/
│       │   │   ├── storefront/
│       │   │   ├── orders/
│       │   │   ├── payments/
│       │   │   ├── analytics/
│       │   │   └── settings/
│       │   ├── shared/
│       │   └── l10n/
│       └── test/
├── backend/
│   ├── migrations/
│   ├── functions/
│   ├── seed/
│   └── tests/
├── docs/
│   ├── api.md
│   ├── threat-model.md
│   └── privacy-retention.md
└── README.md
```

## 3. Core database tables

### `businesses`

`id`, `owner_user_id`, `name`, `preferred_language`, `whatsapp_number`, `gstin_encrypted_or_tokenized`, `created_at`, and `deleted_at`.

### `business_members`

`business_id`, `user_id`, `role` — owner or staff — and `created_at`.

### `products`

`id`, `business_id`, `name`, `description`, `sku`, `currency`, `selling_price_minor`, `discount_minor`, `product_cost_minor`, `packaging_cost_minor`, `shipping_cost_minor`, `payment_fee_rate`, `expected_return_rate`, `expected_rto_rate`, `stock_quantity`, `is_active`, `created_at`, and `updated_at`.

### `product_variants`

`id`, `product_id`, `name`, `sku`, `price_delta_minor`, and `stock_quantity`.

### `storefront_links`

`id`, `business_id`, `product_id`, `public_token`, `is_active`, `created_at`, and `expires_at`.

### `customers`

`id`, `business_id`, `name`, `phone_encrypted_or_tokenized`, `address_encrypted_or_tokenized`, `pincode`, `consent_order_communication`, `created_at`, and `deleted_at`.

### `orders`

`id`, `business_id`, `customer_id`, `order_number`, `payment_method`, `payment_status`, `fulfilment_status`, `subtotal_minor`, `discount_minor`, `shipping_minor`, `payment_fee_minor`, `product_cost_minor`, `packaging_cost_minor`, `expected_return_cost_minor`, `expected_rto_cost_minor`, `estimated_profit_minor`, `realised_profit_minor`, `created_at`, and `updated_at`.

### `order_items`

`order_id`, `product_id`, `variant_id`, `quantity`, `unit_price_minor`, and `unit_cost_minor`.

### `payment_evidence`

`id`, `order_id`, `type` — UTR, screenshot, or provider event — `reference`, `storage_path`, `review_status`, `reviewed_by`, and `created_at`.

### `order_events`

`id`, `order_id`, `actor_user_id`, `event_type`, `old_value_json`, `new_value_json`, and `created_at`.

## 4. API surface

```text
POST   /auth/request-otp
POST   /auth/verify-otp
GET    /business/me
POST   /business
POST   /products
GET    /products
PATCH  /products/:id
POST   /products/:id/publish-link
GET    /storefront/:token
POST   /storefront/:token/orders
GET    /orders
GET    /orders/:id
PATCH  /orders/:id/status
POST   /orders/:id/payment-evidence
POST   /orders/:id/messages/preview
GET    /reports/summary
GET    /reports/orders.csv
POST   /imports/products.csv
POST   /exports/orders.csv
DELETE /account
```

Public storefront endpoints must never expose private analytics, internal cost fields, the complete customer list, or staff details.

## 5. Profit engine

Store money as integer minor units such as paise, never floating-point rupees.

```text
net_sales = selling_price - discount
payment_fee = net_sales * payment_fee_rate
expected_return_cost = net_sales * expected_return_rate * return_handling_cost_rate
expected_rto_cost = shipping_cost * expected_rto_rate
estimated_profit =
  net_sales
  - product_cost
  - packaging_cost
  - shipping_cost
  - payment_fee
  - expected_return_cost
  - expected_rto_cost
```

Show all calculation inputs with an “edit assumptions” action. When an order reaches a final state, replace estimates with actual costs where available.

## 6. Payment implementation

Use a non-custodial model for the MVP:

1. Generate a UPI intent or payment-provider checkout.
2. Return the customer to the order confirmation page.
3. Show “payment pending” until a trusted provider callback or manual seller review confirms payment.
4. Allow UTR entry and screenshot upload as evidence, clearly labelled “needs review.”
5. Never ask for or store UPI PIN, OTP, card data, or banking passwords.

Do not mark a screenshot as verified solely because OCR detects a successful-looking word. Prefer honest uncertainty over false payment confirmation.

## 7. Security and privacy checklist

- Implement row-level security by `business_id`.
- Use signed URLs for screenshots and customer documents.
- Encrypt or tokenise phone numbers and addresses where practical.
- Do not log raw customer PII.
- Add rate limits to public order creation and OTP endpoints.
- Add file-type and file-size validation.
- Maintain an audit trail for status and financial-input changes.
- Provide account deletion and data export.
- Define retention periods for inactive orders and payment evidence.
- Restrict staff access to financial configuration and exports.
- Add fraud reporting and support escalation.

## 8. Analytics event taxonomy

Use privacy-safe event names:

```text
seller_onboarding_completed
product_created
product_link_published
storefront_viewed
checkout_started
order_created
payment_handoff_started
payment_evidence_uploaded
order_status_changed
whatsapp_template_shared
csv_import_completed
profit_viewed
subscription_screen_viewed
subscription_started
```

Do not include phone numbers, addresses, screenshots, message bodies, or payment references in event properties.

## 9. Testing plan

### Unit tests

Test profit calculations, discounts, tax configuration fields, return/RTO assumptions, order-state transitions, role permissions, and CSV validation.

### Integration tests

Test public storefront to order creation, payment-pending to payment-confirmed flow, image upload and signed URL expiry, seller account deletion, and export totals matching dashboard totals.

### Device tests

Test budget Android devices, poor network, app backgrounding, low storage, large-text settings, Hindi fonts, interrupted uploads, and shared-device logout.

### Safety tests

Confirm that public links cannot reveal internal cost data; staff cannot access another business; expired links stop accepting orders; deleted customer data is removed or anonymised according to policy; and fake payment screenshots remain “needs review.”

## 10. Eight-week build sequence

### Week 1 — Discovery and design

Interview 15 sellers. Collect anonymised examples of their current order spreadsheet, DM process, payment reconciliation, and return/RTO workflow. Choose one seller segment, such as Instagram fashion sellers. Deliver user flows, clickable prototype, data model, pricing experiment, and risk review.

### Week 2 — Foundation

Set up the Flutter project, authentication abstraction, database, storage, environments, logging, analytics, and design system.

### Weeks 3–4 — Core order loop

Build onboarding, product catalogue, shareable product page, customer checkout, order creation, dashboard, and manual status changes.

### Week 5 — Profit engine

Add cost inputs, expected versus realised profit, order detail, CSV export, and seeded demo data.

### Week 6 — Payments and communication

Add the UPI handoff adapter, payment-pending state, manual UTR/evidence flow, WhatsApp share templates, and retry/error states.

### Week 7 — Pilot hardening

Add staff roles, audit logs, account deletion, data export, abuse reporting, rate limiting, crash reporting, and budget-device testing.

### Week 8 — Paid pilot

Launch to 20–30 sellers with manual onboarding. Charge only after sellers complete real orders. Review weekly outcomes and remove features that do not improve order completion or profit visibility.

## 11. First validation script

Ask sellers:

1. Show me how you handled your last ten orders.
2. Where did each order arrive from?
3. How did you confirm payment?
4. How did you know what was actually profitable?
5. How many orders were returned, cancelled, or RTO?
6. What information did you enter more than once?
7. What mistake cost you the most money recently?
8. What do you currently pay for software, courier tools, ads, or assistance?
9. If this app prevented that mistake, what would it be worth monthly?
10. Would you pay today for a 30-day pilot using your real orders?

Ask about the last real workflow before asking whether someone would use the app.

## 12. First implementation milestone

The first useful release is this six-step loop:

```text
Create product
→ publish link
→ customer places order
→ seller confirms payment/COD
→ seller updates delivery state
→ app shows estimated or realised profit
```

If this loop works reliably for 20 real sellers, add integrations. If it does not, more AI, gamification, or marketplace features will not solve the core problem.

## 13. What not to build first

Avoid a full marketplace discovery feed, Instagram DM scraping, complex courier aggregation, lending, cash advances, creator follower rankings, AI-generated spam messages, a large influencer campaign marketplace, GST filing, legal/tax advice, stored-value wallets, and customer credit until the core workflow has paid retention.
