const crypto = require("crypto");
const https = require("https");

const getConfig = () => ({
  partnerCode: process.env.MOMO_PARTNER_CODE || "MOMOBKUN20180529",
  accessKey: process.env.MOMO_ACCESS_KEY || "klm05TvNBzhv7h7j",
  secretKey: process.env.MOMO_SECRET_KEY || "at67qH6mk8w5Y1nAyMoYKMWACiEi2bsa",
  endpoint: process.env.MOMO_ENDPOINT || "https://test-payment.momo.vn/v2/gateway/api/create",
});

const generateRequestId = () => Date.now() + "_" + Math.random().toString(36).substring(2, 8);

const generateOrderId = () => {
  const n = new Date();
  const p = (v, l) => String(v).padStart(l, "0");
  return "MM" + p(n.getFullYear(),4) + p(n.getMonth()+1,2) + p(n.getDate(),2) + p(n.getHours(),2) + p(n.getMinutes(),2) + p(n.getSeconds(),2) + p(n.getMilliseconds(),3);
};

const createSignature = (raw, key) => crypto.createHmac("sha256", key).update(raw, "utf-8").digest("hex").toUpperCase();

const postToMomo = (url, body) => new Promise((resolve, reject) => {
  const data = JSON.stringify(body);
  const u = new URL(url);
  const req = https.request({
    hostname: u.hostname, port: u.port || 443,
    path: u.pathname + u.search, method: "POST",
    headers: { "Content-Type": "application/json", "Content-Length": Buffer.byteLength(data) },
    timeout: 15000,
  }, (res) => {
    let d = ""; res.on("data", c => d += c);
    res.on("end", () => {
      console.log("MoMo status:", res.statusCode, "body:", d.substring(0, 500));
      try { resolve(JSON.parse(d)); } catch (e) { resolve({ raw: d, httpStatus: res.statusCode }); }
    });
  });
  req.on("timeout", () => { req.destroy(); reject(new Error("MoMo timeout")); });
  req.on("error", e => reject(new Error("MoMo connect fail: " + e.message)));
  req.write(data); req.end();
});

const createPaymentUrl = async ({ amount, orderInfo, appReturnUrl, redirectUrl, ipnUrl }) => {
  const cfg = getConfig();
  const requestId = generateRequestId();
  const orderId = generateOrderId();
  const extraData = appReturnUrl ? Buffer.from(appReturnUrl).toString("base64") : "";

  const rawSig = "accessKey=" + cfg.accessKey + "&amount=" + amount + "&extraData=" + extraData + "&ipnUrl=" + ipnUrl + "&orderId=" + orderId + "&orderInfo=" + orderInfo + "&partnerCode=" + cfg.partnerCode + "&redirectUrl=" + redirectUrl + "&requestId=" + requestId + "&requestType=captureWallet";
  const signature = createSignature(rawSig, cfg.secretKey);

  const body = {
    partnerCode: cfg.partnerCode, accessKey: cfg.accessKey,
    requestId, amount: String(amount), orderId, orderInfo,
    redirectUrl, ipnUrl, extraData, requestType: "captureWallet",
    signature, lang: "vi",
  };

  console.log("=== MoMo Request ===");
  console.log("Endpoint:", cfg.endpoint);
  console.log("Body:", JSON.stringify(body, null, 2));

  const response = await postToMomo(cfg.endpoint, body);
  console.log("MoMo Response:", JSON.stringify(response));

  const rc = response.resultCode;
  if (rc === 0 || rc === "0") {
    return { success: true, payUrl: response.payUrl, qrCodeUrl: response.qrCodeUrl, deeplink: response.deeplink, requestId, orderId, amount };
  }
  const err = new Error(response.message || "MoMo error (resultCode=" + rc + ")");
  err.momoResponse = response;
  throw err;
};

const verifyCallback = (params) => {
  const cfg = getConfig();
  const code = params.resultCode || params.errorCode || "";
  const sig = params.signature;
  if (!sig) return { success: false, message: "Missing signature" };

  const rawSig = "accessKey=" + (params.accessKey||"") + "&amount=" + (params.amount||"") + "&extraData=" + (params.extraData||"") + "&message=" + (params.message||"") + "&orderId=" + (params.orderId||"") + "&orderInfo=" + (params.orderInfo||"") + "&orderType=" + (params.orderType||"") + "&partnerCode=" + (params.partnerCode||"") + "&payType=" + (params.payType||"") + "&requestId=" + (params.requestId||"") + "&responseTime=" + (params.responseTime||"") + "&resultCode=" + code + "&transId=" + (params.transId||"");

  const computed = createSignature(rawSig, cfg.secretKey);
  const valid = computed === sig;
  const isSuccess = code === "0" || code === 0;

  let appReturnUrl = null;
  if (params.extraData) {
    try { appReturnUrl = Buffer.from(params.extraData, "base64").toString("utf-8"); } catch (e) {}
  }

  return {
    success: valid && isSuccess,
    message: isSuccess ? "Payment successful" : (params.message || "Failed (code=" + code + ")"),
    data: { txnRef: params.orderId, amount: params.amount, orderInfo: params.orderInfo, responseCode: code, transactionNo: params.transId, payType: params.payType, responseTime: params.responseTime },
    appReturnUrl,
  };
};

module.exports = { createPaymentUrl, verifyCallback };
