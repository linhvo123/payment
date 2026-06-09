const express = require("express");
const router = express.Router();

const paymentController = require("../controllers/payment.controller");

// Create VNPay payment URL
router.post("/create", paymentController.createPayment);

// VNPay return URL (user is redirected here after payment)
router.get("/vnpay-return", paymentController.vnpayReturn);

// VNPay IPN (server-to-server notification)
router.get("/vnpay-ipn", paymentController.vnpayIPN);

// ─── MoMo Routes ─────────────────────────────

// Create MoMo payment URL
router.post("/create-momo", paymentController.createMomoPayment);

// MoMo IPN (server-to-server notification from MoMo)
router.post("/momo-ipn", paymentController.momoIPN);

// MoMo Return URL (user is redirected here after payment)
router.get("/momo-return", paymentController.momoReturn);

module.exports = router;