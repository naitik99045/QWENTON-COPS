# Qwenton CommerceOps — Product Requirements Document

**Product:** Android-first commerce operations app for Indian micro-creators and small social sellers.

**MVP promise:** Turn social-media interest into a trackable order and show the real profit after product cost, shipping, payment fees, discounts, returns, and RTO.

## 1. Product summary

Qwenton CommerceOps is a seller-side operations app for people who sell through Instagram, YouTube Shorts, WhatsApp, and other social channels. It does not replace those channels. It gives sellers a simple product link, order capture, payment evidence, fulfilment tracking, and profit visibility.

The first version is a **profit and order layer**, not a social network, marketplace, payment wallet, or shipping company.

## 2. Problem statement

Small social sellers frequently manage product details, customer questions, addresses, UPI screenshots, COD orders, courier updates, returns, and settlements across DMs, spreadsheets, notes, bank apps, and WhatsApp. This creates missed or duplicate orders, unclear payment status, poor delivery visibility, and false profit calculations.

Qwenton CommerceOps succeeds when it helps a seller make fewer order mistakes and understand actual contribution profit.

## 3. Personas

### Solo social seller

A 20–35-year-old seller runs an Instagram or WhatsApp shop from a phone. They receive 10–100 orders per month and use UPI, notes, and courier websites. They value simplicity over advanced analytics.

### Regional-language creator

A creator sells beauty, fashion, food, craft, or local products through short videos. Their audience prefers Hindi or another Indian language. They need shareable product pages and local-language message templates.

### Small D2C team

A two-to-five-person team has product, fulfilment, and customer-support responsibilities. They need shared access, clear status ownership, and profit reports.

## 4. User stories

- As a seller, I want to publish a product link so customers can order without sending all details in DMs.
- As a seller, I want to record product and delivery costs so I can see expected profit.
- As a customer, I want to order without installing a separate app.
- As a seller, I want to distinguish paid, COD, pending, returned, and RTO orders.
- As a seller, I want to send a polite payment reminder without writing it manually each time.
- As a team owner, I want staff to update fulfilment without accessing financial settings.
- As a seller, I want to export my data if I stop using the product.

## 5. MVP requirements

### Authentication and onboarding

Phone login with an OTP provider abstraction. Collect seller name, business name, preferred language, WhatsApp number, optional GSTIN, terms acceptance, and privacy consent. Include a demo mode for evaluation.

### Product catalogue

Each product supports a name, description, images, category, SKU, variants, selling price, discount, product cost, packaging cost, shipping cost, payment-fee assumption, expected return percentage, expected RTO percentage, stock quantity, and active/inactive state.

### Shareable storefront

The seller can publish a public product page with a random non-guessable link. Customers do not need an account. Checkout collects name, phone, address, pincode, variant, quantity, payment method, and consent for order communication.

The storefront must not expose seller cost data, private analytics, staff information, or the complete customer list.

### Order management

Orders can be created from a storefront or manually. Sellers can filter by status, payment method, date, product, and customer. Each order has status history, internal notes, tags, return/RTO reason, and refund state.

### Profit calculation

Use two separate values:

```text
Expected profit = net sale
                 - product cost
                 - packaging cost
                 - shipping cost
                 - payment/platform fee
                 - expected return cost
                 - expected RTO cost

Realised profit = actual settlement
                  - actual product cost
                  - actual packaging cost
                  - actual shipping cost
                  - actual payment/platform fee
                  - actual return/RTO/refund costs
```

Always label assumptions. Expected profit must never be presented as final profit.

### Communication

Provide editable templates for order received, payment pending, COD confirmation, packed, shipped, delivered, review request, and return instructions. The MVP opens WhatsApp or the system share sheet. It does not send bulk automated messages without reviewing consent and platform policies.

### Reports

The MVP includes daily, weekly, and monthly order count; revenue and realised profit; return and RTO rate; payment-pending value; best-selling products; and CSV export.

## 6. Non-functional requirements

- Android 9 or newer for MVP, subject to current Google Play support review.
- First usable screen in under 3 seconds on a mid-range device with network.
- Read-only offline mode for recently viewed data.
- No loss of draft order when network fails.
- Server-side authorisation for every business record.
- Auditability for payment and order-status changes.
- Hindi-ready localisation architecture.

## 7. Success metrics

### Activation

- Seller creates the first product within 10 minutes.
- Seller publishes the first product link within 15 minutes.
- First customer order is created within 7 days.

### Engagement

- Weekly active sellers.
- Orders created per active seller.
- Percentage of orders with a recorded payment state.
- Percentage of orders with complete cost data.
- Repeat storefront usage.

### Business outcome

- Reduction in missed orders.
- Reduction in reconciliation time.
- Reduction in unknown payment status.
- Difference between expected and realised profit.
- Seller retention after 30 days.

### Monetisation experiments

Do not charge before sellers complete real orders. Initial targets are experiments, not promises:

- At least 20% of active pilot sellers ask for advanced features.
- At least 5 sellers prepay a monthly plan.
- At least 3 sellers use the product for 30 days.
- At least 2 sellers refer another seller without a paid referral incentive.

## 8. Monetisation hypotheses

### Free

One business, up to 20 active products, up to 30 orders per month, basic shareable links, manual status tracking, and basic profit estimates.

### Solo Pro

Hypothesis: ₹199/month or ₹1,999/year for unlimited products and orders, advanced profit reports, CSV import/export, saved WhatsApp templates, return/RTO analytics, and multiple storefront links.

### Team

Hypothesis: ₹499/month for up to five staff, role permissions, audit logs, shared status ownership, and advanced reports.

These are test prices, not claims about willingness to pay.

## 9. Risks

The main risks are weak seller retention, very price-sensitive customers, changing platform policies, payment fraud, fake screenshots, customer-privacy exposure, RTO volatility, unreliable social-platform integrations, and marketplace competition.

Keep the first version non-custodial, avoid social scraping, minimise customer data, and show payment uncertainty honestly.

## 10. Go/no-go gates

Proceed beyond MVP only if, during a 30-day pilot:

- 20 sellers create at least one live product link.
- 15 sellers receive a real order through the link.
- 10 sellers use order-status tracking more than once.
- 8 sellers enter complete cost data for most orders.
- 5 sellers prepay a plan or sign a paid pilot.
- 3 sellers report reduced missed-order or reconciliation work.
- No serious privacy, payment, or data-leak incident occurs.

If sellers use the app only as a catalogue but do not track orders or profit, narrow the product around storefront checkout or reconsider the broader operations concept.
