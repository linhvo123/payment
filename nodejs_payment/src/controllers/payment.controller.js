const { createPaymentUrl } =
  require("../services/vnpay.service");

const createPayment = async (req, res) => {
  try {
    const { amount } = req.body;

    const paymentUrl =
      createPaymentUrl({
        amount,
        ipAddr:
          req.headers["x-forwarded-for"] ||
          req.socket.remoteAddress,
      });

    return res.json({
      success: true,
      paymentUrl,
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

module.exports = {
  createPayment,
};