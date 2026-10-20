# Qwenton CommerceOps — AI build prompt

Copy and paste the following prompt into an AI coding agent or app-building system.

```text
Build an Android-first application called Qwenton CommerceOps.

Product goal:
Help Indian micro-creators and social sellers convert Instagram, YouTube Shorts, and WhatsApp traffic into trackable, profitable orders. The app must manage shareable product links, customer orders, UPI/COD payment evidence, fulfilment status, returns/RTO, and true profit per order.

Target users:
1. Solo Instagram and WhatsApp sellers.
2. Regional-language creators selling products through social media.
3. Small D2C teams with 1–5 people.

Primary MVP promise:
“A customer can order from your shared product link, and you can see whether that order is actually profitable.”

MVP scope:
- Phone-number authentication with an OTP abstraction for development.
- Seller onboarding with business name, language, optional GSTIN, WhatsApp number, and default shipping assumptions.
- Product catalogue with product name, images, variants, selling price, product cost, packaging cost, shipping cost, expected return rate, expected RTO rate, and stock quantity.
- Shareable mobile product page with product image, description, variant selection, quantity, customer name, phone, address, pincode, payment option, and consent checkbox.
- Order creation from the product page.
- UPI payment handoff using a configurable UPI deep link or mock provider in development. Never store UPI PIN, OTP, or card data.
- COD order creation.
- Manual UTR/reference entry and screenshot upload for payment reconciliation. Screenshot-based payment evidence must be labelled “needs review”; do not claim automatic verification without a trusted payment provider.
- Order statuses: New, Payment Pending, Paid, COD Confirmed, Packed, Shipped, Delivered, Return Requested, Returned, RTO, Cancelled, Refunded.
- Profit calculation per order: selling price minus product cost, packaging cost, shipping cost, payment/platform fee, discount, expected return cost, and expected RTO cost.
- Dashboard cards for orders today, pending payment, shipped, delivered, returns/RTO, estimated profit, and cash awaiting settlement.
- Order detail screen with customer, address, payment evidence, fulfilment status, costs, profit, audit history, and WhatsApp message templates.
- CSV import/export for products and orders.
- WhatsApp share buttons using ordinary share links. Do not scrape WhatsApp or Instagram.
- Basic Hindi and English UI architecture. Implement English first, but keep every user-facing string in localisation files.
- Seller-configurable WhatsApp templates for order confirmation, payment reminder, shipping update, and delivery follow-up.
- Basic team roles: Owner and Staff. Staff cannot change payout or business settings.
- Privacy settings, account deletion, data export, abuse reporting, and support contact.

Out of scope for MVP:
- Instagram or YouTube private API access.
- Automatic scraping of social platforms.
- Holding customer money or operating a wallet.
- Lending, insurance, investments, or credit.
- Full courier aggregation.
- Automated tax filing or GST advice.
- AI-generated customer messages without seller approval.
- Public social feed, follower leaderboard, referral pyramid, or recruitment rewards.
- Automatic UPI screenshot verification presented as guaranteed.

Recommended stack:
- Flutter and Dart for the Android application.
- Supabase or equivalent PostgreSQL backend for authentication, database, storage, and row-level security.
- REST or typed RPC layer between app and backend.
- Object storage for product images and payment evidence with signed URLs.
- Firebase Crashlytics or equivalent crash reporting.
- PostHog or equivalent privacy-safe product analytics.
- Razorpay/UPI provider integration behind an adapter interface; use a mock adapter for local development.

UX requirements:
- Fast on budget Android phones.
- Large tap targets and Hindi-ready copy.
- Seller creates the first product in under 3 minutes.
- Seller shares a product link in two taps.
- Customer checkout fits on one short screen plus address details.
- Show estimated-profit assumptions clearly.
- Never hide shipping, return, platform, or payment costs.
- Use “Needs review” instead of falsely saying “Payment verified.”
- Include sample data in empty states.

Security requirements:
- Never store UPI PIN, OTP, card number, CVV, or banking passwords.
- Encrypt sensitive data in transit and at rest through managed services.
- Use row-level authorisation so sellers see only their own business data.
- Use signed, expiring URLs for payment screenshots and customer documents.
- Minimise customer PII and allow deletion/export.
- Rate-limit public order links and OTP attempts.
- Validate uploaded files and limit size/type.
- Keep an audit log for order-status and cost changes.

Acceptance criteria:
1. A seller can create a product and publish a working share link.
2. A customer can create a COD or prepaid order without installing the app.
3. The seller sees the order in the dashboard within 5 seconds of creation.
4. The seller can manually move the order through all MVP statuses.
5. Profit updates when any cost input changes.
6. CSV export matches dashboard totals.
7. Staff cannot access another seller’s data or change owner settings.
8. Account deletion removes or anonymises associated customer data according to the retention policy.
9. Analytics events exclude raw phone numbers, addresses, payment screenshots, and message content.
10. The app works with seeded demo data and provides offline read access for the last loaded dashboard.

Build in phases:
Phase 1: Product catalogue, shareable product page, order creation, order dashboard, manual status updates, and profit calculation.
Phase 2: UPI handoff, payment evidence, WhatsApp templates, CSV import/export, and seller analytics.
Phase 3: Team accounts, returns/RTO workflows, payment-provider verification, courier integrations, and Hindi UI.

Before writing production integrations, generate:
- Database schema.
- API contract.
- Navigation map.
- Empty/loading/error states.
- Threat model.
- Test plan.
- Seed data.
- Event taxonomy.
- Deployment instructions.

Do not build a broad ecommerce marketplace. Keep Qwenton CommerceOps focused on the workflow from social content to profitable order.
```
