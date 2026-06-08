// Payment service to handle payment logic

const createPayment = async ({ amount, method }) => {
  switch (method) {
    case "momo":
      return {
        success: true,
        paymentUrl:
          "https://test-payment-url.com/momo",
        amount,
      };

    case "vnpay":
      return {
        success: true,
        paymentUrl:
          "https://test-payment-url.com/vnpay",
        amount,
      };

    case "bank":
      return {
        success: true,
        paymentUrl:
          "https://test-payment-url.com/bank",
        amount,
      };

    default:
      throw new Error("Unsupported payment method");
  }
};

module.exports = {
  createPayment,
};