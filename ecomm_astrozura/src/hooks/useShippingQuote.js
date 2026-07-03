import { useEffect, useMemo, useState } from "react";
import api from "../api/axios";

export function useShippingQuote(cartItems) {
  const localSubtotal = useMemo(
    () => cartItems.reduce(
      (total, item) => total + (Number(item.price) || 0) * (Number(item.qty) || 1),
      0
    ),
    [cartItems]
  );
  const fallback = {
    subtotal_amount: localSubtotal,
    shipping_amount: 0,
    tax_amount: localSubtotal * 0.12,
    total_amount: localSubtotal * 1.12,
    shipping_breakdown: [],
  };
  const [quote, setQuote] = useState(fallback);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!cartItems.length) {
      setQuote({
        subtotal_amount: 0,
        shipping_amount: 0,
        tax_amount: 0,
        total_amount: 0,
        shipping_breakdown: [],
      });
      return undefined;
    }

    const timer = window.setTimeout(async () => {
      try {
        setLoading(true);
        const response = await api.post("/ecomm/shipping-quote", {
          items: cartItems.map((item) => ({
            id: item.id,
            variant_id: item.variant_id || null,
            qty: item.qty,
          })),
        });
        if (response.data?.status === "success") setQuote(response.data.data);
      } catch {
        setQuote(fallback);
      } finally {
        setLoading(false);
      }
    }, 180);

    return () => window.clearTimeout(timer);
  }, [cartItems, localSubtotal]);

  return { quote, loading };
}
