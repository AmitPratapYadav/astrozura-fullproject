// import '../product/product.model.dart';

// class ProductData {
//   static List<ProductModel> products = [
//     ProductModel(
//       id: "1",
//       name: "Natural Amethyst Healing Cluster",
//       images: [
//         "https://lifechangingastro.com/cdn/shop/files/7_mukhi_rudraksha_With_pendant.webp?v=1770448415&width=600",
//         "https://lifechangingastro.com/cdn/shop/files/7_mukhi_rudraksha_With_pendant.webp?v=1770448415&width=600",
//       ],
//       price: 600,
//       rating: 4.5,
//       reviews: 124,
//       category: "Crystals",
//       isBestSeller: true,
//       isRecommended: true,
//       description:
//           "Elevate your spiritual sanctuary with this hand-selected Amethyst cluster. Known for its calming energy, it enhances intuition, promotes inner peace, and protects against negative vibrations.",
//     ),

//     ProductModel(
//       id: "2",
//       name: "Tibetan Singing Meditation Bowl",
//       images: [
//         "https://lifechangingastro.com/cdn/shop/files/7_mukhi_rudraksha_With_pendant.webp?v=1770448415&width=600",
//         "https://lifechangingastro.com/cdn/shop/files/7_mukhi_rudraksha_With_pendant.webp?v=1770448415&width=600",
//       ],
//       price: 599,
//       oldPrice: 799,
//       rating: 4.7,
//       reviews: 189,
//       category: "Meditation",
//       isTrending: true,
//       description:
//           "Experience deep meditation and healing vibrations with this handcrafted Tibetan singing bowl. Ideal for chakra balancing, stress relief, and spiritual awakening.",
//     ),

//     ProductModel(
//       id: "3",
//       name: "Shri Yantra Copper Plate",
//       images: [
//         "https://lifechangingastro.com/cdn/shop/files/7_mukhi_rudraksha_With_pendant.webp?v=1770448415&width=600",
//         "https://lifechangingastro.com/cdn/shop/files/7_mukhi_rudraksha_With_pendant.webp?v=1770448415&width=600",
//       ],
//       price: 599,
//       rating: 4.4,
//       reviews: 56,
//       category: "Spiritual",
//       isRecommended: true,
//       description:
//           "The sacred Shri Yantra attracts prosperity, harmony, and divine blessings. Crafted in pure copper, it enhances positive energy flow in your home and workspace.",
//     ),

//     ProductModel(
//       id: "4",
//       name: "7 Chakra Healing Rudraksha Bracelet",
//       images: [
//         "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSC7dKvPe3NHKWIR1qnIWvJD-xpSG0Cy26z3g&s",
//         "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSC7dKvPe3NHKWIR1qnIWvJD-xpSG0Cy26z3g&s",
//       ],
//       price: 600,
//       rating: 4.3,
//       reviews: 210,
//       category: "Rudraksa",
//       isTrending: true,
//       description:
//           "Balance your chakras with this powerful Rudraksha bracelet infused with healing stones. Promotes emotional stability, focus, and spiritual alignment.",
//     ),

//     ProductModel(
//       id: "5",
//       name: "Essential Daily Pooja Kit",
//       images: [
//         "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSC7dKvPe3NHKWIR1qnIWvJD-xpSG0Cy26z3g&s",
//         "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSC7dKvPe3NHKWIR1qnIWvJD-xpSG0Cy26z3g&s",
//       ],
//       price: 799,
//       rating: 4.1,
//       reviews: 42,
//       category: "Pooja",
//       isNew: true,
//       description:
//           "Complete your daily rituals with this premium pooja kit. Includes incense, diya, and sacred essentials to maintain spiritual discipline and positivity.",
//     ),

