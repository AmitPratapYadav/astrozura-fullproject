import { useState, useEffect, useRef } from "react"
import { useNavigate, useParams } from "react-router-dom"
import Navbar from "../components/Navbar"
import Footer from "../components/Footer"
import { FaChevronLeft, FaChevronRight, FaStar } from "react-icons/fa"

import avatar from "../assets/astrologer-avatar.jpg"
import img1 from "../assets/img1.png"

import user1 from "../assets/user1.png"

export default function AstrologerProfile() {

const { id } = useParams()
const [msg,setMsg] = useState("")
const [activeBtn,setActiveBtn] = useState(null)
const [astrologer, setAstrologer] = useState(null)
const [similarAstrologers, setSimilarAstrologers] = useState([])
const [loading, setLoading] = useState(true)
const reviewsScrollerRef = useRef(null)

const navigate = useNavigate()

const showMsg = (text)=>{
  setMsg(text)
  setTimeout(()=> setMsg(""),2000)
}

const handleBtn = (id,text)=>{
  setActiveBtn(id)
  showMsg(text + " Clickable")
}

useEffect(() => {
  const fetchAstrologer = async () => {
    try {
      const apiUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api';
      const response = await fetch(`${apiUrl}/astrologer/${id}`);
      const data = await response.json();
      if (data.success) {
        setAstrologer(data.astrologer);
      } else {
        setAstrologer(null);
      }
    } catch (error) {
      console.error("Failed to fetch astrologer profile", error);
      setAstrologer(null);
    } finally {
      setLoading(false);
    }
  };
  
  const fetchSimilarExperts = async () => {
    try {
      const apiUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api';
      const response = await fetch(`${apiUrl}/astrologers`);
      const data = await response.json();
      if (data.success) {
        setSimilarAstrologers(data.astrologers.filter(a => a.id !== parseInt(id)).slice(0, 3));
      }
    } catch (error) {
      console.error("Failed to fetch similar experts", error);
    }
  };

  if(id) {
    fetchAstrologer();
    fetchSimilarExperts();
  } else {
    setLoading(false);
  }
}, [id]);

const getImageUrl = (path) => {
  if (!path) return avatar;
  if (path.startsWith('http')) return path;
  const baseUrl = import.meta.env.VITE_API_BASE_URL ? import.meta.env.VITE_API_BASE_URL.replace('/api', '') : 'http://localhost:8000';
  return `${baseUrl}${path.startsWith("/") ? path : `/${path}`}`;
};

const details = astrologer?.astrologer_detail || {};
const reviews = astrologer?.received_reviews || astrologer?.reviews || [];
const totalReviews = Number(details.total_reviews || reviews.length || 0);
const ratingValue = details.rating && totalReviews > 0 ? Number(details.rating) : null;
const specialitiesArray = details.specialities ? details.specialities.split(',').map(s => s.trim()) : ["Astrology"];
const basePrice = details.chat_price || details.call_price || 20;

const dynamicPlans = [
  { id: 1, time: "10 Minutes", duration: 10, price: `Rs ${basePrice * 10}` },
  { id: 2, time: "15 Minutes", duration: 15, price: `Rs ${basePrice * 15}` },
  { id: 3, time: "20 Minutes", duration: 20, price: `Rs ${basePrice * 20}` },
  { id: 4, time: "30 Minutes", duration: 30, price: `Rs ${basePrice * 30}` }
];

const renderedReviews = reviews.map((review) => ({
  id: review.id,
  rating: Number(review.rating || 0),
  review: review.review || "",
  name: review.user?.name || "Astro Zura User",
  image: review.user?.profile_image ? getImageUrl(review.user.profile_image) : user1,
  created_at: review.created_at,
}));

if (loading) {
  return (
    <div className="bg-[#FFFBF3] min-h-screen flex flex-col">
      <Navbar/>
      <div className="flex-1 flex justify-center items-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#D4A73C]"></div>
      </div>
      <Footer/>
    </div>
  );
}

if (!astrologer) {
  return (
    <div className="bg-[#FFFBF3] min-h-screen flex flex-col">
      <Navbar/>
      <div className="flex-1 flex justify-center items-center flex-col">
        <h2 className="text-2xl font-bold text-gray-700">Astrologer not found</h2>
        <button onClick={() => navigate('/astrologers')} className="mt-4 bg-[#D4A73C] text-white px-6 py-2 rounded-lg">Go Back</button>
      </div>
      <Footer/>
    </div>
  );
}

const scrollReviews = (direction) => {
  if (!reviewsScrollerRef.current) {
    return;
  }

  reviewsScrollerRef.current.scrollBy({
    left: direction * 340,
    behavior: "smooth",
  });
};

return(

<div className="bg-[#FFFBF3] min-h-screen flex flex-col">

<Navbar/>

{/* Notification */}
{msg && (
        <div className="fixed right-6 top-24 z-[70] rounded-lg bg-[#d8ba4a] px-6 py-3 text-white shadow-lg">
{msg}
</div>
)}

{/* PROFILE */}
<div className="w-full max-w-[1200px] mx-auto px-4 md:px-10 py-6">

<div className="bg-white rounded-2xl shadow p-8 flex flex-col md:flex-row gap-10 items-center">

<div className="relative">
<img 
  src={getImageUrl(details.profile_image)} 
  className="w-56 h-56 rounded-full border-4 border-[#E9B44C] object-cover bg-gray-50"
  alt={astrologer.name}
/>
<span className="absolute bottom-3 right-3 w-4 h-4 bg-green-500 rounded-full border-2 border-white"></span>
</div>

<div className="text-center md:text-left">

<p className="text-sm text-[#c7926a] font-semibold flex items-center gap-2 justify-center md:justify-start">
{ratingValue ? (
  <>
    <span className="flex items-center gap-1">
      <FaStar className="text-[#D4A73C]" />
      {ratingValue.toFixed(1)}/5
    </span>
    <span className="text-gray-500">({totalReviews} reviews)</span>
  </>
) : (
  <span className="text-gray-500">Not Rated Yet</span>
)}
</p>

<h1 className="text-4xl font-bold mt-2">{astrologer.name}</h1>

<p className="opacity-70 mt-2">
{details.experience_years || 0}+ Years Experience | {details.languages || 'English, Hindi'}
</p>

<div className="flex flex-wrap gap-3 mt-5 justify-center md:justify-start">

{specialitiesArray.map((spec, index) => (
  <button key={index} onClick={()=>showMsg(`${spec} Selected`)} className="bg-gray-100 hover:bg-[#f3d38d] px-4 py-2 rounded-full text-sm">
    {spec}
  </button>
))}

</div>

<div className="flex flex-wrap gap-4 mt-7 justify-center md:justify-start">

<button
onClick={()=>{
handleBtn("chat","Chat Booking")
navigate(`/consultation/${astrologer.id}`,{ state:{ type:"chat", astrologer} })
}}
className="px-7 py-3 rounded-xl shadow border bg-[#d8b14a] text-white border-[#c7926a]"
>
Book Chat (Rs {details.chat_price || 0}/min)
</button>

<button
onClick={()=>{
handleBtn("call","Audio Call")
navigate(`/consultation/${astrologer.id}`,{ state:{ type:"call", astrologer} })
}}
className="px-7 py-3 rounded-xl shadow border bg-white text-[#D4A73C] border-[#c7926a]"
>
Book Call (Rs {details.call_price || 0}/min)
</button>

</div>

</div>

</div>
</div>

{/* ABOUT */}
<div className="w-full max-w-[1200px] mx-auto px-4 md:px-10 py-6">

<h2 className="text-xl font-semibold mb-4">
About {astrologer.name}
</h2>

<div className="bg-white p-6 rounded-xl shadow text-gray-600 leading-relaxed whitespace-pre-line">
{details.about_bio || (
  "No bio provided for this astrologer. They are highly respected and experienced in guiding individuals to clarity and confidence."
)}
</div>

</div>

{/* CONSULTATION */}
<div className="w-full max-w-[1200px] mx-auto px-4 md:px-10 py-6">

<h2 className="text-xl font-semibold mb-6">
Consultation Plans
</h2>

<div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-8">

{dynamicPlans.map((plan)=>(

<div key={plan.id} className="bg-white p-6 rounded-2xl shadow text-center">

<div className="w-12 h-12 bg-[#FFF4DC] flex items-center justify-center rounded-full mx-auto mb-4">
Time
</div>

<p>{plan.time}</p>
<h3 className="text-2xl font-bold mt-2">{plan.price}</h3>

<button
onClick={()=>{
  handleBtn(plan.id,plan.time);
  navigate(`/consultation/${astrologer.id}`, { state: { type: "chat", astrologer, duration: plan.duration }});
}}
className="px-4 py-2 mt-4 w-full bg-[#d8ba4a] text-white rounded"
>
Book Now
</button>

</div>

))}

</div>

</div>

<div className="w-full max-w-[1200px] mx-auto px-4 md:px-10 py-6">
  
  <div className="flex justify-between mb-6 items-center gap-4">
    <h2 className="text-xl font-semibold">User Experiences</h2>

    {renderedReviews.length > 0 && (
      <div className="flex items-center gap-2">
        <button
          type="button"
          onClick={() => scrollReviews(-1)}
          className="flex h-10 w-10 items-center justify-center rounded-full border border-gray-200 bg-white text-gray-500 transition hover:border-[#D4A73C] hover:text-[#D4A73C]"
        >
          <FaChevronLeft />
        </button>
        <button
          type="button"
          onClick={() => scrollReviews(1)}
          className="flex h-10 w-10 items-center justify-center rounded-full border border-gray-200 bg-white text-gray-500 transition hover:border-[#D4A73C] hover:text-[#D4A73C]"
        >
          <FaChevronRight />
        </button>
      </div>
    )}
  </div>

  <div
    ref={reviewsScrollerRef}
    className="flex gap-6 overflow-x-auto scroll-smooth pb-3 snap-x snap-mandatory"
  >

    {renderedReviews.length > 0 ? renderedReviews.map((u) => (
      
      <div key={u.id} className="min-w-[300px] max-w-[340px] flex-1 snap-start bg-white p-6 rounded-xl shadow hover:shadow-md transition">

        {/* USER INFO */}
        <div className="flex items-center gap-3">
          <img
            src={u.image || user1}
            className="w-10 h-10 rounded-full object-cover"
          />
          <h3 className="font-semibold">{u.name || "App User"}</h3>
        </div>
        <div className="mt-3 flex items-center gap-1">
          {Array.from({ length: 5 }, (_, index) => (
            <FaStar key={`${u.id}-${index}`} className={index < u.rating ? "text-[#D4A73C]" : "text-gray-300"} />
          ))}
          <span className="ml-2 text-sm font-semibold text-[#1E3557]">{u.rating}/5</span>
        </div>
        <p className="text-gray-600 mt-3 text-sm leading-relaxed">
          {u.review || "The user rated this astrologer highly."}
        </p>
        {u.created_at && (
          <p className="mt-4 text-xs uppercase tracking-wide text-gray-400">
            {new Date(u.created_at).toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" })}
          </p>
        )}

      </div>
    )) : (
      <div className="w-full text-center text-gray-400 py-10">
        No reviews available for this astrologer yet.
      </div>
    )}

  </div>
</div>

{/* SIMILAR */}
{similarAstrologers && similarAstrologers.length > 0 && (
<div className="w-full max-w-[1200px] mx-auto px-4 md:px-10 py-6">

<h2 className="text-xl font-semibold mb-6">
Similar Experts
</h2>

<div className="grid md:grid-cols-3 gap-8">

{similarAstrologers.map((astro,i)=>(

<div key={i} className="bg-white rounded-xl shadow overflow-hidden">

<img 
  src={getImageUrl(astro.astrologer_detail?.profile_image) || img1} 
  alt={astro.name}
  className="w-full h-44 object-cover object-top"
/>

<div className="p-4">

<h3 className="font-semibold">{astro.name}</h3>
<p className="text-gray-500 text-sm mt-1">
  {astro.astrologer_detail?.specialities || "Astrology"}
</p>

<p className="text-[#c7926a] mt-2 font-medium">Rs {astro.astrologer_detail?.chat_price || 20}/min</p>

<button
onClick={()=>{
  handleBtn("profile"+astro.id,"View Profile")
  navigate("/profile/" + astro.id, { state: { msg: "Viewing Profile..." }})
}}
className="w-full py-2 rounded-lg mt-3 border hover:bg-gray-100"
>
View Profile
</button>

</div>

</div>

))}

</div>

</div>
)}

<Footer/>

</div>
)
}
