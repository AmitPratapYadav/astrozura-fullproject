import { useState, useEffect } from "react";
import api from "../../api/axios";
import { useNavigate } from "react-router-dom";

export default function UserOrders() {
  const [activeTab, setActiveTab] = useState("all");
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchOrders = async () => {
      try {
        const response = await api.get("/dashboard/orders");
        if (response.data.status === "success") {
          setOrders(response.data.data);
        }
      } catch (error) {
        console.error("Failed to fetch orders:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchOrders();
  }, []);

  const filteredOrders = activeTab === "all" 
    ? orders 
    : orders.filter(o => o.status.toLowerCase() === activeTab);

  const tabs = [
    { id: "all", label: "All Orders" },
    { id: "pending", label: "Pending" },
    { id: "completed", label: "Completed" },
  ];

  return (
    <div className="space-y-8 animate-fadeIn">
      {/* HEADER */}
      <div>
        <h2 className="text-2xl font-bold text-gray-900">My Orders</h2>
        <p className="text-gray-500 mt-1">Track your recent purchases and download invoices.</p>
      </div>

      {/* TABS */}
      <div className="flex items-center gap-2 p-1.5 bg-gray-100 rounded-2xl w-fit">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`px-6 py-2 rounded-xl text-sm font-bold transition-all ${
              activeTab === tab.id 
              ? "bg-white text-[#c9a227] shadow-sm" 
              : "text-gray-500 hover:text-gray-700"
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* ORDERS LIST */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        {loading ? (
          <div className="p-20 flex justify-center items-center">
            <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-[#c9a227]"></div>
          </div>
        ) : filteredOrders.length > 0 ? (
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead>
                <tr className="bg-gray-50 border-b border-gray-100">
                  <th className="px-6 py-4 text-xs font-bold text-gray-500 uppercase">Order ID</th>
                  <th className="px-6 py-4 text-xs font-bold text-gray-500 uppercase">Date</th>
                  <th className="px-6 py-4 text-xs font-bold text-gray-500 uppercase">Total</th>
                  <th className="px-6 py-4 text-xs font-bold text-gray-500 uppercase">Items</th>
                  <th className="px-6 py-4 text-xs font-bold text-gray-500 uppercase">Status</th>
                  <th className="px-6 py-4 text-xs font-bold text-gray-500 uppercase text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {filteredOrders.map((order) => (
                  <tr key={order.id} className="hover:bg-gray-50 transition">
                    <td className="px-6 py-4 font-bold text-gray-900">{order.order_number}</td>
                    <td className="px-6 py-4 text-sm text-gray-600">{new Date(order.created_at).toLocaleDateString()}</td>
                    <td className="px-6 py-4 text-sm font-bold text-gray-900">₹{order.total_amount}</td>
                    <td className="px-6 py-4 text-sm text-gray-600">{(order.items || []).length} items</td>
                    <td className="px-6 py-4">
                      <span className={`px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                        order.status === "completed" 
                        ? "bg-green-100 text-green-600" 
                        : "bg-amber-100 text-amber-600"
                      }`}>
                        {order.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <button onClick={() => navigate(`/dashboard/orders/${order.id}`)} className="text-xs font-bold text-[#c9a227] hover:underline">View Details</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="p-20 text-center">
            <div className="w-16 h-16 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-4 text-2xl">
              🔍
            </div>
            <h4 className="text-gray-900 font-bold text-lg">No orders found</h4>
            <p className="text-gray-500 mt-1">You haven't placed any {activeTab !== 'all' ? activeTab : ''} orders yet.</p>
            <button 
              onClick={() => navigate('/allproduct')}
              className="mt-6 bg-[#c9a227] text-white px-8 py-3 rounded-xl font-bold hover:shadow-lg transition">
              Start Shopping
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
