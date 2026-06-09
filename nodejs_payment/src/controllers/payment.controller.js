const { createPaymentUrl, verifyReturnUrl } =
  require("../services/vnpay.service");
const {
  createPaymentUrl: createMomoPaymentUrl,
  verifyCallback: verifyMomoCallback,
} = require("../services/momo.service");

const createPayment = async (req, res) => {
  try {
    const { amount, appReturnUrl } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: "Invalid amount",
      });
    }

    const ipAddr =
      req.headers["x-forwarded-for"]?.split(",")[0]?.trim() ||
      req.socket.remoteAddress ||
      "127.0.0.1";

    const paymentUrl = createPaymentUrl({
      amount,
      ipAddr,
      appReturnUrl,
    });

    return res.json({
      success: true,
      paymentUrl,
    });
  } catch (error) {
    console.error("createPayment error:", error);
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * VNPay Return URL handler (GET)
 * Verifies signature, then 302 redirects to Flutter app with result
 */
const vnpayReturn = async (req, res) => {
  try {
    console.log("=== VNPay Return Called ===");

    const { returnAppUrl, ...vnpParams } = req.query;
    const result = verifyReturnUrl(vnpParams);

    const resultJson = JSON.stringify(result);
    const encoded = encodeURIComponent(resultJson);

    if (returnAppUrl) {
      // Redirect to Flutter app with result in query param
      return res.redirect(
        302,
        `${returnAppUrl}?vnpay_result=${encoded}`
      );
    }

    // No Flutter URL — just return JSON (fallback)
    return res.json(result);
  } catch (error) {
    console.error("vnpayReturn error:", error);

    // Try redirect even on error
    const { returnAppUrl } = req.query;
    if (returnAppUrl) {
      const errJson = JSON.stringify({
        success: false,
        message: error.message,
      });
      return res.redirect(
        302,
        `${returnAppUrl}?vnpay_result=${encodeURIComponent(errJson)}`
      );
    }

    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * VNPay IPN (Instant Payment Notification) handler (GET)
 * VNPay sends server-to-server notification here
 */
const vnpayIPN = async (req, res) => {
  try {
    console.log("=== VNPay IPN Called ===");
    console.log("Query params:", req.query);

    const result = verifyReturnUrl(req.query);

    if (result.success) {
      // Process the payment result (update database, etc.)
      console.log("IPN verified successfully:", result.data);

      // Return success to VNPay so it stops retrying
      return res.json({
        RspCode: "00",
        Message: "Confirm Success",
      });
    } else {
      console.error("IPN signature verification failed");
      return res.json({
        RspCode: "97",
        Message: "Invalid signature",
      });
    }
  } catch (error) {
    console.error("vnpayIPN error:", error);

    return res.json({
      RspCode: "99",
      Message: "Unknown error",
    });
  }
};

// ─── MoMo Payment ────────────────────────────────────────────────

/**
 * Create MoMo payment URL
 */
const createMomoPayment = async (req, res) => {
  try {
    const { amount: rawAmount, orderInfo, appReturnUrl } = req.body;

    // Ensure amount is a positive integer
    const amount = parseInt(rawAmount, 10);
    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: "Invalid amount",
      });
    }

    // IPN URL is for server-to-server notification (POST)
    // Redirect URL is where MoMo redirects the user's browser (GET)
    const baseUrl = process.env.MOMO_RETURN_BASE_URL || 'https://payment-1-3sh3.onrender.com';
    const redirectUrl = `${baseUrl}/api/payments/momo-return`;
    const ipnUrl = `${baseUrl}/api/payments/momo-ipn`;

    const result = await createMomoPaymentUrl({
      amount,
      orderInfo: orderInfo || `Thanh toan don hang`,
      appReturnUrl: appReturnUrl || "",
      redirectUrl,
      ipnUrl,
    });

    return res.json({
      success: true,
      payUrl: result.payUrl,
      qrCodeUrl: result.qrCodeUrl,
      deeplink: result.deeplink,
      orderId: result.orderId,
      requestId: result.requestId,
    });
  } catch (error) {
    console.error("createMomoPayment error:", error.message);
    console.error("createMomoPayment stack:", error.stack);
    return res.status(500).json({
      success: false,
      message: error.message || "Internal server error",
      details: error.stack?.split("\n")[0] || "",
    });
  }
};

