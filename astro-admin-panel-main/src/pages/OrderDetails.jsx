import { ArrowLeft, Download } from "lucide-react";
import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { apiRequest } from "../lib/api";

const API_BASE = import.meta.env.VITE_API_BASE_URL || "https://astrozura.com/apigateway/index.php/api";

export default function OrderDetails() {
  const { id } = useParams();
  const [order, setOrder] = useState(null);
  useEffect(() => { apiRequest(`/admin/ecomm/orders/${id}`).then((response) => setOrder(response.data)); }, [id]);
  const invoice = async () => {
    const response = await fetch(`${API_BASE}/admin/ecomm/orders/${id}/invoice`, { headers: { Authorization: `Bearer ${localStorage.getItem("admin_token")}` } });
    if (!response.ok) return window.alert("Invoice download failed.");
    const url = URL.createObjectURL(await response.blob());
    const link = document.createElement("a"); link.href = url; link.download = `${order.order_number}-invoice.pdf`; link.click(); URL.revokeObjectURL(url);
  };
  if (!order) return <p>Loading order...</p>;
  const address = order.shipping_details || {};
  return <div className="space-y-6"><div className="flex flex-wrap items-center justify-between gap-3"><div className="flex items-center gap-3"><Link to="/orders"><ArrowLeft /></Link><div><h1 className="text-2xl font-bold">{order.order_number}</h1><p className="text-sm text-gray-500">{order.user?.name} · {order.status}</p></div></div><button onClick={invoice} className="flex items-center gap-2 rounded-lg bg-yellow-500 px-4 py-2 font-semibold"><Download size={17} /> Download Invoice</button></div><div className="grid gap-6 lg:grid-cols-[2fr_1fr]"><section className="rounded-xl bg-white p-6 shadow"><h2 className="mb-4 font-bold">Items</h2>{order.items?.map((item) => <div key={item.id} className="flex justify-between border-b py-3"><div><p className="font-semibold">{item.product?.name}</p><p className="text-sm text-gray-500">{item.variant_title || item.variant?.title} × {item.quantity}</p></div><p>₹{Number(item.total_price || item.price * item.quantity).toLocaleString("en-IN")}</p></div>)}<div className="ml-auto mt-5 max-w-sm space-y-2 text-sm"><p className="flex justify-between"><span>Subtotal</span><b>₹{Number(order.subtotal_amount || 0).toLocaleString("en-IN")}</b></p><p className="flex justify-between"><span>Shipping</span><b>₹{Number(order.shipping_amount || 0).toLocaleString("en-IN")}</b></p><p className="flex justify-between"><span>Tax</span><b>₹{Number(order.tax_amount || 0).toLocaleString("en-IN")}</b></p><p className="flex justify-between border-t pt-2 text-lg"><span>Total</span><b>₹{Number(order.total_amount).toLocaleString("en-IN")}</b></p></div></section><aside className="rounded-xl bg-white p-6 shadow"><h2 className="mb-3 font-bold">Shipping Address</h2><p>{address.full_name || order.user?.name}</p><p>{address.address_line1 || order.address}</p><p>{address.address_line2}</p><p>{[address.city, address.state, address.postal_code].filter(Boolean).join(", ")}</p><p className="mt-2">{address.phone || order.phone}</p></aside></div></div>;
}
