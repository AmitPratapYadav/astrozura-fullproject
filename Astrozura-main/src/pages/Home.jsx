import Navbar from "../components/Navbar"
import FeaturedAstrologerSection from "../components/FeaturedAstrologerSection"
import HeroServices from "../components/HeroServices"
import Premium from "../components/Premium"
import MainSections from "../components/MainSections"
import Footer from "../components/Footer"
import { Link } from "react-router-dom"
import { useEffect, useState } from "react"
import tarotBanner from "../assets/tarot-intro-banner.png"
import tarotBannerTwo from "../assets/tarot-intro-banner-2.png"

export default function Home(){
const tarotBanners = [tarotBanner, tarotBannerTwo]
const [activeTarotBanner, setActiveTarotBanner] = useState(0)

useEffect(() => {
  const timer = window.setInterval(() => {
    setActiveTarotBanner((current) => (current + 1) % tarotBanners.length)
  }, 4500)

  return () => window.clearInterval(timer)
}, [tarotBanners.length])

return(

<div>

<Navbar/>

<FeaturedAstrologerSection/>

<HeroServices/>

<section className="bg-[#FAF7F2] px-4 py-6 md:px-10">
  <div className="mx-auto max-w-[1280px]">
    <div className="relative">
      <Link
        to="/services/tarot-reading"
        className="group relative block aspect-[3/1] overflow-hidden rounded-2xl border border-[#D4A73C]/25 shadow-[0_14px_30px_rgba(15,23,42,0.14)] transition duration-300 hover:-translate-y-0.5 hover:shadow-[0_18px_38px_rgba(15,23,42,0.2)]"
        aria-label="Explore Tarot Reading"
      >
        {tarotBanners.map((banner, index) => (
          <img
            key={banner}
            src={banner}
            alt="Explore Tarot Reading"
            className={`absolute inset-0 h-full w-full object-cover transition duration-700 group-hover:scale-[1.01] ${
              index === activeTarotBanner ? "opacity-100" : "opacity-0"
            }`}
          />
        ))}
      </Link>
      <div className="mt-3 flex justify-center gap-2">
        {tarotBanners.map((_, index) => (
          <button
            key={index}
            type="button"
            aria-label={`Show tarot banner ${index + 1}`}
            onClick={() => setActiveTarotBanner(index)}
            className={`h-1.5 rounded-full transition-all ${
              index === activeTarotBanner ? "w-6 bg-[#D4A73C]" : "w-2 bg-[#D4A73C]/35"
            }`}
          />
        ))}
      </div>
    </div>
  </div>
</section>

<Premium/>

<MainSections/>

<Footer/>

</div>

)

}
