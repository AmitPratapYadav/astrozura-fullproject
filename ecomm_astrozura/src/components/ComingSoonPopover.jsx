import { useEffect, useState } from "react";

export default function ComingSoonPopover({ children, className = "" }) {
  const [open, setOpen] = useState(false);

  useEffect(() => {
    if (!open) return undefined;
    const timer = window.setTimeout(() => setOpen(false), 2200);
    return () => window.clearTimeout(timer);
  }, [open]);

  return (
    <span className={`relative inline-flex ${className}`}>
      <button type="button" onClick={() => setOpen(true)} className="inline-flex" aria-label="Coming soon">
        {children}
      </button>
      {open && (
        <span className="absolute bottom-full left-1/2 z-20 mb-2 -translate-x-1/2 whitespace-nowrap rounded-lg bg-white px-3 py-2 text-xs font-bold text-[#1E3557] shadow-xl ring-1 ring-black/5">
          Coming Soon
        </span>
      )}
    </span>
  );
}
