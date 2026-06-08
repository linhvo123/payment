const express = require("express");
const cors = require("cors");

const paymentRoutes = require("./routes/payment.routes");

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use("/api/payments", paymentRoutes);

// Health check
app.get("/", (req, res) => {
  res.json({ message: "Payment API is running" });
});

module.exports = app;
