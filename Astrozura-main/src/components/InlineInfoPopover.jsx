import { useEffect, useId, useState } from "react";
import { Info } from "lucide-react";

export default function InlineInfoPopover({ title, content, className = "" }) {
  const [open, setOpen] = useState(false);
  const popoverId = useId();

  useEffect(() => {
    if (!open) return undefined;

    const close = () => setOpen(false);
    window.addEventListener("scroll", close, { passive: true });
    window.addEventListener("resize", close);
    return () => {
      window.removeEventListener("scroll", close);
      window.removeEventListener("resize", close);
    };
  }, [open]);

  return (
    <span
      className={`relative inline-flex items-center ${className}`}
      onMouseEnter={() => setOpen(true)}
      onMouseLeave={() => setOpen(false)}
    >
      <button
        type="button"
        aria-label={title || "More information"}
        aria-expanded={open}
        aria-controls={popoverId}
        onClick={() => setOpen((current) => !current)}
        className="inline-flex h-5 w-5 items-center justify-center rounded-full border border-slate-300 bg-white text-slate-500 transition hover:border-[#D4A73C] hover:text-[#D4A73C]"
      >
        <Info size={12} />
      </button>

      {open && (
        <div
          id={popoverId}
          role="tooltip"
          className="absolute left-1/2 top-[calc(100%+10px)] z-30 w-72 -translate-x-1/2 rounded-2xl border border-slate-200 bg-white p-4 text-left shadow-2xl"
        >
          <div className="absolute left-1/2 top-0 h-3 w-3 -translate-x-1/2 -translate-y-1/2 rotate-45 border-l border-t border-slate-200 bg-white" />
          {title && <p className="text-sm font-bold text-[#1E3557]">{title}</p>}
          <p className={`text-xs leading-6 text-slate-600 ${title ? "mt-2" : ""}`}>{content}</p>
        </div>
      )}
    </span>
  );
}
