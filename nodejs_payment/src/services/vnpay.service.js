const crypto = require("crypto");
const moment = require("moment");

/**
 * PHP-compatible urlencode (spaces → +)
 * VNPay uses PHP's urlencode for hash data
 */
const phpUrlEncode = (str) => {
  return encodeURIComponent(String(str))
    .replace(/%20/g, "+");
};

/**
 * Sort object by key alphabetically
 */
const sortObject = (obj) => {
  const sorted = {};
  const keys = Object.keys(obj).sort();
  for (const key of keys) {
    sorted[key] = obj[key];
  }
  return sorted;
};

/**
 * Build hash data string: key1=value1&key2=value2
 * Values are URL-encoded per VNPay spec (matching PHP urlencode)
 */
const buildHashData = (params) => {
  const sorted = sortObject(params);
  return Object.entries(sorted)
    .map(([key, value]) => `${phpUrlEncode(key)}=${phpUrlEncode(value)}`)
    .join("&");
};

/**
 * Build URL query string
 * Values are URL-encoded
 */
const buildQueryString = (params) => {
  const sorted = sortObject(params);
  return Object.entries(sorted)
    .map(([key, value]) => `${phpUrlEncode(key)}=${phpUrlEncode(value)}`)
    .join("&");
};

/**
 * Create HMAC-SHA512 signature
 */
const createSignature = (hashData, secretKey) => {
  return crypto
    .createHmac("sha512", secretKey)
    .update(Buffer.from(hashData, "utf-8"))
    .digest("hex");
};

/**
 * Create VNPay payment URL
 */
const createPaymentUrl = ({ amount, ipAddr, appReturnUrl }) => {
  const tmnCode = process.env.VNP_TMNCODE;
  const secretKey = process.env.VNP_HASHSECRET;
  const vnpUrl = process.env.VNP_URL;

  if (!tmnCode || !secretKey || !vnpUrl) {
    throw new Error(
      "Missing VNPay config: VNP_TMNCODE, VNP_HASHSECRET, VNP_URL"
    );
  }

  const createDate = moment().format("YYYYMMDDHHmmss");
  const orderId = moment().format("DDHHmmss");

  // Normalize IP address (remove IPv6 prefix if present)
  const normalizedIp =
    ipAddr?.replace(/^::ffff:/, "") || "127.0.0.1";

  // Build return URL with appReturnUrl so backend can redirect to Flutter later
  let returnUrl = process.env.VNP_RETURN_URL;
  if (appReturnUrl) {
    const sep = returnUrl.includes("?") ? "&" : "?";
    returnUrl += `${sep}returnAppUrl=${encodeURIComponent(appReturnUrl)}`;
  }

  const vnpParams = {
    vnp_Version: "2.1.0",
    vnp_Command: "pay",
    vnp_TmnCode: tmnCode,
    vnp_Locale: "vn",
    vnp_CurrCode: "VND",
    vnp_TxnRef: orderId,
    vnp_OrderInfo: `Thanh toan don hang ${orderId}`,
    vnp_OrderType: "other",
    vnp_Amount: amount * 100,
    vnp_ReturnUrl: returnUrl,
    vnp_IpAddr: normalizedIp,
    vnp_CreateDate: createDate,
  };

  // Build hash data with URL-encoded values (matching PHP urlencode)
  const hashData = buildHashData(vnpParams);
  const secureHash = createSignature(hashData, secretKey);

  // Build final URL: query string + secureHash appended at end (matching VNPay PHP demo)
  const queryString = buildQueryString(vnpParams);
  const paymentUrl =
    vnpUrl + "?" + queryString + "&vnp_SecureHash=" + secureHash;

  console.log("=== VNPay Payment URL Created ===");
  console.log("Hash Data:", hashData);
  console.log("SecureHash:", secureHash);

  return paymentUrl;
};

/**
 * Verify VNPay return URL / IPN signature
 */
const verifyReturnUrl = (queryParams) => {
  const secretKey = process.env.VNP_HASHSECRET;

  if (!secretKey) {
    throw new Error("Missing VNPay config: VNP_HASHSECRET");
  }

  // Extract vnp_ params excluding vnp_SecureHash and vnp_SecureHashType
  const vnpParams = {};
  for (const key of Object.keys(queryParams)) {
    if (
      key.startsWith("vnp_") &&
      key !== "vnp_SecureHash" &&
      key !== "vnp_SecureHashType"
    ) {
      vnpParams[key] = queryParams[key];
    }
  }

  const vnpSecureHash = queryParams["vnp_SecureHash"];

  if (!vnpSecureHash) {
    return {
      success: false,
      message: "Missing vnp_SecureHash in return data",
    };
  }

  // Build hash data from decoded values, re-encode with PHP urlencode
  const hashData = buildHashData(vnpParams);
  const computedHash = createSignature(hashData, secretKey);

  console.log("=== VNPay Return Verification ===");
  console.log("Hash Data:", hashData);
  console.log("Received Hash:", vnpSecureHash);
  console.log("Computed Hash:", computedHash);
  console.log("Match:", computedHash === vnpSecureHash);

  const isValid = computedHash === vnpSecureHash;

  return {
    success: isValid,
    message: isValid ? "Signature verified" : "Invalid signature",
    data: {
      txnRef: vnpParams["vnp_TxnRef"],
      amount: vnpParams["vnp_Amount"],
      orderInfo: vnpParams["vnp_OrderInfo"],
      responseCode: vnpParams["vnp_ResponseCode"],
      transactionNo: vnpParams["vnp_TransactionNo"],
      bankCode: vnpParams["vnp_BankCode"],
      payDate: vnpParams["vnp_PayDate"],
      transactionStatus: vnpParams["vnp_TransactionStatus"],
    },
  };
};

module.exports = {
  createPaymentUrl,
  verifyReturnUrl,
};