const { createPaymentUrl, verifyReturnUrl } =
  require("../services/vnpay.service");

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

module.exports = {
  createPayment,
  vnpayReturn,
  vnpayIPN,
};