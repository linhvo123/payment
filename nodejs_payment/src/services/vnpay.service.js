const crypto = require("crypto");
const moment = require("moment");
const qs = require("qs");

const createPaymentUrl = ({ amount, ipAddr }) => {
  const tmnCode = process.env.VNP_TMNCODE;
  const secretKey = process.env.VNP_HASHSECRET;
  const vnpUrl = process.env.VNP_URL;

  const createDate = moment().format("YYYYMMDDHHmmss");
  const orderId = moment().format("DDHHmmss");

  let vnpParams = {
    vnp_Version: "2.1.0",
    vnp_Command: "pay",
    vnp_TmnCode: tmnCode,
    vnp_Locale: "vn",
    vnp_CurrCode: "VND",

    vnp_TxnRef: orderId,
    vnp_OrderInfo: `Thanh toan don hang ${orderId}`,
    vnp_OrderType: "other",

    vnp_Amount: amount * 100,

    vnp_ReturnUrl: process.env.VNP_RETURN_URL,

    vnp_IpAddr: ipAddr,

    vnp_CreateDate: createDate,
  };

  vnpParams = Object.keys(vnpParams)
    .sort()
    .reduce((result, key) => {
      result[key] = vnpParams[key];
      return result;
    }, {});

  const signData = qs.stringify(vnpParams, {
    encode: false,
  });

  const signed = crypto
    .createHmac("sha512", secretKey)
    .update(Buffer.from(signData, "utf-8"))
    .digest("hex");

  vnpParams["vnp_SecureHash"] = signed;

  return (
    vnpUrl +
    "?" +
    qs.stringify(vnpParams, {
      encode: false,
    })
  );
};

module.exports = {
  createPaymentUrl,
};