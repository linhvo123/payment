const crypto = require("crypto");
const https = require("https");
const http = require("http");

const MOMO_CONFIG = {
  partnerCode: "MOMO",
  accessKey: "F8B6IOfmWI96orwY",
  secretKey: "v779836144r889475613010759404394",
  endpoint: "https://test-payment.momo.vn/v3/gateway/api/create",
};

/**
 * Generate a unique request ID
 */
const generateRequestId = () => {
  return `${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
};

/**
 * Generate a unique order ID
 */
const generateOrderId = () => {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, "0");
  const d = String(now.getDate()).padStart(2, "0");
  const h = String(now.getHours()).padStart(2, "0");
  const min = String(now.getMinutes()).padStart(2, "0");
  const s = String(now.getSeconds()).padStart(2, "0");
  const ms = String(now.getMilliseconds()).padStart(3, "0");
  return `MM${y}${m}${d}${h}${min}${s}${ms}`;
};

/**
 * Create HMAC-SHA256 signature for MoMo
 *
 * MoMo signature format:
 * accessKey=<accessKey>&amount=<amount>&extraData=<extraData>
 * &ipnUrl=<ipnUrl>&orderId=<orderId>&orderInfo=<orderInfo>
 * &partnerCode=<partnerCode>&redirectUrl=<redirectUrl>
 * &requestId=<requestId>&requestType=<requestType>
 */
const createSignature = (rawSignature) => {
  return crypto
    .createHmac("sha256", MOMO_CONFIG.secretKey)
    .update(rawSignature, "utf-8")
    .digest("hex");
};

/**
 * Make HTTPS POST request to MoMo API
 * MoMo v3 uses HTTP Basic Auth (accessKey:secretKey)
 */
const postToMomo = (url, body, authHeader) => {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(body);
    const parsedUrl = new URL(url);

    const headers = {
      "Content-Type": "application/json",
      "Content-Length": Buffer.byteLength(postData),
    };

    // Add Basic Auth if provided
    if (authHeader) {
      headers["Authorization"] = authHeader;
    }

    const options = {
      hostname: parsedUrl.hostname,
      port: parsedUrl.port || 443,
      path: parsedUrl.pathname + parsedUrl.search,
      method: "POST",
      headers,
      timeout: 15000,
    };

    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        console.log("MoMo response status:", res.statusCode);
        console.log("MoMo response body:", data.substring(0, 500));
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          resolve({ raw: data, httpStatus: res.statusCode });
        }
      });
    });

    req.on("timeout", () => {
      req.destroy();
      reject(new Error("MoMo API timeout after 15s"));
    });

    req.on("error", (e) => {
      console.error("MoMo request error:", e.message);
      reject(new Error(`Cannot connect to MoMo: ${e.message}`));
    });

    req.write(postData);
    req.end();
  });
};

/**
 * Create MoMo payment request (v3 API - uses HTTP Basic Auth)
 *
 * @param {Object} params
 * @param {number} params.amount - Payment amount in VND
 * @param {string} params.orderInfo - Order description
 * @param {string} params.appReturnUrl - URL to redirect Flutter app after payment
 * @param {string} params.redirectUrl - MoMo redirect URL
 * @param {string} params.ipnUrl - IPN URL for server notification
 */
const createPaymentUrl = async ({ amount, orderInfo, appReturnUrl, redirectUrl, ipnUrl }) => {
  const requestId = generateRequestId();
  const orderId = generateOrderId();
  const extraData = appReturnUrl ? Buffer.from(appReturnUrl).toString("base64") : "";

  // Build Basic Auth header: base64(accessKey:secretKey)
  const authHeader = "Basic " + Buffer.from(
    `${MOMO_CONFIG.accessKey}:${MOMO_CONFIG.secretKey}`
  ).toString("base64");

  // Build raw signature string + HMAC-SHA256 (for v2 compatibility, some v3 need this too)
  const rawSignature =
    `accessKey=${MOMO_CONFIG.accessKey}` +
    `&amount=${amount}` +
    `&extraData=${extraData}` +
    `&ipnUrl=${ipnUrl}` +
    `&orderId=${orderId}` +
    `&orderInfo=${orderInfo}` +
    `&partnerCode=${MOMO_CONFIG.partnerCode}` +
    `&redirectUrl=${redirectUrl}` +
    `&requestId=${requestId}` +
    `&requestType=captureWallet`;

  const signature = createSignature(rawSignature);

  const requestBody = {
    partnerCode: MOMO_CONFIG.partnerCode,
    accessKey: MOMO_CONFIG.accessKey,
    requestId: requestId,
    amount: amount.toString(),
    orderId: orderId,
    orderInfo: orderInfo,
    redirectUrl: redirectUrl,
    ipnUrl: ipnUrl,
    extraData: extraData,
    requestType: "captureWallet",
    signature: signature,
    lang: "vi",
  };

  console.log("=== MoMo Payment Request ===");
  console.log("URL:", MOMO_CONFIG.endpoint);
  console.log("Auth: Basic ***");
  console.log("Signature:", signature);
  console.log("Request Body:", JSON.stringify(requestBody, null, 2));

  const response = await postToMomo(MOMO_CONFIG.endpoint, requestBody, authHeader);

  console.log("=== MoMo Response ===");
  console.log("RAW:", JSON.stringify(response));

  // MoMo v3 response: try multiple possible formats
  const resultCode = response.resultCode ?? response.status ?? response.errorCode;
  const payUrl = response.payUrl ?? response.payurl ?? response.data?.payUrl;
  const msg = response.message ?? response.errorMessage ?? response.description ?? "";

  if (resultCode === 0 || resultCode === "0" || resultCode === 200) {
    return {
      success: true,
      payUrl: payUrl,
      qrCodeUrl: response.qrCodeUrl ?? response.data?.qrCodeUrl,
      deeplink: response.deeplink ?? response.deeplinkUrl ?? response.data?.deeplink,
      requestId: requestId,
      orderId: orderId,
      amount: amount,
    };
  } else {
    // Throw with full response for debugging
    const err = new Error(msg || `MoMo error (code: ${resultCode})`);
    err.momoResponse = response;
    throw err;
  }
};

/**
 * Verify MoMo IPN / Return callback signature
 *
 * MoMo sends the following params in the callback:
 * partnerCode, accessKey, requestId, orderId, amount, orderInfo,
 * orderType, transId, message, localMessage, responseTime,
 * errorCode (or resultCode), payType, extraData, signature
 */
const verifyCallback = (params) => {
  const {
    partnerCode,
    accessKey,
    requestId,
    orderId,
    amount,
    orderInfo,
    orderType,
    transId,
    resultCode,
    errorCode,
    message,
    localMessage,
    payType,
    responseTime,
    extraData,
    signature: receivedSignature,
  } = params;

  // MoMo uses errorCode in some versions, resultCode in others
  const code = resultCode || errorCode || "";

  if (!receivedSignature) {
    return { success: false, message: "Missing signature" };
  }

  // Build raw signature string for verification (alphabetical order)
  // Include all fields that MoMo includes in signature
  const rawSignature =
    `accessKey=${accessKey || ""}` +
    `&amount=${amount || ""}` +
    `&extraData=${extraData || ""}` +
    `&message=${message || ""}` +
    `&orderId=${orderId || ""}` +
    `&orderInfo=${orderInfo || ""}` +
    `&orderType=${orderType || ""}` +
    `&partnerCode=${partnerCode || ""}` +
    `&payType=${payType || ""}` +
    `&requestId=${requestId || ""}` +
    `&responseTime=${responseTime || ""}` +
    `&resultCode=${code}` +
    `&transId=${transId || ""}`;

  const computedSignature = createSignature(rawSignature);

  console.log("=== MoMo Callback Verification ===");
  console.log("Raw Signature:", rawSignature);
  console.log("Received Signature:", receivedSignature);
  console.log("Computed Signature:", computedSignature);
  console.log("Match:", computedSignature === receivedSignature);

  const isValid = computedSignature === receivedSignature;

  // Decode extraData (contains appReturnUrl) if present
  let appReturnUrl = null;
  if (extraData) {
    try {
      appReturnUrl = Buffer.from(extraData, "base64").toString("utf-8");
    } catch (e) {
      console.error("Failed to decode extraData:", e.message);
    }
  }

  const isSuccess = code === "0" || code === 0;

  return {
    success: isValid && isSuccess,
    message: isSuccess
      ? "Payment successful"
      : message || `Payment failed (code: ${code})`,
    isValidSignature: isValid,
    data: {
      txnRef: orderId,
      amount: amount,
      orderInfo: orderInfo,
      responseCode: code,
      transactionNo: transId,
      payType: payType,
      responseTime: responseTime,
      message: message,
    },
    appReturnUrl,
  };
};

module.exports = {
  createPaymentUrl,
  verifyCallback,
  MOMO_CONFIG,
};
