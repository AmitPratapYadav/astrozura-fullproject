import { useState, useEffect } from "react";
import api from "../../api/axios";
import { useCart } from "../../context/CartContext";

export default function UserWishlist() {
  const [wishlist, setWishlist] = useState([]);
  const [loading, setLoading] = useState(true);
  const { addToCart } = useCart();

  useEffect(() => {
    fetchWishlist();
  }, []);

  const fetchWishlist = async () => {
    try {
      const response = await api.get("/dashboard/wishlist");
      if (response.data.status === "success") {
        setWishlist(response.data.data);
      }
    } catch (error) {
      console.error("Failed to fetch wishlist:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleRemove = async (productId) => {
    try {
      const response = await api.post("/dashboard/wishlist/toggle", { product_id: productId });
      if (response.data.status === "success") {
        setWishlist(wishlist.filter(item => item.id !== productId));
      }
    } catch (error) {
      console.error("Failed to remove item:", error);
    }
  };

  const getImage = (img) => {
    if (!img) return "https://placehold.co/400x400?text=No+Image";
    if (img.startsWith("http")) return img;
    const host = import.meta.env.VITE_BACKEND_URL || "http://127.0.0.1:8000";
    return `${host}/${img}`;
  };

  return (
    <div className="space-y-8 animate-fadeIn">
      {/* HEADER */}
      <div>
        <h2 className="text-2xl font-bold text-gray-900">My Wishlist</h2>
        <p className="text-gray-500 mt-1">Saved items you want to buy later.</p>
      </div>

      {loading ? (
        <div className="p-20 flex justify-center items-center">
          <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-[#c9a227]"></div>
        </div>
      ) : wishlist.length > 0 ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {wishlist.map((item) => (
            <div key={item.id} className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden group">
              <div className="relative h-48 bg-gray-50 overflow-hidden">
                <img 
                  src={getImage(item.image)} 
                  alt={item.name}
                  className="w-full h-full object-contain p-4 group-hover:scale-110 transition-transform duration-500"
                />
                <button 
                  onClick={() => handleRemove(item.id)}
                  className="absolute top-3 right-3 w-8 h-8 bg-white/80 backdrop-blur-sm rounded-full flex items-center justify-center text-red-500 hover:bg-white shadow-sm transition-all"
                >
                  ✕
                </button>
              </div>
              <div className="p-5">
                <h4 className="font-bold text-gray-900 text-sm h-10 line-clamp-2">{item.name}</h4>
                <div className="mt-4 flex items-center justify-between">
                  <p className="font-bold text-[#c9a227]">₹{item.price}</p>
                  <button 
                    onClick={() => {
                        addToCart({
                            id: item.id,
                            name: item.name,
                            price: item.price,
                            image: getImage(item.image),
                            qty: 1
                        });
                    }}
                    className="text-xs font-bold text-[#1d1d2b] hover:underline"
                  >
                    Add to Cart +
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="bg-white rounded-2xl p-20 text-center shadow-sm border border-gray-100">
           <div className="w-20 h-20 bg-red-50 rounded-full flex items-center justify-center mx-auto mb-6 text-3xl">
            ❤️
          </div>
          <h4 className="text-gray-900 font-bold text-xl">Your wishlist is empty</h4>
          <p className="text-gray-500 mt-2 max-w-sm mx-auto">
            Save items you like to your wishlist and they will show up here.
          </p>
          <button 
            className="mt-8 bg-[#1d1d2b] text-white px-10 py-3 rounded-xl font-bold hover:shadow-xl transition-all"
            onClick={() => window.location.href = '/all-products'}
          >
            Explore Products
          </button>
        </div>
      )}
    </div>
  );
}
