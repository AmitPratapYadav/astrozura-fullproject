import { useEffect, useState } from "react";
import { ArrowLeft, Download } from "lucide-react";
import { useNavigate, useParams } from "react-router-dom";
import api from "../../api/axios";
import CatalogImage from "../../components/CatalogImage";

export default function OrderDetails() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [order, setOrder] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get(`/dashboard/orders/${id}`)
      .then((response) => setOrder(response.data?.data || null))
      .finally(() => setLoading(false));
  }, [id]);

  const downloadInvoice = async () => {
    const response = await api.get(`/dashboard/orders/${id}/invoice`, { responseType: "blob" });
    const url = URL.createObjectURL(response.data);
    const link = document.createElement("a");
    link.href = url;
    link.download = `${order?.order_number || "order"}-invoice.pdf`;
    link.click();
    URL.revokeObjectURL(url);
  };

  if (loading) return <p className="p-10 text-center text-gray-500">Loading order...</p>;
  if (!order) return <p className="p-10 text-center text-gray-500">Order not found.</p>;

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <button type="button" onClick={() => navigate("/dashboard/orders")} className="rounded-xl border p-2 text-gray-600">
            <ArrowLeft size={18} />
          </button>
          <div>
            <h2 className="text-2xl font-bold text-gray-900">{order.order_number}</h2>
            <p className="mt-1 text-sm text-gray-500">{new Date(order.created_at).toLocaleString()}</p>
          </div>
        </div>
        <button type="button" onClick={() => void downloadInvoice()} className="inline-flex items-center gap-2 rounded-xl bg-[#c9a227] px-5 py-3 text-sm font-bold text-white">
          <Download size={17} /> Download Invoice
        </button>
      </div>

      <section className="overflow-hidden rounded-2xl border border-gray-100 bg-white shadow-sm">
        {(order.items || []).map((item) => (
          <div key={item.id} className="flex items-center gap-4 border-b border-gray-100 p-5 last:border-0">
            <CatalogImage src={item.product?.image} alt={item.product?.name || "Product"} className="h-16 w-16 rounded-xl object-cover" />
            <div className="min-w-0 flex-1">
              <strong className="block truncate text-gray-900">{item.product?.name || "Product"}</strong>
              <p className="mt-1 text-xs text-gray-500">{item.variant_title || "Standard"} · Qty {item.quantity}</p>
            </div>
            <strong className="text-[#1E3557]">₹{(Number(item.price) * item.quantity).toFixed(2)}</strong>
          </div>
        ))}
      </section>

      <div className="grid gap-6 lg:grid-cols-2">
        <section className="rounded-2xl border border-gray-100 bg-white p-6 shadow-sm">
          <h3 className="font-bold text-gray-900">Shipping Address</h3>
          <p className="mt-3 text-sm leading-7 text-gray-600">
            {order.shipping_details?.recipient_name || ""}<br />
            {order.shipping_details?.address_line || order.shipping_address}<br />
            {order.shipping_details?.city || ""}, {order.shipping_details?.state || ""} {order.shipping_details?.postal_code || ""}<br />
            {order.shipping_details?.phone || order.phone}
          </p>
        </section>
        <section className="rounded-2xl bg-[#1E3557] p-6 text-white shadow-sm">
          <h3 className="font-bold">Payment Summary</h3>
          <div className="mt-4 space-y-3 text-sm">
            <div className="flex justify-between"><span className="text-white/60">Subtotal</span><span>₹{Number(order.subtotal_amount).toFixed(2)}</span></div>
            {(order.shipping_breakdown || []).map((item) => (
              <div key={item.category_id} className="flex justify-between"><span className="text-white/60">Shipping: {item.category_name}</span><span>₹{Number(item.amount).toFixed(2)}</span></div>
            ))}
            <div className="flex justify-between"><span className="text-white/60">Tax</span><span>₹{Number(order.tax_amount).toFixed(2)}</span></div>
            <div className="flex justify-between border-t border-white/10 pt-3 text-lg font-bold"><span>Total</span><span>₹{Number(order.total_amount).toFixed(2)}</span></div>
          </div>
          <div className="mt-5 flex gap-2 text-xs uppercase">
            <span className="rounded-full bg-white/10 px-3 py-1">{order.status}</span>
            <span className="rounded-full bg-white/10 px-3 py-1">{order.payment_status}</span>
          </div>
        </section>
      </div>
    </div>
  );
}
