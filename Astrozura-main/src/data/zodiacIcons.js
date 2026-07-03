import aquarius from "../assets/zodiac-icons/aquarius.png";
import aries from "../assets/zodiac-icons/aries.png";
import cancer from "../assets/zodiac-icons/cancer.png";
import capricorn from "../assets/zodiac-icons/capricorn.png";
import gemini from "../assets/zodiac-icons/gemini.png";
import leo from "../assets/zodiac-icons/leo.png";
import libra from "../assets/zodiac-icons/libra.png";
import pisces from "../assets/zodiac-icons/pisces.png";
import sagittarius from "../assets/zodiac-icons/sagittarius.png";
import scorpio from "../assets/zodiac-icons/scorpio.png";
import taurus from "../assets/zodiac-icons/taurus.png";
import virgo from "../assets/zodiac-icons/virgo.png";

export const zodiacIconMap = {
  aquarius,
  aries,
  cancer,
  capricorn,
  gemini,
  leo,
  libra,
  pisces,
  sagittarius,
  scorpio,
  taurus,
  virgo,
};

export function getZodiacIcon(sign) {
  return zodiacIconMap[String(sign || "").toLowerCase()] || null;
}
