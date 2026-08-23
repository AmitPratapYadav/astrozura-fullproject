import { Link } from "react-router-dom";

export function ToolInputPanel({ title, description, action, children, className = "" }) {
  return (
    <section className={`rounded-[2rem] border border-[#EFE3D1] bg-white p-5 shadow-sm md:p-6 ${className}`}>
      {(title || description || action) && (
        <div className="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
          {(title || description) && (
            <div className="max-w-3xl">
              {title ? <h2 className="text-2xl font-bold text-[#1E3557]">{title}</h2> : null}
              {description ? <p className="mt-2 text-sm leading-6 text-slate-500">{description}</p> : null}
            </div>
          )}
          {action ? <div className="w-full md:w-[28rem] md:max-w-[45%]">{action}</div> : null}
        </div>
      )}
      {children}
    </section>
  );
}

export function RelatedToolTabs({ title = "Related tools", items = [], className = "" }) {
  const visibleItems = items.filter(Boolean);
  if (!visibleItems.length) return null;

  return (
    <nav className={`rounded-[2rem] border border-[#EFE3D1] bg-white p-4 shadow-sm ${className}`} aria-label={title}>
      <div className="mb-3 flex items-center justify-between gap-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-[#D4A73C]">{title}</p>
        <span className="hidden text-xs font-semibold text-slate-400 sm:inline">Scroll sideways for more</span>
      </div>
      <div className="-mx-1 flex gap-3 overflow-x-auto px-1 pb-2 [scrollbar-width:thin]">
        {visibleItems.map((item) => {
          const icon = item.icon || item.image || item.iconUrl;
          return (
            <Link
              key={item.to || item.href || item.label}
              to={item.to || item.href || "#"}
              aria-current={item.isActive ? "page" : undefined}
              className={`inline-flex min-h-11 shrink-0 items-center gap-2 rounded-full border px-4 py-2 text-sm font-extrabold transition ${
                item.isActive
                  ? "border-[#1E3557] bg-[#1E3557] text-white shadow-sm"
                  : "border-[#EFE3D1] bg-[#FFF9EA] text-[#1E3557] hover:border-[#D4A73C] hover:bg-[#FFF3CE]"
              }`}
            >
              {typeof icon === "string" ? (
                <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-white/80 p-1">
                  <img src={icon} alt="" className="h-full w-full object-contain" />
                </span>
              ) : null}
              <span className="whitespace-nowrap">{item.label || item.title}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
