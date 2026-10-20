"use client";

import React, { useState } from "react";
import { CheckCircle2, ShieldCheck, Truck, ArrowRight, MessageCircle, Copy, Check } from "lucide-react";

// Mock public product lookup (matching public_storefront_view in PostgreSQL)
// Strict constraint: NEVER contains product_cost, packaging_cost, shipping_cost, or margins
const MOCK_STOREFRONT_PRODUCTS: Record<string, any> = {
  "chikankari-pink": {
    productId: "22222222-2222-2222-2222-222222222221",
    businessName: "Chikankari Studio Jaipur",
    sellerWhatsapp: "919876543210",
    sellerUpiId: "chikankarijaipur@icici",
    name: "Hand Embroidered Chikankari Kurti - Pastel Pink",
    description: "Pure modal cotton fabric with intricate hand embroidery from Lucknow artisans. Breathable, comfortable, and elegant.",
    sellingPriceMinor: 99900, // ₹999
    discountMinor: 5000,      // ₹50
    images: [
      "https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=800&auto=format&fit=crop",
    ],
    variants: [
      { id: "v1", name: "Size: S", priceDeltaMinor: 0 },
      { id: "v2", name: "Size: M", priceDeltaMinor: 0 },
      { id: "v3", name: "Size: L", priceDeltaMinor: 0 },
      { id: "v4", name: "Size: XL", priceDeltaMinor: 5000 }, // +₹50
    ],
  },
};

