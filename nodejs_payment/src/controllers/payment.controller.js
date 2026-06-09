const { createPaymentUrl, verifyReturnUrl } =
  require("../services/vnpay.service");

const createPayment = async (req, res) => {
  try {
    const { amount } = req.body;

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
 * VNPay redirects user here after payment
 */
const vnpayReturn = async (req, res) => {
  try {
    console.log("=== VNPay Return Called ===");
    console.log("Query params:", req.query);

    const result = verifyReturnUrl(req.query);

    if (result.success && result.data.responseCode === "00") {
      // Payment successful
      return res.json({
        success: true,
        message: "Payment successful",
        data: result.data,
      });
    } else if (result.success && result.data.responseCode !== "00") {
      // Payment failed or cancelled
      return res.json({
        success: false,
        message: `Payment failed with code: ${result.data.responseCode}`,
        data: result.data,
      });
    } else {
      // Signature invalid
      return res.status(400).json({
        success: false,
        message: result.message,
      });
    }
  } catch (error) {
    console.error("vnpayReturn error:", error);

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