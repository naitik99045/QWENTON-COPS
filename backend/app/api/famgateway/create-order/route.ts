import { NextRequest, NextResponse } from "next/server";
import { adminDb } from "@/lib/firebaseAdmin";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const {
      orderId,
      amountMinor,
      customerName,
      customerPhone,
      businessId,
      productName,
    } = body;

    if (!orderId || !amountMinor || !customerPhone) {
      return NextResponse.json(
        {
          error: "Missing required fields: orderId, amountMinor, and customerPhone are required.",
        },
        { status: 400 }
      );
    }

    const host = process.env.NEXT_PUBLIC_BASE_URL || "https://qwen.qwenton.shop";
    const webhookUrl = `${host}/api/webhook/famgateway`;
    const amountRupees = (amountMinor / 100).toFixed(2);

    // FamGateway API Credentials
    const apiKey = process.env.FAMGATEWAY_API_KEY;
    const merchantId = process.env.FAMGATEWAY_MERCHANT_ID || "FG_MERCHANT_DEFAULT";
    const apiUrl = process.env.FAMGATEWAY_API_URL || "https://api.famgateway.com/v1";

    let paymentSessionUrl = "";
    let upiIntentString = "";
    let famgatewayOrderId = `FG_${Date.now()}_${Math.floor(Math.random() * 1000)}`;

    const isLiveGatewayConfigured =
      apiKey &&
      apiKey !== "fg_live_sample_apikey_123456" &&
      !apiKey.includes("sample");

    if (isLiveGatewayConfigured) {
      try {
        const fgResponse = await fetch(`${apiUrl}/orders/create`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${apiKey}`,
            "X-Merchant-Id": merchantId,
          },
          body: JSON.stringify({
            order_id: orderId,
            amount: parseFloat(amountRupees),
            currency: "INR",
            customer_name: customerName || "Customer",
            customer_phone: customerPhone,
            description: `Payment for order ${orderId}`,
            webhook_url: webhookUrl,
            callback_url: `qwenton://payment/callback?order_id=${orderId}`,
          }),
        });

        if (fgResponse.ok) {
          const fgData = await fgResponse.json();
          famgatewayOrderId = fgData.id || fgData.order_id || famgatewayOrderId;
          paymentSessionUrl = fgData.payment_url || fgData.checkout_url || "";
          upiIntentString = fgData.upi_intent || "";
        } else {
          console.warn("[FamGateway] Live API returned non-200, generating standard UPI intent:", await fgResponse.text());
        }
      } catch (apiError) {
        console.error("[FamGateway] API request error:", apiError);
      }
    }

    // Standard Fallback UPI Intent Deep Link for seamless Indian mobile checkout
    // Compatible with PhonePe, Google Pay, Paytm, BHIM, and Cred
    const payeeVpa = process.env.FAMGATEWAY_DEFAULT_VPA || "famgateway@icici";
    const payeeName = "Qwenton CommerceOps";
    const note = encodeURIComponent(`Order ${orderId}`);
    
    if (!upiIntentString) {
      upiIntentString = `upi://pay?pa=${payeeVpa}&pn=${encodeURIComponent(
        payeeName
      )}&am=${amountRupees}&cu=INR&tn=${note}&tr=${orderId}`;
    }

    if (!paymentSessionUrl) {
      paymentSessionUrl = `${host}/pay?orderId=${encodeURIComponent(
        orderId
      )}&amount=${amountRupees}&phone=${encodeURIComponent(customerPhone)}`;
    }

    // Persist FamGateway order reference to Firestore if adminDb is available
    if (adminDb) {
      try {
        const orderRef = adminDb.collection("orders").doc(orderId);
        await orderRef.set(
          {
            famgatewayOrderId,
            famgatewayAmountMinor: amountMinor,
            famgatewayStatus: "initiated",
            famgatewayCreatedAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          },
          { merge: true }
        );
      } catch (dbError) {
        console.warn("[Firestore] Could not update famgatewayOrderId:", dbError);
      }
    }

    return NextResponse.json({
      success: true,
      orderId,
      famgatewayOrderId,
      amountRupees: parseFloat(amountRupees),
      amountMinor,
      upiIntent: upiIntentString,
      paymentUrl: paymentSessionUrl,
      webhookConfigured: webhookUrl,
    });
  } catch (error: any) {
    console.error("[FamGateway Create Order] Error:", error);
    return NextResponse.json(
      { error: "Internal server error creating payment order", details: error?.message },
      { status: 500 }
    );
  }
}
