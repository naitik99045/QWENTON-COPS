import { NextResponse } from "next/server";

export async function GET() {
  return NextResponse.json({
    status: "ok",
    service: "Qwenton CommerceOps Vercel Backend",
    domain: process.env.NEXT_PUBLIC_BASE_URL || "https://qwen.qwenton.shop",
    famgatewayWebhookEndpoint: `${
      process.env.NEXT_PUBLIC_BASE_URL || "https://qwen.qwenton.shop"
    }/api/webhook/famgateway`,
    firebaseProject: process.env.FIREBASE_PROJECT_ID || "qwenton-reelmarket",
    timestamp: new Date().toISOString(),
  });
}
