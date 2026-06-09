const express = require("express");
const router = express.Router();

const paymentController = require("../controllers/payment.controller");

// Create payment URL
router.post("/create", paymentController.createPayment);

// VNPay return URL (user is redirected here after payment)
router.get("/vnpay-return", paymentController.vnpayReturn);

// VNPay IPN (server-to-server notification)
router.get("/vnpay-ipn", paymentController.vnpayIPN);

module.exports = router;