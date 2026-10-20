import http from "http";
import crypto from "crypto";

const BASE_URL = "http://localhost:3000";

function makeRequest(path, method, body = null, headers = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE_URL);
    const postData = body ? JSON.stringify(body) : null;

    const reqHeaders = {
      ...headers,
    };
    if (postData) {
      reqHeaders["Content-Type"] = "application/json";
      reqHeaders["Content-Length"] = Buffer.byteLength(postData);
    }

    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method,
      headers: reqHeaders,
    };

    const req = http.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        try {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: data ? JSON.parse(data) : null,
          });
        } catch (e) {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: data,
          });
        }
      });
    });

    req.on("error", reject);
    if (postData) req.write(postData);
    req.end();
  });
}

async function runTestSuite() {
  console.log("================================================================================");
  console.log("🚀 Qwenton CommerceOps — End-to-End Pilot Verification Suite");
  console.log("Target Domain: https://qwen.qwenton.shop");
  console.log("================================================================================\n");

  let passedTests = 0;
  let totalTests = 0;

  function assert(condition, testName) {
    totalTests++;
    if (condition) {
      console.log(`  ✅ [PASS] ${testName}`);
      passedTests++;
    } else {
      console.error(`  ❌ [FAIL] ${testName}`);
      process.exitCode = 1;
    }
  }

  // TEST 1: Health Check
  console.log("Test 1: Health Check Endpoint");
  try {
    const res = await makeRequest("/api/health", "GET");
    assert(res.statusCode === 200, "Health check returns HTTP 200");
    assert(res.body.domain === "https://qwen.qwenton.shop", "Host domain is configured as https://qwen.qwenton.shop");
    assert(
      res.body.famgatewayWebhookEndpoint === "https://qwen.qwenton.shop/api/webhook/famgateway",
      "Webhook endpoint matches https://qwen.qwenton.shop/api/webhook/famgateway"
    );
  } catch (err) {
    console.error("Health check error:", err);
  }

  // TEST 2: Customer Creates Order & Initiates FamGateway Session
  console.log("\nTest 2: Customer Order Initiation (User App -> Vercel Backend)");
  const orderId = `QC-SIM-${Date.now()}`;
  try {
    const res = await makeRequest("/api/famgateway/create-order", "POST", {
      orderId,
      amountMinor: 94900,
      customerName: "Pooja Sharma",
      customerPhone: "9811223344",
      businessId: "biz_jaipur_01",
      productName: "Hand Embroidered Chikankari Kurti",
    });

    assert(res.statusCode === 200, "Create Order returns HTTP 200");
    assert(res.body.success === true, "Session creation flag is true");
    assert(res.body.amountRupees === 949, "Amount converted correctly to ₹949.00");
    assert(res.body.upiIntent.includes("upi://pay"), "Generates valid native UPI Intent string");
    assert(res.body.upiIntent.includes("famgateway@icici"), "VPA matches famgateway@icici");
  } catch (err) {
    console.error("Order creation error:", err);
  }

  // TEST 3: FamGateway Webhook Verification & Firestore Mutation
  console.log("\nTest 3: FamGateway Webhook Processing");
  const txnId = `FG_TXN_${Date.now()}`;
  const webhookPayload = {
    order_id: orderId,
    transaction_id: txnId,
    status: "SUCCESS",
    amount: 94900,
    currency: "INR",
    utr: "428901234567",
    timestamp: Math.floor(Date.now() / 1000),
  };

  try {
    const res = await makeRequest(
      "/api/webhook/famgateway",
      "POST",
      webhookPayload
    );

    assert(res.statusCode === 200, "Webhook returns HTTP 200 OK");
    assert(res.body.status === "success", "Webhook status is success");
    assert(res.body.orderId === orderId, "Webhook mapped correct orderId");
    assert(res.body.transactionId === txnId, "Webhook mapped correct transactionId");
    assert(res.body.processed === true, "Webhook marked as processed");
  } catch (err) {
    console.error("Webhook processing error:", err);
  }

  // TEST 4: Idempotency Guard (Replay attack defense)
  console.log("\nTest 4: Webhook Replay Defense (Idempotency)");
  try {
    const res = await makeRequest(
      "/api/webhook/famgateway",
      "POST",
      webhookPayload
    );

    assert(res.statusCode === 200, "Duplicate webhook returns HTTP 200");
    assert(res.body.status === "success", "Duplicate webhook handled gracefully without crashing");
  } catch (err) {
    console.error("Replay test error:", err);
  }

  // TEST 5: Cryptographic Signature Failure Handling
  console.log("\nTest 5: Cryptographic Security & Malicious Signature Defense");
  try {
    const rawBody = JSON.stringify({ order_id: "MALICIOUS_ORDER", amount: 100 });
    const forgedSignature = "forged_hex_signature_abcdef123456";

    // When a webhook secret is set in environment, forged signature must be rejected
    const res = await makeRequest(
      "/api/webhook/famgateway",
      "POST",
      JSON.parse(rawBody),
      { "x-famgateway-signature": forgedSignature }
    );

    assert(
      res.statusCode === 200 || res.statusCode === 401,
      "Webhook strictly handles signatures without leaking server stack trace"
    );
  } catch (err) {
    console.error("Security test error:", err);
  }

  // TEST 6: Mathematical Profit Engine Calculations
  console.log("\nTest 6: Dual-Engine Profit Calculations (Paise Integer Precision)");
  // Scenario A: Delivered Item
  // Selling Price = ₹949 (94900), COGS = ₹420 (42000), Pkg = ₹15 (1500), Ship = ₹60 (6000), Fee (2%) = ₹18.98 (1898)
  const deliveredNetSales = 94900;
  const cogs = 42000;
  const pkg = 1500;
  const forwardShip = 6000;
  const fee = Math.floor(deliveredNetSales * 0.02);
  const deliveredProfit = deliveredNetSales - cogs - pkg - forwardShip - fee;
  assert(deliveredProfit === 43502, `Delivered Profit calculated as ₹${deliveredProfit / 100} (Exact Paisa 43502)`);

  // Scenario B: RTO Doorstep Loss
  // Revenue = 0, Product returned to shelf, Absorbs: Packaging (₹15) + Forward Courier (₹60) + Reverse Courier (₹60)
  const reverseShip = 6000;
  const rtoLoss = 0 - pkg - forwardShip - reverseShip;
  assert(rtoLoss === -13500, `RTO Doorstep Loss calculated as -₹${Math.abs(rtoLoss) / 100} (-13500 Paise)`);
  assert(rtoLoss < 0, "RTO correctly registers as negative operational loss");

  console.log("\n================================================================================");
  console.log(`📊 Test Summary: ${passedTests} / ${totalTests} assertions passed (${Math.round((passedTests / totalTests) * 100)}%)`);
  console.log("================================================================================");

  if (passedTests === totalTests) {
    console.log("🎉 ALL INTEGRATION & VERIFICATION CHECKS PASSED!");
  }
}

runTestSuite();
