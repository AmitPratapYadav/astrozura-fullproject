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
    throw new Error("Online payments are being configured. Please use cash on delivery for now.");
  }
  return data;
};

export const payForOrder = async ({ order, user, contact }) => {
  await loadRazorpay();
  const { data } = await api.post("/payments/razorpay/order", {
    purpose: "product",
    record_id: order.id,
  });

  return new Promise((resolve, reject) => {
    const checkout = new window.Razorpay({
      key: data.key_id,
      order_id: data.order.id,
      amount: data.order.amount,
      currency: data.order.currency,
      name: "Astral Shop - AstroZura",
      description: `Order ${order.order_number}`,
      prefill: { name: user?.name || "", email: user?.email || "", contact },
      theme: { color: "#C5A021" },
      handler: async (payment) => {
        try {
          const verification = await api.post("/payments/razorpay/verify", {
            purpose: "product",
            record_id: order.id,
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
