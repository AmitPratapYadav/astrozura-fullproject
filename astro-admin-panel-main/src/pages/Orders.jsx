import { useEffect, useState } from "react";
import { apiRequest } from "../lib/api";

const statusOptions = ["pending", "processing", "completed", "cancelled"];

export default function Orders() {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [updatingId, setUpdatingId] = useState(null);

  const loadOrders = async () => {
    try {
      const response = await apiRequest("/admin/ecomm/orders");
      setOrders(response.data || []);
    } catch (error) {
      console.error("Failed to load orders", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadOrders();
  }, []);

  const updateStatus = async (order, status) => {
    setUpdatingId(order.id);
    try {
      await apiRequest(`/admin/ecomm/orders/${order.id}/status`, {
        method: "POST",
        body: { status, payment_status: order.payment_status },
      });
      await loadOrders();
    } finally {
      setUpdatingId(null);
    }
  };

  return (
    <div className="rounded-xl bg-white p-6 shadow-sm">
      <div className="mb-6">
        <h1 className="text-2xl font-bold">Product Orders</h1>
        <p className="mt-1 text-sm text-gray-500">Review customer orders and update fulfilment status.</p>
      </div>

      {loading ? <p>Loading orders...</p> : (
        <div className="overflow-x-auto">
          <table className="w-full min-w-[900px] text-left text-sm">
            <thead className="bg-gray-100 text-gray-700">
              <tr>
                <th className="p-3">Order</th>
                <th className="p-3">Customer</th>
                <th className="p-3">Items</th>
                <th className="p-3">Amount</th>
                <th className="p-3">Payment</th>
                <th className="p-3">Status</th>
                <th className="p-3">Placed</th>
              </tr>
            </thead>
            <tbody>
              {orders.map((order) => (
                <tr key={order.id} className="border-b align-top hover:bg-gray-50">
                  <td className="p-3 font-bold">{order.order_number}</td>
                  <td className="p-3">
                    <p className="font-semibold">{order.user?.name || "Customer"}</p>
                    <p className="text-xs text-gray-500">{order.phone}</p>
                  </td>
                  <td className="p-3">
                    {order.items?.map((item) => (
                      <p key={item.id} className="mb-1">
                        {item.product?.name}
                        {item.variant_title ? ` - ${item.variant_title}` : ""} x {item.quantity}
                      </p>
                    ))}
                  </td>
                  <td className="p-3 font-bold">Rs {Number(order.total_amount).toLocaleString("en-IN")}</td>
                  <td className="p-3 capitalize">{order.payment_status}</td>
                  <td className="p-3">
                    <select
                      value={order.status}
                      disabled={updatingId === order.id}
                      onChange={(event) => updateStatus(order, event.target.value)}
                      className="rounded-lg border border-gray-300 bg-white px-3 py-2 capitalize"
                    >
                      {statusOptions.map((status) => <option key={status} value={status}>{status}</option>)}
                    </select>
                  </td>
                  <td className="p-3 text-gray-500">{new Date(order.created_at).toLocaleString()}</td>
                </tr>
              ))}
              {!orders.length && (
                <tr><td colSpan="7" className="p-10 text-center text-gray-500">No product orders yet.</td></tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
