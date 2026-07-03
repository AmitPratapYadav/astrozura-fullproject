import { useEffect, useState } from "react";
import { assetUrl } from "../utils/assetUrl";
import placeholder from "../assets/vedic-astrology.png";

export default function CatalogImage({ src, alt, className = "", fallbackClassName = "" }) {
  const [failed, setFailed] = useState(!src);

  useEffect(() => {
    setFailed(!src);
  }, [src]);

  return (
    <img
      src={failed ? placeholder : assetUrl(src)}
      alt={alt}
      onError={() => setFailed(true)}
      className={`${className} ${failed ? `bg-[#FFF8E8] object-contain p-5 ${fallbackClassName}` : ""}`}
    />
  );
}
