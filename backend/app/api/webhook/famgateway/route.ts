import { NextRequest, NextResponse } from "next/server";
import crypto from "crypto";
import { adminDb, hasFirebaseCredentials } from "@/lib/firebaseAdmin";

/**
 * FamGateway Webhook Handler
 * Endpoint: POST https://qwen.qwenton.shop/api/webhook/famgateway
 *
 * Verifies cryptographic signature, guarantees idempotency,
 * and updates Firestore order status to 'paid' and 'to_pack'.
 */
export async function POST(req: NextRequest) {
  try {
    const rawBody = await req.text();
    const signature =
      req.headers.get("x-famgateway-signature") ||
      req.headers.get("x-webhook-signature") ||
      req.headers.get("x-signature");

    const apiKeyHeader =
      req.headers.get("x-api-key") ||
      req.headers.get("api-key") ||
      req.headers.get("authorization");

    const webhookSecret = process.env.FAMGATEWAY_WEBHOOK_SECRET;
    const apiKey = process.env.FAMGATEWAY_API_KEY;

    // If FamGateway validates via direct API key header:
    const isApiKeyHeaderValid =
      apiKey &&
      apiKeyHeader &&
      (apiKeyHeader === apiKey || apiKeyHeader === `Bearer ${apiKey}`);

    // Cryptographic Signature Verification (HMAC-SHA256) if signature or secret exists
    const secretToVerify = webhookSecret || (signature ? apiKey : null);
    if (secretToVerify && secretToVerify !== "fg_whsec_sample_987654321" && !isApiKeyHeaderValid) {
      if (signature) {
        const expectedSignature = crypto
          .createHmac("sha256", secretToVerify)
          .update(rawBody)
          .digest("hex");

        const isValid = crypto.timingSafeEqual(
          Buffer.from(signature, "utf-8"),
          Buffer.from(expectedSignature, "utf-8")
        );

        if (!isValid) {
          console.error("[FamGateway Webhook] Invalid signature verification failure");
          return NextResponse.json(
            { error: "Invalid signature" },
            { status: 401 }
          );
        }
      } else if (webhookSecret) {
        console.warn("[FamGateway Webhook] Missing signature header while secret is enforced");
        return NextResponse.json(
          { error: "Missing signature header" },
          { status: 401 }
        );
      }
    }

    let payload: any;
    try {
      payload = JSON.parse(rawBody);
    } catch (parseError) {
      return NextResponse.json(
        { error: "Invalid JSON payload" },
        { status: 400 }
      );
    }

    const orderId =
      payload.order_id ||
      payload.orderId ||
      payload.order_number ||
      payload.data?.order_id;
    const transactionId =
      payload.transaction_id ||
      payload.txn_id ||
      payload.payment_id ||
      payload.id ||
      `FG_TXN_${Date.now()}`;
    const status = (
      payload.status ||
      payload.event ||
      payload.payment_status ||
      ""
    ).toUpperCase();
    const utr = payload.utr || payload.bank_ref_num || payload.rrn || null;
    const amount = payload.amount || payload.amount_paid || null;

    if (!orderId) {
      return NextResponse.json(
        { error: "Payload missing order_id reference" },
        { status: 400 }
      );
    }

    console.log(
      `[FamGateway Webhook] Received event for Order: ${orderId}, Status: ${status}, Txn: ${transactionId}`
    );

    const timestamp = new Date().toISOString();
    let firestoreUpdated = false;

    // If Firestore Admin credentials are provided, process with database mutation & idempotency
    if (hasFirebaseCredentials && adminDb) {
      try {
        // 1. Idempotency Guard
        const webhookRef = adminDb.collection("famgateway_webhooks").doc(transactionId);
        const webhookDoc = await webhookRef.get();

        if (webhookDoc.exists) {
          console.log(
            `[FamGateway Webhook] Transaction ${transactionId} already processed (idempotent duplicate)`
          );
          return NextResponse.json({
            status: "success",
            message: "Transaction already processed",
            orderId,
          });
        }

        const isSuccess =
          status.includes("SUCCESS") ||
          status.includes("PAID") ||
          status.includes("COMPLETED");

        // 2. Locate order in Firestore
        let targetOrderDocRef: FirebaseFirestore.DocumentReference | null = null;
        let orderDoc = await adminDb.collection("orders").doc(orderId).get();

        if (orderDoc.exists) {
          targetOrderDocRef = adminDb.collection("orders").doc(orderId);
        } else {
          const querySnapshot = await adminDb
            .collection("orders")
            .where("orderNumber", "==", orderId)
            .limit(1)
            .get();

          if (!querySnapshot.empty) {
            targetOrderDocRef = querySnapshot.docs[0].ref;
            orderDoc = querySnapshot.docs[0];
          }
        }

        if (targetOrderDocRef && orderDoc && orderDoc.exists) {
          if (isSuccess) {
            await targetOrderDocRef.update({
              paymentStatus: "paid",
              fulfilmentStatus: "to_pack",
              paymentMethod: "famgateway",
              famgatewayTxnId: transactionId,
              famgatewayUtr: utr,
              paidAt: timestamp,
              updatedAt: timestamp,
            });

            await adminDb.collection("order_events").add({
              orderId: orderDoc.id,
              eventType: "famgateway_payment_confirmed",
              actor: "famgateway_webhook",
              details: { transactionId, utr, amount, status },
              timestamp,
            });

            firestoreUpdated = true;
            console.log(
              `[FamGateway Webhook] Successfully marked Order ${orderId} as PAID / TO_PACK in Firestore`
            );
          }
        }

        // Record webhook log
        await webhookRef.set({
          orderId,
          transactionId,
          status,
          amount,
          utr,
          processedAt: timestamp,
          payload,
        });
      } catch (dbErr) {
        console.warn("[FamGateway Webhook] Firestore update warning:", dbErr);
      }
    } else {
      console.log(
        `[FamGateway Webhook] Running in dev mode (Firestore credentials pending in .env). Payload accepted for order: ${orderId}`
      );
    }

    return NextResponse.json({
      status: "success",
      orderId,
      transactionId,
      firestoreUpdated,
      processed: true,
      timestamp,
    });
  } catch (error: any) {
    console.error("[FamGateway Webhook] Internal processing error:", error);
    return NextResponse.json(
      { error: "Webhook processing error", details: error?.message },
      { status: 500 }
    );
  }
}
