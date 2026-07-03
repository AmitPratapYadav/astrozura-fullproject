import { useEffect, useRef, useState } from "react";
import { Sparkles, X } from "lucide-react";

export default function ComingSoonPopover({ children, label = "Coming Soon", className = "" }) {
  const [open, setOpen] = useState(false);
  const wrapperRef = useRef(null);

  useEffect(() => {
    if (!open) return undefined;
    const close = (event) => {
      if (!wrapperRef.current?.contains(event.target)) setOpen(false);
    };
    document.addEventListener("pointerdown", close);
    return () => document.removeEventListener("pointerdown", close);
  }, [open]);

  return (
    <span ref={wrapperRef} className={`relative inline-flex ${className}`}>
      <button type="button" onClick={() => setOpen((current) => !current)} className="inline-flex w-full" aria-expanded={open}>
        {children}
      </button>
      <span className="pointer-events-none absolute -right-1 -top-2 rounded-full bg-[#D4A73C] px-2 py-0.5 text-[9px] font-black uppercase tracking-wide text-[#1E3557] shadow">
        Soon
      </span>
      {open && (
        <span className="absolute bottom-full left-1/2 z-50 mb-3 w-60 -translate-x-1/2 rounded-xl border border-[#E8D49A] bg-white p-4 text-left text-[#1E3557] shadow-2xl">
          <span className="flex items-start gap-3">
            <Sparkles size={18} className="mt-0.5 shrink-0 text-[#D4A73C]" />
            <span className="min-w-0 flex-1">
              <strong className="block text-sm">{label}</strong>
              <span className="mt-1 block text-xs leading-5 text-gray-500">The AstroZura mobile app is being prepared for launch.</span>
            </span>
            <X size={15} className="shrink-0 text-gray-400" />
          </span>
        </span>
      )}
    </span>
  );
}