export default function StorefrontProductPage({ params }: { params: { token: string } }) {
  const token = params.token || "chikankari-pink";
  const product = MOCK_STOREFRONT_PRODUCTS[token] || MOCK_STOREFRONT_PRODUCTS["chikankari-pink"];

  const [selectedVariant, setSelectedVariant] = useState(product.variants[1]); // Default Size M
  const [quantity, setQuantity] = useState(1);
  const [paymentMethod, setPaymentMethod] = useState<"upi" | "cod">("upi");

  // Form State
  const [customerName, setCustomerName] = useState("");
  const [customerPhone, setCustomerPhone] = useState("");
  const [address, setAddress] = useState("");
  const [pincode, setPincode] = useState("");
  const [consent, setConsent] = useState(true);
  const [utrNumber, setUtrNumber] = useState("");
  const [copiedUpi, setCopiedUpi] = useState(false);

  // Submission & Success State
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [orderConfirmed, setOrderConfirmed] = useState<any | null>(null);

  // Price Calculation
  const unitPrice = (product.sellingPriceMinor - product.discountMinor + selectedVariant.priceDeltaMinor) / 100;
  const totalPrice = unitPrice * quantity;

  const handleCopyUpi = () => {
    navigator.clipboard.writeText(product.sellerUpiId);
    setCopiedUpi(true);
    setTimeout(() => setCopiedUpi(false), 2000);
  };

  const handlePlaceOrder = (e: React.FormEvent) => {
    e.preventDefault();
    if (!customerName || !customerPhone || !address || !pincode) {
      alert("Please fill in your delivery details.");
      return;
    }
    if (customerPhone.length < 10) {
      alert("Please enter a valid 10-digit mobile number.");
      return;
    }

    setIsSubmitting(true);
    setTimeout(() => {
      const generatedOrderNumber = `QC-${new Date().toISOString().slice(0, 10).replace(/-/g, "")}-${Math.floor(1000 + Math.random() * 9000)}`;
      setOrderConfirmed({
        orderNumber: generatedOrderNumber,
        customerName,
        customerPhone,
        address,
        pincode,
        productName: product.name,
        variantName: selectedVariant.name,
        quantity,
        totalPrice,
        paymentMethod,
        utrNumber: utrNumber || null,
      });
      setIsSubmitting(false);
    }, 900);
  };

  if (orderConfirmed) {
    return (
      <div className="max-w-md mx-auto min-h-screen bg-white p-6 shadow-sm flex flex-col justify-between">
        <div>
          <div className="text-center py-8">
            <div className="w-16 h-16 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <CheckCircle2 className="w-10 h-10 text-emerald-600" />
            </div>
            <h1 className="text-2xl font-bold text-slate-900">Order Placed!</h1>
            <p className="text-sm text-slate-500 mt-1">Thank you for your order, {orderConfirmed.customerName}.</p>
            <div className="inline-block bg-slate-100 px-3 py-1 rounded-full text-xs font-semibold text-slate-700 mt-3">
              Order #{orderConfirmed.orderNumber}
            </div>
          </div>

          <div className="border border-slate-200 rounded-xl p-4 bg-slate-50 mb-6 space-y-2 text-sm">
            <div className="flex justify-between text-slate-600">
              <span>Item:</span>
              <span className="font-semibold text-slate-900">{orderConfirmed.productName}</span>
            </div>
            <div className="flex justify-between text-slate-600">
              <span>Variant:</span>
              <span className="text-slate-900">{orderConfirmed.variantName} (Qty: {orderConfirmed.quantity})</span>
            </div>
            <div className="flex justify-between text-slate-600">
              <span>Payment Mode:</span>
              <span className="font-semibold uppercase text-slate-900">{orderConfirmed.paymentMethod}</span>
            </div>
            {orderConfirmed.utrNumber && (
              <div className="flex justify-between text-slate-600">
                <span>UTR Reference:</span>
                <span className="text-slate-900">{orderConfirmed.utrNumber} (Needs Review)</span>
              </div>
            )}
            <div className="border-t border-slate-200 pt-2 flex justify-between font-bold text-base text-slate-900">
              <span>Total Payable:</span>
              <span>₹{orderConfirmed.totalPrice.toFixed(2)}</span>
            </div>
          </div>

          <div className="border border-slate-200 rounded-xl p-4 mb-6 text-xs text-slate-600 space-y-1">
            <div className="font-semibold text-slate-800 text-sm mb-1">Delivery Address:</div>
            <div>{orderConfirmed.address}</div>
            <div>PIN: {orderConfirmed.pincode}</div>
            <div>Mobile: +91 {orderConfirmed.customerPhone}</div>
          </div>
        </div>

        <div className="space-y-3 pb-6">
          <a
            href={`https://wa.me/${product.sellerWhatsapp}?text=${encodeURIComponent(
              `Hi ${product.businessName}, I just placed order #${orderConfirmed.orderNumber} for ${orderConfirmed.productName} (${orderConfirmed.variantName}). Total: ₹${orderConfirmed.totalPrice}`
            )}`}
            target="_blank"
            rel="noopener noreferrer"
            className="w-full bg-[#25D366] hover:bg-[#20bd5a] text-white py-3.5 px-4 rounded-xl font-bold flex items-center justify-center space-x-2 transition"
          >
            <MessageCircle className="w-5 h-5" />
            <span>Confirm Order on WhatsApp</span>
          </a>
          <button
            onClick={() => window.location.reload()}
            className="w-full bg-slate-100 hover:bg-slate-200 text-slate-800 py-3 rounded-xl font-semibold text-sm transition"
          >
            Place Another Order
          </button>
        </div>
      </div>
    );
  }

  const upiDeepLink = `upi://pay?pa=${encodeURIComponent(product.sellerUpiId)}&pn=${encodeURIComponent(
    product.businessName
  )}&am=${totalPrice.toFixed(2)}&cu=INR&tn=Order_${encodeURIComponent(product.name.slice(0, 20))}`;

  return (
    <div className="max-w-md mx-auto min-h-screen bg-white pb-28 shadow-sm">
      {/* Seller Header */}
      <header className="px-4 py-3 border-b border-slate-100 bg-white sticky top-0 z-20 flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <div className="w-7 h-7 bg-blue-600 rounded-lg flex items-center justify-center text-white font-bold text-xs">
            QC
          </div>
          <span className="font-semibold text-sm text-slate-800">{product.businessName}</span>
        </div>
        <div className="flex items-center text-emerald-700 text-xs font-medium space-x-1">
          <ShieldCheck className="w-4 h-4" />
          <span>Verified Seller</span>
        </div>
      </header>

      {/* Product Image */}
      <div className="relative aspect-square w-full bg-slate-100 overflow-hidden">
        <img
          src={product.images[0]}
          alt={product.name}
          className="w-full h-full object-cover"
        />
        <div className="absolute top-3 left-3 bg-red-600 text-white text-xs font-bold px-2.5 py-1 rounded-md shadow">
          ₹{(product.discountMinor / 100).toFixed(0)} OFF
        </div>
      </div>

      <div className="p-4 space-y-4">
        {/* Title and Price */}
        <div>
          <h1 className="text-lg font-bold text-slate-900 leading-snug">{product.name}</h1>
          <div className="flex items-baseline space-x-3 mt-2">
            <span className="text-2xl font-black text-slate-900">₹{unitPrice.toFixed(0)}</span>
            <span className="text-sm text-slate-400 line-through">
              ₹{(product.sellingPriceMinor / 100).toFixed(0)}
            </span>
            <span className="text-xs font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded">
              Free Delivery
            </span>
          </div>
          <p className="text-xs text-slate-500 mt-2 leading-relaxed">{product.description}</p>
        </div>

        {/* Variant Selection */}
        {product.variants.length > 0 && (
          <div className="pt-2 border-t border-slate-100">
            <label className="text-xs font-bold text-slate-700 block mb-2 uppercase tracking-wide">
              Select Option:
            </label>
            <div className="grid grid-cols-4 gap-2">
              {product.variants.map((v: any) => {
                const isSelected = selectedVariant.id === v.id;
                return (
                  <button
                    key={v.id}
                    type="button"
                    onClick={() => setSelectedVariant(v)}
                    className={`py-2 px-1 text-center rounded-lg border text-xs font-semibold transition ${
                      isSelected
                        ? "border-blue-600 bg-blue-50 text-blue-700 ring-2 ring-blue-600/20"
                        : "border-slate-200 text-slate-700 hover:border-slate-300"
                    }`}
                  >
                    {v.name}
                    {v.priceDeltaMinor > 0 && ` (+₹${v.priceDeltaMinor / 100})`}
                  </button>
                );
              })}
            </div>
          </div>
        )}

        {/* Quantity */}
        <div className="flex items-center justify-between pt-2 border-t border-slate-100">
          <span className="text-xs font-bold text-slate-700 uppercase tracking-wide">Quantity:</span>
          <div className="flex items-center border border-slate-200 rounded-lg overflow-hidden">
            <button
              type="button"
              onClick={() => setQuantity(Math.max(1, quantity - 1))}
              className="px-3 py-1.5 bg-slate-50 hover:bg-slate-100 text-slate-700 font-bold"
            >
              -
            </button>
            <span className="px-4 text-sm font-bold text-slate-800">{quantity}</span>
            <button
              type="button"
              onClick={() => setQuantity(quantity + 1)}
              className="px-3 py-1.5 bg-slate-50 hover:bg-slate-100 text-slate-700 font-bold"
            >
              +
            </button>
          </div>
        </div>

        {/* Customer Details Form */}
        <form onSubmit={handlePlaceOrder} className="space-y-3 pt-4 border-t border-slate-100">
          <div className="flex items-center space-x-2 text-slate-900 font-bold text-sm">
            <Truck className="w-4 h-4 text-blue-600" />
            <span>Delivery Information</span>
          </div>

          <div>
            <label className="text-xs text-slate-600 block mb-1">Full Name *</label>
            <input
              type="text"
              required
              value={customerName}
              onChange={(e) => setCustomerName(e.target.value)}
              placeholder="e.g. Priya Sharma"
              className="w-full px-3 py-2.5 rounded-lg border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="text-xs text-slate-600 block mb-1">Mobile Number (for delivery SMS & WhatsApp) *</label>
            <div className="flex rounded-lg border border-slate-200 overflow-hidden focus-within:ring-2 focus-within:ring-blue-500">
              <span className="bg-slate-100 px-3 py-2.5 text-xs font-bold text-slate-700 flex items-center border-r border-slate-200">
                +91
              </span>
              <input
                type="tel"
                required
                maxLength={10}
                value={customerPhone}
                onChange={(e) => setCustomerPhone(e.target.value.replace(/\D/g, ""))}
                placeholder="98765 43210"
                className="w-full px-3 py-2.5 text-sm focus:outline-none"
              />
            </div>
          </div>

          <div>
            <label className="text-xs text-slate-600 block mb-1">Delivery Address (House/Street/Landmark) *</label>
            <textarea
              required
              rows={2}
              value={address}
              onChange={(e) => setAddress(e.target.value)}
              placeholder="Flat 402, Royal Palms, Vaishali Nagar"
              className="w-full px-3 py-2 rounded-lg border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="text-xs text-slate-600 block mb-1">PIN Code *</label>
            <input
              type="text"
              required
              maxLength={6}
              value={pincode}
              onChange={(e) => setPincode(e.target.value.replace(/\D/g, ""))}
              placeholder="302021"
              className="w-full px-3 py-2.5 rounded-lg border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {/* Payment Method Switcher */}
          <div className="pt-3">
            <label className="text-xs font-bold text-slate-700 block mb-2 uppercase tracking-wide">
              Payment Option:
            </label>
            <div className="grid grid-cols-2 gap-3">
              <button
                type="button"
                onClick={() => setPaymentMethod("upi")}
                className={`p-3 rounded-xl border text-left flex flex-col justify-between transition ${
                  paymentMethod === "upi"
                    ? "border-blue-600 bg-blue-50/60 ring-2 ring-blue-600/20"
                    : "border-slate-200 hover:border-slate-300"
                }`}
              >
                <div className="text-xs font-bold text-slate-900">UPI Instant Pay</div>
                <div className="text-[11px] text-slate-500 mt-1">GPay, PhonePe, Paytm</div>
              </button>
              <button
                type="button"
                onClick={() => setPaymentMethod("cod")}
                className={`p-3 rounded-xl border text-left flex flex-col justify-between transition ${
                  paymentMethod === "cod"
                    ? "border-blue-600 bg-blue-50/60 ring-2 ring-blue-600/20"
                    : "border-slate-200 hover:border-slate-300"
                }`}
              >
                <div className="text-xs font-bold text-slate-900">Cash on Delivery</div>
                <div className="text-[11px] text-slate-500 mt-1">Pay cash at doorstep</div>
              </button>
            </div>
          </div>

          {/* UPI Intent or Manual UTR Field */}
          {paymentMethod === "upi" && (
            <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 space-y-2.5 text-xs">
              <div className="flex items-center justify-between text-slate-700">
                <span className="font-semibold">Seller UPI ID:</span>
                <button
                  type="button"
                  onClick={handleCopyUpi}
                  className="flex items-center space-x-1 text-blue-600 hover:underline font-bold"
                >
                  {copiedUpi ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5" />}
                  <span>{copiedUpi ? "Copied" : product.sellerUpiId}</span>
                </button>
              </div>

              <a
                href={upiDeepLink}
                className="w-full bg-blue-600 hover:bg-blue-700 text-white py-2 px-3 rounded-lg font-bold flex items-center justify-center space-x-1.5 transition"
              >
                <span>Tap to Pay with any UPI App</span>
              </a>

              <div>
                <label className="text-[11px] text-slate-500 block mb-1">
                  12-digit UPI Reference / UTR Number (optional):
                </label>
                <input
                  type="text"
                  maxLength={16}
                  value={utrNumber}
                  onChange={(e) => setUtrNumber(e.target.value)}
                  placeholder="e.g. 412984928192"
                  className="w-full px-2.5 py-1.5 rounded-lg border border-slate-200 text-xs bg-white focus:outline-none"
                />
              </div>
            </div>
          )}

          {/* Consent Checkbox */}
          <div className="flex items-start space-x-2 pt-2">
            <input
              type="checkbox"
              id="consent"
              checked={consent}
              onChange={(e) => setConsent(e.target.checked)}
              className="mt-0.5 rounded border-slate-300 text-blue-600 focus:ring-blue-500"
            />
            <label htmlFor="consent" className="text-[11px] text-slate-500 leading-tight">
              I agree to receive order tracking updates on WhatsApp / SMS from {product.businessName}.
            </label>
          </div>

          {/* Sticky Bottom Bar */}
          <div className="fixed bottom-0 left-0 right-0 p-4 bg-white border-t border-slate-200 z-30">
            <div className="max-w-md mx-auto flex items-center justify-between space-x-4">
              <div>
                <div className="text-[11px] text-slate-500">Total Amount:</div>
                <div className="text-xl font-black text-slate-900">₹{totalPrice.toFixed(2)}</div>
              </div>
              <button
                type="submit"
                disabled={isSubmitting}
                className="flex-1 bg-blue-600 hover:bg-blue-700 text-white font-bold py-3.5 px-6 rounded-xl shadow-lg shadow-blue-500/25 flex items-center justify-center space-x-2 transition disabled:opacity-50"
              >
                <span>{isSubmitting ? "Placing Order..." : "Place Order Now"}</span>
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  );
}