/**
 * MoMo IPN (Instant Payment Notification) handler (POST)
 * MoMo sends server-to-server notification here after payment
 */
const momoIPN = async (req, res) => {
  try {
    console.log("=== MoMo IPN Called ===");
    console.log("Body:", req.body);

    const result = verifyMomoCallback(req.body);

    if (result.success) {
      console.log("MoMo IPN verified successfully:", result.data);

      // If there's an appReturnUrl embedded in extraData, trigger redirect logic
      if (result.appReturnUrl) {
        console.log("App return URL decoded:", result.appReturnUrl);
      }

      // Return success to MoMo
      return res.status(200).json({
        status: 0,
        message: "Success",
        data: result.data,
      });
    } else {
      console.error("MoMo IPN verification failed:", result.message);
      return res.status(200).json({
        status: 10,
        message: result.message,
      });
    }
  } catch (error) {
    console.error("momoIPN error:", error);
    return res.status(500).json({
      status: 99,
      message: "Unknown error",
    });
  }
};

/**
 * MoMo Return URL handler (GET)
 * MoMo redirects user here after payment via GET
 * We verify the signature and redirect to Flutter app
 */
const momoReturn = async (req, res) => {
  try {
    // If this request already has momo_result, it's the WebView intercepting
    // the redirect. Return a simple HTML that does nothing.
    if (req.query.momo_result) {
      return res.send(`
        <!DOCTYPE html>
        <html><body><p>Redirecting...</p></body></html>
      `);
    }

    console.log("=== MoMo Return Called ===");
    console.log("Query params:", req.query);

    const result = verifyMomoCallback(req.query);

    const resultJson = JSON.stringify(result);
    const encoded = encodeURIComponent(resultJson);

    // Decode appReturnUrl from extraData to redirect to Flutter
    if (result.appReturnUrl) {
      return res.redirect(
        302,
        `${result.appReturnUrl}?momo_result=${encoded}`
      );
    }

    // Check for explicit returnAppUrl in query
    const { returnAppUrl } = req.query;
    if (returnAppUrl) {
      return res.redirect(
        302,
        `${returnAppUrl}?momo_result=${encoded}`
      );
    }

    // Fallback: return JSON
    return res.json(result);
  } catch (error) {
    console.error("momoReturn error:", error);

    const { returnAppUrl } = req.query;
    if (returnAppUrl) {
      const errJson = JSON.stringify({
        success: false,
        message: error.message,
      });
      return res.redirect(
        302,
        `${returnAppUrl}?momo_result=${encodeURIComponent(errJson)}`
      );
    }

    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * Debug endpoint: test MoMo API connectivity
 * Sends a minimal request to MoMo and returns the raw response
 */
const momoDebug = async (req, res) => {
  try {
    const { amount } = req.body;
    const testAmount = amount || 10000;

    const https = require("https");
    const postData = JSON.stringify({
      partnerCode: "MOMO",
      accessKey: "F8B6IOfmWI96orwY",
      requestId: `${Date.now()}_test`,
      amount: String(testAmount),
      orderId: `DEBUG_${Date.now()}`,
      orderInfo: "Debug test",
      redirectUrl: "https://payment-1-3sh3.onrender.com/api/payments/momo-return",
      ipnUrl: "https://payment-1-3sh3.onrender.com/api/payments/momo-ipn",
      extraData: "",
      requestType: "captureWallet",
      signature: "test",
      lang: "vi",
    });

    const result = await new Promise((resolve, reject) => {
      const parsedUrl = new URL("https://test-payment.momo.vn/v3/gateway/api/create");
      const options = {
        hostname: parsedUrl.hostname,
        port: 443,
        path: parsedUrl.pathname,
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(postData),
        },
        timeout: 10000,
      };

      const req = https.request(options, (httpRes) => {
        let data = "";
        httpRes.on("data", (chunk) => (data += chunk));
        httpRes.on("end", () => {
          resolve({
            statusCode: httpRes.statusCode,
            headers: httpRes.headers,
            body: data,
          });
        });
      });

      req.on("timeout", () => { req.destroy(); reject(new Error("timeout")); });
      req.on("error", (e) => reject(e));
      req.write(postData);
      req.end();
    });

    return res.json(result);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

module.exports = {
  createPayment,
  vnpayReturn,
  vnpayIPN,
  createMomoPayment,
  momoIPN,
  momoReturn,
  momoDebug,
};