import { useEffect, useRef, useState } from "react";
import { Plus, RefreshCw, Trash2 } from "lucide-react";

const emptyOption = () => ({ name: "", values: "" });

function combinations(groups) {
  return groups.reduce(
    (rows, group) => rows.flatMap((row) => group.values.map((value) => [...row, { name: group.name, value }])),
    [[]]
  );
}

export default function VariantEditor({ optionNames, variants, onChange }) {
  const [options, setOptions] = useState([emptyOption()]);
  const initializedRef = useRef(false);

  useEffect(() => {
    if (initializedRef.current || !optionNames?.length) return;
    setOptions(optionNames.map((name) => ({
      name,
      values: Array.from(new Set(
        variants
          .map((variant) => variant.option_values?.[name])
          .filter(Boolean)
      )).join(", "),
    })));
    initializedRef.current = true;
  }, [optionNames, variants]);

  const emit = (nextOptions, nextVariants = variants) => {
    const names = nextOptions.map((option) => option.name.trim()).filter(Boolean);
    onChange(names, nextVariants);
  };

  const updateOption = (index, key, value) => {
    const next = options.map((option, optionIndex) => optionIndex === index ? { ...option, [key]: value } : option);
    setOptions(next);
    emit(next);
  };

  const generateVariants = () => {
    const groups = options
      .map((option) => ({
        name: option.name.trim(),
        values: option.values.split(",").map((value) => value.trim()).filter(Boolean),
      }))
      .filter((option) => option.name && option.values.length);

    if (!groups.length) return;

    const generated = combinations(groups).map((values, position) => {
      const title = values.map((entry) => entry.value).join(" / ");
      const existing = variants.find((variant) => variant.title === title);
      return existing || {
        title,
        sku: "",
        option_values: Object.fromEntries(values.map((entry) => [entry.name, entry.value])),
        price: "",
        compare_at_price: "",
        stock_quantity: 0,
        status: true,
        position,
      };
    });

    emit(options, generated);
  };

  const updateVariant = (index, key, value) => {
    const next = variants.map((variant, variantIndex) => variantIndex === index ? { ...variant, [key]: value } : variant);
    emit(options, next);
  };

  const addManualVariant = () => {
    emit(options, [...variants, {
      title: `Variant ${variants.length + 1}`,
      sku: "",
      option_values: {},
      price: "",
      compare_at_price: "",
      stock_quantity: 0,
      status: true,
      position: variants.length,
    }]);
  };

  return (
    <section className="rounded-xl border border-gray-200 bg-gray-50 p-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h2 className="text-lg font-bold">Product Variants</h2>
          <p className="text-sm text-gray-500">Create options such as Size, Material, Color, or Pack.</p>
        </div>
        <button type="button" onClick={addManualVariant} className="flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm font-semibold">
          <Plus size={16} /> Add variant
        </button>
      </div>

      <div className="mt-5 space-y-3">
        {options.map((option, index) => (
          <div key={index} className="grid gap-3 md:grid-cols-[180px_1fr_auto]">
            <input
              value={option.name}
              onChange={(event) => updateOption(index, "name", event.target.value)}
              placeholder="Option name"
              className="rounded-lg border border-gray-300 bg-white px-3 py-2"
            />
            <input
              value={option.values}
              onChange={(event) => updateOption(index, "values", event.target.value)}
              placeholder="Values separated by commas"
              className="rounded-lg border border-gray-300 bg-white px-3 py-2"
            />
            <button
              type="button"
              aria-label="Remove option"
              onClick={() => {
                const next = options.filter((_, optionIndex) => optionIndex !== index);
                setOptions(next.length ? next : [emptyOption()]);
                emit(next, variants);
              }}
              className="rounded-lg border border-red-200 bg-white p-2 text-red-600"
            >
              <Trash2 size={17} />
            </button>
          </div>
        ))}
      </div>

      <div className="mt-3 flex flex-wrap gap-3">
        {options.length < 3 && (
          <button type="button" onClick={() => setOptions((current) => [...current, emptyOption()])} className="text-sm font-semibold text-blue-700">
            + Add another option
          </button>
        )}
        <button type="button" onClick={generateVariants} className="flex items-center gap-2 rounded-lg bg-gray-900 px-4 py-2 text-sm font-semibold text-white">
          <RefreshCw size={15} /> Generate combinations
        </button>
      </div>

      {variants.length > 0 && (
        <div className="mt-6 overflow-x-auto rounded-lg border border-gray-200 bg-white">
          <table className="w-full min-w-[900px] text-left text-sm">
            <thead className="bg-gray-100">
              <tr>
                <th className="p-3">Variant</th>
                <th className="p-3">Price</th>
                <th className="p-3">Compare at</th>
                <th className="p-3">SKU</th>
                <th className="p-3">Stock</th>
                <th className="p-3">Active</th>
                <th className="p-3"></th>
              </tr>
            </thead>
            <tbody>
              {variants.map((variant, index) => (
                <tr key={variant.id || `${variant.title}-${index}`} className="border-t">
                  <td className="p-2"><input required value={variant.title} onChange={(e) => updateVariant(index, "title", e.target.value)} className="w-full rounded border px-2 py-2" /></td>
                  <td className="p-2"><input required type="number" min="0" step="0.01" value={variant.price} onChange={(e) => updateVariant(index, "price", e.target.value)} className="w-28 rounded border px-2 py-2" /></td>
                  <td className="p-2"><input type="number" min="0" step="0.01" value={variant.compare_at_price || ""} onChange={(e) => updateVariant(index, "compare_at_price", e.target.value)} className="w-28 rounded border px-2 py-2" /></td>
                  <td className="p-2"><input value={variant.sku || ""} onChange={(e) => updateVariant(index, "sku", e.target.value)} className="w-36 rounded border px-2 py-2" /></td>
                  <td className="p-2"><input type="number" min="0" value={variant.stock_quantity ?? 0} onChange={(e) => updateVariant(index, "stock_quantity", e.target.value)} className="w-24 rounded border px-2 py-2" /></td>
                  <td className="p-2 text-center"><input type="checkbox" checked={Boolean(variant.status)} onChange={(e) => updateVariant(index, "status", e.target.checked)} /></td>
                  <td className="p-2"><button type="button" onClick={() => emit(options, variants.filter((_, variantIndex) => variantIndex !== index))} className="text-red-600"><Trash2 size={17} /></button></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </section>
  );
}