//     ProductModel(
//       id: "6",
//       name: "Himalayan Salt Lamp",
//       images: [
//         "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSC7dKvPe3NHKWIR1qnIWvJD-xpSG0Cy26z3g&s",
//       ],
//       price: 499,
//       oldPrice: 699,
//       rating: 4.6,
//       reviews: 315,
//       category: "Home",
//       isRecommended: true,
//       description:
//           "Purify your surroundings with this Himalayan salt lamp. Emits calming light and helps reduce stress while improving air quality and energy balance.",
//     ),

//     /// 🔮 AMETHYST (Recommended + Best Seller)
//     ProductModel(
//       id: "7",
//       name: "Amethyst Healing Crystal",
//       images: [
//         "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSC7dKvPe3NHKWIR1qnIWvJD-xpSG0Cy26z3g&s",
//         "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSC7dKvPe3NHKWIR1qnIWvJD-xpSG0Cy26z3g&s",
//       ],
//       description:
//           "Elevate your spiritual energy with this Natural Amethyst Healing Cluster. Known as a stone of peace and protection, it helps calm the mind, enhance intuition, and remove negative energies. Ideal for meditation spaces, healing rituals, and creating a serene environment in your home.",
//       price: 400,
//       rating: 4.5,
//       reviews: 124,
//       category: "Crystals",
//       isBestSeller: true,
//       isRecommended: true,
//     ),

//     /// 🥣 MEDITATION BOWL (Trending)
//     ProductModel(
//       id: "8",
//       name: "Tibetan Singing Bowl",
//       images: [
//         "https://lifechangingastro.com/cdn/shop/files/7_mukhi_rudraksha_With_pendant.webp?v=1770448415&width=600",
//         "https://lifechangingastro.com/cdn/shop/files/7_mukhi_rudraksha_With_pendant.webp?v=1770448415&width=600",
//         "https://lifechangingastro.com/cdn/shop/files/7_mukhi_rudraksha_With_pendant.webp?v=1770448415&width=600",
//       ],
//       description:
//           "Experience deep relaxation and vibrational healing with this Tibetan Singing Bowl. Crafted for meditation and sound therapy, it helps balance chakras, reduce stress, and promote mindfulness. Perfect for yoga sessions and spiritual practices.",
//       price: 599,
//       oldPrice: 799,
//       rating: 4.7,
//       reviews: 189,
//       category: "Meditation",
//       isTrending: true,
//     ),

//     /// 🕉️ YANTRA
//     ProductModel(
//       id: "9",
//       name: "Shri Yantra Copper Plate",
//       images: [
//         "https://lifechangingastro.com/cdn/shop/files/7_mukhi_rudraksha_With_pendant.webp?v=1770448415&width=600",
//         "https://lifechangingastro.com/cdn/shop/files/7_mukhi_rudraksha_With_pendant.webp?v=1770448415&width=600",
//         "https://lifechangingastro.com/cdn/shop/files/7_mukhi_rudraksha_With_pendant.webp?v=1770448415&width=600",
//       ],
//       description:
//           "The sacred Shri Yantra is a powerful symbol of divine energy and prosperity. This finely crafted copper plate enhances positivity, attracts abundance, and brings harmony to your surroundings. Ideal for home temples and vastu correction.",
//       price: 599,
//       rating: 4.4,
//       reviews: 56,
//       category: "Spiritual",
//       isRecommended: true,
//     ),

//     /// 📿 CHAKRA BRACELET (Trending)
//     ProductModel(
//       id: "10",
//       name: "7 Chakra Healing Bracelet",
//       images: [
//         "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSC7dKvPe3NHKWIR1qnIWvJD-xpSG0Cy26z3g&s",
//         "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSC7dKvPe3NHKWIR1qnIWvJD-xpSG0Cy26z3g&s",
//         "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSC7dKvPe3NHKWIR1qnIWvJD-xpSG0Cy26z3g&s",
//       ],
//       description:
//           "This 7 Chakra Rudraksha Bracelet is designed to balance your energy centers and promote emotional well-being. Infused with healing stones and sacred Rudraksha beads, it supports focus, reduces stress, and enhances spiritual growth.",
//       price: 600,
//       rating: 4.3,
//       reviews: 210,
//       category: "Rudraksa",
//       isTrending: true,
//     ),

