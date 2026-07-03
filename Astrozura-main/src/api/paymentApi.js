import api from "./axios";

const loadRazorpay = () =>
  new Promise((resolve, reject) => {
    if (window.Razorpay) {
      resolve();
      return;
    }

    const existing = document.querySelector('script[src="https://checkout.razorpay.com/v1/checkout.js"]');
    if (existing) {
      existing.addEventListener("load", resolve, { once: true });
      existing.addEventListener("error", reject, { once: true });
      return;
    }

    const script = document.createElement("script");
    script.src = "https://checkout.razorpay.com/v1/checkout.js";
    script.async = true;
    script.onload = resolve;
    script.onerror = () => reject(new Error("Unable to load Razorpay Checkout."));
    document.head.appendChild(script);
  });

export const ensureRazorpayConfigured = async () => {
  const { data } = await api.get("/payments/razorpay/config");
  if (!data?.enabled) {
    throw new Error("Online payments are being configured. Please try again shortly.");
  }
  return data;
};

export const payWithRazorpay = async ({ purpose, recordId, name, email, contact, description }) => {
  await loadRazorpay();

  const { data } = await api.post("/payments/razorpay/order", {
    purpose,
    record_id: recordId,
  });

  return new Promise((resolve, reject) => {
    const checkout = new window.Razorpay({
      key: data.key_id,
      order_id: data.order.id,
      amount: data.order.amount,
      currency: data.order.currency,
      name: "AstroZura",
      description,
      prefill: { name, email, contact },
      theme: { color: "#D4A73C" },
      handler: async (payment) => {
        try {
          const verification = await api.post("/payments/razorpay/verify", {
            purpose,
            record_id: recordId,
            ...payment,
          });
          resolve(verification.data);
        } catch (error) {
          reject(error);
        }
      },
      modal: {
        ondismiss: () => reject(new Error("Payment was cancelled.")),
      },
    });

    checkout.on("payment.failed", (response) => {
      reject(new Error(response?.error?.description || "Payment failed."));
    });
    checkout.open();
  });
};
