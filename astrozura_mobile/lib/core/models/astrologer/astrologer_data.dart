// import '../astrologer/astrologer_model.dart';

// class AstrologerData {

//   /// 🔁 COMMON REVIEWS (DEFINE FIRST ✅)
//   static final List<ReviewModel> _commonReviews = [
//     ReviewModel(
//       name: "Priya Sharma",
//       image: "https://www.astrocamp.com//images/astrologer/ai-astro-2x/swamiji_sqr.jpg",
//       rating: 5,
//       review:
//           "The career guidance I received was life-changing. Accurate predictions and great support!",
//     ),
//     ReviewModel(
//       name: "Rahul Verma",
//       image: "https://www.astrocamp.com//images/astrologer/ai-astro-2x/swamiji_sqr.jpg",
//       rating: 4.5,
//       review:
//           "Amazing session! Helped me understand my future clearly and gave practical advice.",
//     ),
//     ReviewModel(
//       name: "Sneha Kapoor",
//       image: "https://www.astrocamp.com//images/astrologer/ai-astro-2x/swamiji_sqr.jpg",
//       rating: 5,
//       review:
//           "Very kind and knowledgeable astrologer. Highly recommended for relationship guidance.",
//     ),
//   ];

//   /// 🌟 Featured Astrologer
//   static AstrologerModel featuredAstrologer = AstrologerModel(
//     id: 1,
//   name: "Dr. Aruna Sharma",
//   image: "https://www.astrocamp.com//images/astrologer/ai-astro-2x/swamiji_sqr.jpg",
//   description: "Expert Vedic Astrologer with 20+ years experience",

//   experience: 22,
//   languages: ["English", "Hindi", "Sanskrit"],
//   categories: ["Vedic", "Tarot"],

//   rating: 4.9,
//   reviews: 5000,

//   chatPrice: 50,
//   callPrice: 70,

//   isFeatured: true,
//   isOnline: true,

//   /// ✅ ADD THIS (YOU MISSED THIS)
//   shortDescription:
//       "Renowned Vedic astrologer offering career and relationship guidance.",

//   fullDescription:
//       "Dr. Aruna Sharma is a highly respected astrologer with over 20 years of experience. She specializes in Vedic astrology, helping individuals with career clarity, financial growth, and relationship solutions.",

//   plans: [
//     ConsultationPlan(duration: 10, price: 200),
//     ConsultationPlan(duration: 15, price: 300),
//     ConsultationPlan(duration: 20, price: 400, isPopular: true),
//     ConsultationPlan(duration: 30, price: 600),
//   ],

//   reviewsList: _commonReviews,
// );

//   /// 📜 List of Astrologers
//   static List<AstrologerModel> astrologers = [
//     AstrologerModel(
//       id: 2,
//       name: "Pandit Meera",
//       image: "https://www.astrocamp.com//images/astrologer/ai-astro-2x/swamiji_sqr.jpg",
//       description: "Specialist in Vastu & Numerology",
//       experience: 8,
//       rating: 4.9,
//       languages: ["English", "Sanskrit"],
//       reviews: 840,
//       categories: ["Vastu", "Numerology", "Love"],
//       chatPrice: 15,
//       callPrice: 22,
//       isOnline: true,

//       shortDescription:
//           "Expert in Vastu and Numerology for life balance.",

//       fullDescription:
//           "Pandit Meera specializes in Vastu Shastra and Numerology, helping clients align their homes and lives for prosperity and success.",

//       plans: [
//         ConsultationPlan(duration: 10, price: 100),
//         ConsultationPlan(duration: 15, price: 150),
//         ConsultationPlan(duration: 20, price: 200, isPopular: true),
//         ConsultationPlan(duration: 30, price: 300),
//       ],

//       reviewsList: _commonReviews,
//     ),

//     AstrologerModel(
//       id: 3,
//       name: "Guru Devendra",
//       image: "https://www.astrocamp.com//images/astrologer/ai-astro-2x/swamiji_sqr.jpg",
//       description: "Expert in KP Astrology & Vedic readings",
//       experience: 15,
//       rating: 4.7,
//       languages: ["English", "Hindi", "Sanskrit"],
//       reviews: 2100,
//       categories: ["Vedic", "KP Astrology"],
//       chatPrice: 30,
//       callPrice: 40,
//       isOnline: true,

//       shortDescription:
//           "Specialist in KP astrology and accurate predictions.",

//       fullDescription:
//           "Guru Devendra is known for his deep expertise in KP astrology, providing highly accurate predictions related to career, marriage, and finances.",

//       plans: [
//         ConsultationPlan(duration: 10, price: 150),
//         ConsultationPlan(duration: 15, price: 250),
//         ConsultationPlan(duration: 20, price: 350, isPopular: true),
//         ConsultationPlan(duration: 30, price: 500),
//       ],

//       reviewsList: _commonReviews,
//     ),

//     AstrologerModel(
//       id: 4,
//       name: "Smt. Lakshmi",
//       image: "https://www.astrocamp.com//images/astrologer/ai-astro-2x/swamiji_sqr.jpg",
//       description: "Nadi & Prashna astrology expert",
//       experience: 25,
//       rating: 5.0,
//       reviews: 3200,
//       languages: ["English", "Hindi"],
//       categories: ["Vedic", "Prashna", "Nadi"],
//       chatPrice: 40,
//       callPrice: 50,
//       isOnline: true,

//       shortDescription:
//           "Expert in Nadi and Prashna astrology techniques.",

//       fullDescription:
//           "Smt. Lakshmi uses ancient Nadi and Prashna astrology methods to uncover deep insights into life patterns and future possibilities.",

//       plans: [
//         ConsultationPlan(duration: 10, price: 200),
//         ConsultationPlan(duration: 15, price: 300),
//         ConsultationPlan(duration: 20, price: 400, isPopular: true),
//         ConsultationPlan(duration: 30, price: 600),
//       ],

//       reviewsList: _commonReviews,
//     ),
//   ];
// }