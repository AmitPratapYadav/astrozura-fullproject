import { createContext, useState, useContext, useEffect } from "react";

const CartContext = createContext();

export const useCart = () => useContext(CartContext);

export const CartProvider = ({ children }) => {
  const [cartItems, setCartItems] = useState(() => {
    try {
      const savedCart = localStorage.getItem("astrozura_cart");
      if (savedCart) {
        const parsed = JSON.parse(savedCart);
        if (Array.isArray(parsed)) {
          return parsed.map((item) => ({
            ...item,
            cartKey: item.cartKey || `${item.id}:${item.variant_id || "base"}`,
          }));
        }
      }
    } catch (e) {
      console.error("Failed to parse cart", e);
    }
    return [];
  });

  useEffect(() => {
    // Save to local storage whenever cartItems change
    localStorage.setItem("astrozura_cart", JSON.stringify(cartItems));
  }, [cartItems]);

  const addToCart = (product) => {
    setCartItems((prevItems) => {
      const cartKey = product.cartKey || `${product.id}:${product.variant_id || "base"}`;
      const normalizedProduct = { ...product, cartKey };
      const existingItem = prevItems.find((item) => item.cartKey === cartKey);
      if (existingItem) {
        return prevItems.map((item) =>
          item.cartKey === cartKey
            ? { ...item, qty: item.qty + (product.qty || 1) }
            : item
        );
      }
      return [...prevItems, { ...normalizedProduct, qty: product.qty || 1 }];
    });
  };

  const removeFromCart = (cartKey) => {
    setCartItems((prevItems) => prevItems.filter((item) => item.cartKey !== cartKey));
  };

  const increaseQty = (cartKey) => {
    setCartItems((prevItems) =>
      prevItems.map((item) =>
        item.cartKey === cartKey ? { ...item, qty: item.qty + 1 } : item
      )
    );
  };

  const decreaseQty = (cartKey) => {
    setCartItems((prevItems) =>
      prevItems.map((item) =>
        item.cartKey === cartKey && item.qty > 1
          ? { ...item, qty: item.qty - 1 }
          : item
      )
    );
  };

  const clearCart = () => {
    setCartItems([]);
  };

  return (
    <CartContext.Provider
      value={{
        cartItems,
        addToCart,
        removeFromCart,
        increaseQty,
        decreaseQty,
        clearCart,
      }}
    >
      {children}
    </CartContext.Provider>
  );
};