//     /// 🪔 POOJA KIT (New Arrival)
//     ProductModel(
//       id: "11",
//       name: "Essential Daily Pooja Kit",
//       images: [
//         "https://lifechangingastro.com/cdn/shop/files/7_mukhi_rudraksha_With_pendant.webp?v=1770448415&width=600",
//         "https://lifechangingastro.com/cdn/shop/files/7_mukhi_rudraksha_With_pendant.webp?v=1770448415&width=600",
//         "https://lifechangingastro.com/cdn/shop/files/7_mukhi_rudraksha_With_pendant.webp?v=1770448415&width=600",
//       ],
//       description:
//           "Perform your daily rituals with ease using this complete Pooja Kit. It includes essential spiritual items to maintain purity, devotion, and positive vibrations in your home. Perfect for daily prayers and festive occasions.",
//       price: 799,
//       rating: 4.1,
//       reviews: 42,
//       category: "Pooja",
//       isNew: true,
//     ),

//     /// 🧂 SALT LAMP (Recommended)
//     ProductModel(
//       id: "12",
//       name: "Himalayan Salt Lamp",
//       images: [
//         "https://lifechangingastro.com/cdn/shop/files/7_mukhi_rudraksha_With_pendant.webp?v=1770448415&width=600",
//         "https://lifechangingastro.com/cdn/shop/files/7_mukhi_rudraksha_With_pendant.webp?v=1770448415&width=600",
//         "https://lifechangingastro.com/cdn/shop/files/7_mukhi_rudraksha_With_pendant.webp?v=1770448415&width=600",
//       ],
//       description:
//           "Bring warmth and positivity into your space with this Himalayan Salt Lamp. Known for its soothing glow, it helps purify the air, reduce stress, and create a calming ambiance for relaxation and meditation.",
//       price: 499,
//       oldPrice: 699,
//       rating: 4.6,
//       reviews: 315,
//       category: "Home",
//       isRecommended: true,
//     ),

//     /// 🌿 INCENSE (Trending)
//     ProductModel(
//       id: "13",
//       name: "Natural Incense Sticks",
//       images: [
//         "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSC7dKvPe3NHKWIR1qnIWvJD-xpSG0Cy26z3g&shttps://images.unsplash.com/photo-1615484477778-ca3b77940c25?w=600",
//         "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSC7dKvPe3NHKWIR1qnIWvJD-xpSG0Cy26z3g&s",
//         "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSC7dKvPe3NHKWIR1qnIWvJD-xpSG0Cy26z3g&s",
//       ],
//       description:
//           "Enhance your spiritual rituals with these Natural Incense Sticks. Made from pure ingredients, they create a soothing aroma that uplifts mood, purifies the environment, and deepens meditation practices.",
//       price: 199,
//       rating: 4.2,
//       reviews: 88,
//       category: "Incense",
//       isTrending: true,
//     ),

//     /// 🔷 CRYSTAL SET (New + Recommended)
//     ProductModel(
//       id: "14",
//       name: "Healing Crystal Set",
//       images: [
//         "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSC7dKvPe3NHKWIR1qnIWvJD-xpSG0Cy26z3g&s",
//         "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSC7dKvPe3NHKWIR1qnIWvJD-xpSG0Cy26z3g&s",
//         "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSC7dKvPe3NHKWIR1qnIWvJD-xpSG0Cy26z3g&s",
//       ],
//       description:
//           "This Healing Crystal Set includes carefully selected stones to support emotional balance, protection, and spiritual growth. Each crystal carries unique energy to help you align with positivity and inner peace.",
//       price: 999,
//       rating: 4.8,
//       reviews: 140,
//       category: "Crystals",
//       isNew: true,
//       isRecommended: true,
//     ),
//   ];
// }
