import React, { useRef, useState } from "react";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import { getTarotReading } from "../api/prokeralaApi";
import { getServiceIcon } from "../data/serviceIcons";

const cardPath = "/tarot/cards/web";

const tarotNames = [
  "KING OF WANDS",
  "QUEEN OF WANDS",
  "KNIGHT OF WANDS",
  "PAGE OF WANDS",
  "TEN OF WANDS",
  "NINE OF WANDS",
  "EIGHT OF WANDS",
  "SEVEN OF WANDS",
  "SIX OF WANDS",
  "FIVE OF WANDS",
  "FOUR OF WANDS",
  "THREE OF WANDS",
  "TWO OF WANDS",
  "ACE OF WANDS",
  "KING OF SWORDS",
  "QUEEN OF SWORDS",
  "KNIGHT OF SWORDS",
  "PAGE OF SWORDS",
  "TEN OF SWORDS",
  "NINE OF SWORDS",
  "EIGHT OF SWORDS",
  "SEVEN OF SWORDS",
  "SIX OF SWORDS",
  "FIVE OF SWORDS",
  "FOUR OF SWORDS",
  "THREE OF SWORDS",
  "TWO OF SWORDS",
  "ACE OF SWORDS",
  "KING OF CUPS",
  "QUEEN OF CUPS",
  "KNIGHT OF CUPS",
  "PAGE OF CUPS",
  "TEN OF CUPS",
  "NINE OF CUPS",
  "EIGHT OF CUPS",
  "SEVEN OF CUPS",
  "SIX OF CUPS",
  "FIVE OF CUPS",
  "FOUR OF CUPS",
  "THREE OF CUPS",
  "TWO OF CUPS",
  "ACE OF CUPS",
  "KING OF PENTACLES",
  "QUEEN OF PENTACLES",
  "KNIGHT OF PENTACLES",
  "PAGE OF PENTACLES",
  "TEN OF PENTACLES",
  "NINE OF PENTACLES",
  "EIGHT OF PENTACLES",
  "SEVEN OF PENTACLES",
  "SIX OF PENTACLES",
  "FIVE OF PENTACLES",
  "FOUR OF PENTACLES",
  "THREE OF PENTACLES",
  "TWO OF PENTACLES",
  "ACE OF PENTACLES",
  "THE FOOL",
  "THE MAGICIAN",
  "THE HIGH PRIESTESS",
  "THE EMPRESS",
  "THE EMPEROR",
  "THE HIEROPHANT",
  "THE LOVERS",
  "THE CHARIOT",
  "STRENGTH",
  "THE HERMIT",
  "WHEEL OF FORTUNE",
  "JUSTICE",
  "THE HANGED MAN",
  "DEATH",
  "TEMPERANCE",
  "THE DEVIL",
  "THE TOWER",
  "THE STAR",
  "THE MOON",
  "THE SUN",
  "JUDGEMENT",
  "THE WORLD",
];

const cardExtensions = {
  38: "png",
  39: "png",
  40: "png",
  41: "png",
  42: "png",
  43: "png",
  44: "png",
  45: "png",
  46: "png",
  47: "png",
  48: "png",
  49: "png",
  50: "png",
  51: "png",
  52: "png",
  53: "png",
  54: "png",
  55: "png",
  56: "png",
  57: "png",
  58: "png",
  59: "png",
  60: "png",
  61: "png",
  62: "png",
  63: "png",
  64: "png",
  65: "png",
  66: "png",
  67: "png",
  68: "png",
  69: "png",
  70: "png",
  71: "png",
  72: "png",
  73: "png",
  74: "png",
  75: "png",
  76: "png",
  77: "png",
  78: "png",
};

const slugifyCardName = (name) => name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
const tarotDeck = tarotNames.map((name, index) => {
  const id = index + 1;
  const extension = cardExtensions[id] || "jpg";

  return {
    id,
    name,
    image: `${cardPath}/${String(id).padStart(2, "0")}-${slugifyCardName(name)}.${extension}`,
  };
});

const yesNoTarotDeck = [
  { id: 1, name: "THE MAGICIAN", image: `${cardPath}/58-the-magician.png` },
  { id: 2, name: "THE HIEROPHANT", image: `${cardPath}/62-the-hierophant.png` },
  { id: 3, name: "THE EMPEROR", image: `${cardPath}/61-the-emperor.png` },
  { id: 4, name: "DEATH", image: `${cardPath}/70-death.png` },
  { id: 5, name: "THE HERMIT", image: `${cardPath}/66-the-hermit.png` },
  { id: 6, name: "THE DEVIL", image: `${cardPath}/72-the-devil.png` },
  { id: 7, name: "TEMPERANCE", image: `${cardPath}/71-temperance.png` },
  { id: 8, name: "THE FOOL", image: `${cardPath}/57-the-fool.png` },
  { id: 9, name: "THE CHARIOT", image: `${cardPath}/64-the-chariot.png` },
  { id: 10, name: "JUSTICE", image: `${cardPath}/68-justice.png` },
  { id: 11, name: "JUDGEMENT", image: `${cardPath}/77-judgement.png` },
  { id: 12, name: "STRENGTH", image: `${cardPath}/65-strength.png` },
  { id: 13, name: "THE EMPRESS", image: `${cardPath}/60-the-empress.png` },
  { id: 14, name: "WHEEL OF FORTUNE", image: `${cardPath}/67-wheel-of-fortune.png` },
  { id: 15, name: "THE STAR", image: `${cardPath}/74-the-star.png` },
  { id: 16, name: "THE MOON", image: `${cardPath}/75-the-moon.png` },
  { id: 17, name: "THE LOVERS", image: `${cardPath}/63-the-lovers.png` },
  { id: 18, name: "THE SUN", image: `${cardPath}/76-the-sun.png` },
  { id: 19, name: "THE HANGED MAN", image: `${cardPath}/69-the-hanged-man.png` },
  { id: 20, name: "THE TOWER", image: `${cardPath}/73-the-tower.png` },
  { id: 21, name: "THE WORLD", image: `${cardPath}/78-the-world.png` },
  { id: 22, name: "THE HIGH PRIESTESS", image: `${cardPath}/59-the-high-priestess.png` },
];

const shuffleDeck = (cards) => {
  const shuffled = [...cards];

  for (let index = shuffled.length - 1; index > 0; index -= 1) {
    const swapIndex = Math.floor(Math.random() * (index + 1));
    [shuffled[index], shuffled[swapIndex]] = [shuffled[swapIndex], shuffled[index]];
  }

  return shuffled;
};

const shuffleDeckWithPinnedCards = (cards, pinnedCardIds = []) => {
  const pinnedIds = new Set(pinnedCardIds.map((id) => Number(id)));
  const shuffledLooseCards = shuffleDeck(cards.filter((card) => !pinnedIds.has(card.id)));
  let looseIndex = 0;

  return cards.map((card) => {
    if (pinnedIds.has(card.id)) {
      return card;
    }

    const nextCard = shuffledLooseCards[looseIndex];
    looseIndex += 1;
    return nextCard;
  });
};

const cardBack = `${cardPath}/tarot-back.jpg`;

const readingSlots = [
  {
    key: "love",
    title: "Love",
    eyebrow: "Heart",
    gradient: "from-[#FFF0F1] to-[#FFE8DA]",
    border: "border-[#F5C6C9]",
  },
  {
    key: "career",
    title: "Career",
    eyebrow: "Path",
    gradient: "from-[#EEF6FF] to-[#F6F0FF]",
    border: "border-[#C8DDF7]",
  },
  {
    key: "finance",
    title: "Finance",
    eyebrow: "Wealth",
    gradient: "from-[#F2FAEE] to-[#FFF8DD]",
    border: "border-[#D8E9C8]",
  },
];

const slotOrder = readingSlots.map((slot) => slot.key);
const pageIcon = getServiceIcon("tarot-reading");

const createInitialSelections = () => ({
  love: null,
  career: null,
  finance: null,
});

const findCardById = (id) => tarotDeck.find((card) => card.id === Number(id));
const findYesNoCardById = (id) => yesNoTarotDeck.find((card) => card.id === Number(id));

export default function TarotReading() {
  const [mode, setMode] = useState("general");
  const [activeSlot, setActiveSlot] = useState("love");
  const [deckCards, setDeckCards] = useState(() => shuffleDeck(tarotDeck));
  const [yesNoDeckCards, setYesNoDeckCards] = useState(() => shuffleDeck(yesNoTarotDeck));
  const [selectedCards, setSelectedCards] = useState(createInitialSelections);
  const [selectedYesNoCard, setSelectedYesNoCard] = useState(null);
  const [question, setQuestion] = useState("");
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState("");
  const [result, setResult] = useState(null);
  const deckScrollRef = useRef(null);

  const allGeneralCardsSelected = readingSlots.every((slot) => selectedCards[slot.key]);
  const reading = result?.reading || {};
  const visibleDeckCards = mode === "yes-no" ? yesNoDeckCards : deckCards;

  const showToast = (message) => {
    setToast(message);
    window.clearTimeout(window.__astrozuraTarotToast);
    window.__astrozuraTarotToast = window.setTimeout(() => setToast(""), 3200);
  };

  const resetReading = () => {
    setResult(null);
    setSelectedCards(createInitialSelections());
    setSelectedYesNoCard(null);
    setActiveSlot("love");
    setDeckCards(shuffleDeck(tarotDeck));
    setYesNoDeckCards(shuffleDeck(yesNoTarotDeck));
  };

  const switchMode = (value) => {
    setMode(value);
    setResult(null);
    setToast("");
    setSelectedCards(createInitialSelections());
    setSelectedYesNoCard(null);
    setActiveSlot("love");
    setDeckCards(shuffleDeck(tarotDeck));
    setYesNoDeckCards(shuffleDeck(yesNoTarotDeck));
  };

  const getCardSelection = (cardId) => {
    if (selectedYesNoCard?.id === cardId) {
      return { type: "yes-no", label: "Yes / No" };
    }

    const slot = readingSlots.find((item) => selectedCards[item.key]?.id === cardId);
    return slot ? { type: slot.key, label: slot.title } : null;
  };

  const moveToNextEmptySlot = (currentSlot, nextSelections) => {
    const currentIndex = slotOrder.indexOf(currentSlot);
    const ordered = [...slotOrder.slice(currentIndex + 1), ...slotOrder.slice(0, currentIndex + 1)];
    const nextSlot = ordered.find((key) => !nextSelections[key]);

    if (nextSlot) {
      setActiveSlot(nextSlot);
    }
  };

  const handleDeckCardClick = (card) => {
    setResult(null);

    if (mode === "yes-no") {
      const nextCard = selectedYesNoCard?.id === card.id ? null : card;
      setSelectedYesNoCard(nextCard);
      setYesNoDeckCards((current) => shuffleDeckWithPinnedCards(current, [card.id]));
      return;
    }

    const existingSlot = readingSlots.find((slot) => selectedCards[slot.key]?.id === card.id);
    let nextSelections;

    if (existingSlot) {
      setActiveSlot(existingSlot.key);
      nextSelections = { ...selectedCards, [existingSlot.key]: null };
    } else {
      const targetSlot = selectedCards[activeSlot] ? slotOrder.find((key) => !selectedCards[key]) || activeSlot : activeSlot;
      nextSelections = { ...selectedCards, [targetSlot]: card };
      moveToNextEmptySlot(targetSlot, nextSelections);
    }

    setSelectedCards(nextSelections);
    setDeckCards((current) =>
      shuffleDeckWithPinnedCards(current, [
        card.id,
        ...Object.values(nextSelections)
          .filter(Boolean)
          .map((selectedCard) => selectedCard.id),
      ])
    );
  };

  const scrollDeck = (direction) => {
    deckScrollRef.current?.scrollBy({
      left: direction * Math.max(280, Math.floor((deckScrollRef.current.clientWidth || 640) * 0.72)),
      behavior: "smooth",
    });
  };

  const handleSubmit = async (event) => {
    event.preventDefault();

    if (mode === "general" && !allGeneralCardsSelected) {
      showToast("Select one card each for Love, Career, and Finance.");
      return;
    }

    if (mode === "yes-no" && !selectedYesNoCard) {
      showToast("Select one card for your yes/no reading.");
      return;
    }

    try {
      setLoading(true);
      setResult(null);

      const payload =
        mode === "yes-no"
          ? {
              type: "yes-no",
              question: question.trim() || undefined,
              tarot_id: selectedYesNoCard.id,
            }
          : {
              type: "general",
              love: selectedCards.love.id,
              career: selectedCards.career.id,
              finance: selectedCards.finance.id,
            };

      const response = await getTarotReading(payload);

      if (response?.status === "success") {
        setResult({
          ...response.data,
          selectedCards:
            mode === "yes-no"
              ? { tarot_id: selectedYesNoCard }
              : {
                  love: selectedCards.love,
                  career: selectedCards.career,
                  finance: selectedCards.finance,
                },
        });
        showToast("Tarot reading generated.");
        return;
      }

      showToast(response?.message || "Unable to generate tarot reading.");
    } catch (error) {
      showToast(error?.response?.data?.message || "Unable to connect to the tarot service.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#F8F6F1] text-[#1E3557]">
      {toast && (
        <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-xl bg-[#1E3557] px-6 py-3 text-sm font-medium text-white shadow-lg">
          {toast}
        </div>
      )}
      <Navbar />

      <section className="bg-[#1E3557] px-4 py-20 text-white md:px-8">
        <div className="mx-auto grid max-w-6xl gap-8 md:grid-cols-[1fr_auto] md:items-center">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.24em] text-[#D4A73C]">
              Premium Calculator
            </p>
            <h1 className="mt-4 max-w-3xl text-4xl font-black md:text-5xl">Tarot Reading</h1>
            <p className="mt-5 max-w-2xl text-sm leading-7 text-white/80 md:text-base">
              Choose cards for love, career, finance, or a focused yes/no reading.
            </p>
          </div>
          <div className="flex h-28 w-28 items-center justify-center rounded-[1.75rem] bg-white p-3 shadow-2xl md:h-36 md:w-36">
            <img src={pageIcon} alt="" className="h-full w-full object-contain" />
          </div>
        </div>
      </section>

      <main className="mx-auto max-w-7xl px-4 py-12 md:px-8">
        <section className="rounded-[2rem] border border-[#EFE3D1] bg-white p-5 shadow-sm md:p-8">
          <form onSubmit={handleSubmit} className="space-y-8">
            <div className="grid gap-5 lg:grid-cols-[340px_minmax(0,1fr)]">
              <aside className="rounded-3xl border border-[#EFE3D1] bg-[#FFFBF3] p-5">
                <label className="mb-2 block text-sm font-semibold text-slate-600">Reading Type</label>
                <div className="grid grid-cols-2 gap-2 rounded-2xl bg-white p-1.5">
                  {[
                    { value: "general", label: "Three Card" },
                    { value: "yes-no", label: "Yes / No" },
                  ].map((item) => (
                    <button
                      key={item.value}
                      type="button"
                      onClick={() => switchMode(item.value)}
                      className={`rounded-xl px-4 py-3 text-sm font-bold transition ${
                        mode === item.value
                          ? "bg-[#1E3557] text-white shadow-sm"
                          : "text-slate-500 hover:bg-[#F8F6F1]"
                      }`}
                    >
                      {item.label}
                    </button>
                  ))}
                </div>

                {mode === "yes-no" && (
                  <div className="mt-5">
                    <label className="mb-2 block text-sm font-semibold text-slate-600">Question</label>
                    <textarea
                      value={question}
                      onChange={(event) => setQuestion(event.target.value)}
                      rows={4}
                      placeholder="Ask a focused question"
                      className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                    />
                  </div>
                )}

                <div className="mt-5 rounded-2xl border border-[#EFE3D1] bg-white p-4">
                  <p className="text-xs font-bold uppercase tracking-[0.18em] text-[#D4A73C]">Selected Cards</p>
                  {mode === "yes-no" ? (
                    <div className="mt-3 flex items-center gap-3 rounded-2xl bg-[#F8F6F1] p-3">
                      <img
                        src={selectedYesNoCard?.image || cardBack}
                        alt=""
                        className="h-20 w-14 rounded-lg object-cover shadow-sm"
                      />
                      <div>
                        <p className="text-sm font-black text-[#1E3557]">
                          {selectedYesNoCard?.name || "Choose one card"}
                        </p>
                        <p className="mt-1 text-xs font-semibold text-slate-500">
                          {selectedYesNoCard ? `Card #${selectedYesNoCard.id}` : "No card selected"}
                        </p>
                      </div>
                    </div>
                  ) : (
                    <div className="mt-3 grid gap-3">
                      {readingSlots.map((slot) => {
                        const card = selectedCards[slot.key];
                        const isActive = activeSlot === slot.key;

                        return (
                          <button
                            key={slot.key}
                            type="button"
                            onClick={() => setActiveSlot(slot.key)}
                            className={`flex items-center gap-3 rounded-2xl border p-3 text-left transition ${
                              isActive
                                ? "border-[#D4A73C] bg-[#FFF7DE] shadow-sm"
                                : "border-slate-100 bg-[#F8F6F1] hover:border-[#D4A73C]/60"
                            }`}
                          >
                            <img
                              src={card?.image || cardBack}
                              alt=""
                              className="h-20 w-14 rounded-lg object-cover shadow-sm"
                            />
                            <div className="min-w-0">
                              <p className="text-xs font-bold uppercase tracking-[0.14em] text-[#D4A73C]">
                                {slot.eyebrow}
                              </p>
                              <p className="mt-1 text-sm font-black text-[#1E3557]">{slot.title}</p>
                              <p className="mt-1 truncate text-xs font-semibold text-slate-500">
                                {card ? `${card.name} (#${card.id})` : "Waiting for card"}
                              </p>
                            </div>
                          </button>
                        );
                      })}
                    </div>
                  )}
                </div>
              </aside>

              <div className="min-w-0 rounded-3xl border border-[#EFE3D1] bg-[#0E1726] p-5 text-white shadow-inner">
                <div className="flex flex-wrap items-center justify-between gap-3">
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[#D4A73C]">Tarot Deck</p>
                    <h2 className="mt-2 text-2xl font-black">
                      {mode === "yes-no" ? "Select one card" : `Select a card for ${readingSlots.find((slot) => slot.key === activeSlot)?.title}`}
                    </h2>
                  </div>
                  <div className="flex items-center gap-2">
                    <button
                      type="button"
                      onClick={() => scrollDeck(-1)}
                      className="flex h-10 w-10 items-center justify-center rounded-full border border-white/15 bg-white/10 text-lg font-black text-white transition hover:bg-white/20"
                      aria-label="Scroll tarot deck left"
                    >
                      &larr;
                    </button>
                    <button
                      type="button"
                      onClick={() => scrollDeck(1)}
                      className="flex h-10 w-10 items-center justify-center rounded-full border border-white/15 bg-white/10 text-lg font-black text-white transition hover:bg-white/20"
                      aria-label="Scroll tarot deck right"
                    >
                      &rarr;
                    </button>
                    <span className="rounded-full border border-white/10 bg-white/10 px-4 py-2 text-xs font-bold text-white/80">
                      {visibleDeckCards.length} cards loaded
                    </span>
                  </div>
                </div>

                <div ref={deckScrollRef} className="mt-6 overflow-x-auto pb-5">
                  <div className="flex min-w-max items-start px-2 py-5 md:px-6">
                    {visibleDeckCards.map((card, index) => {
                      const selection = getCardSelection(card.id);
                      const isSelected = Boolean(selection);
                      const image = isSelected ? card.image : cardBack;

                      return (
                        <button
                          key={card.id}
                          type="button"
                          onClick={() => handleDeckCardClick(card)}
                          className={`group relative h-[178px] w-[118px] shrink-0 rounded-2xl transition duration-200 first:ml-0 md:h-[224px] md:w-[148px] ${
                            index === 0 ? "" : "-ml-20 md:-ml-28"
                          } ${
                            isSelected
                              ? "z-30 translate-y-5 scale-[1.03]"
                              : "z-10 hover:z-20 hover:-translate-y-3 hover:scale-[1.02]"
                          }`}
                          style={{ zIndex: isSelected ? 80 + index : index + 1 }}
                          aria-label={`Select ${card.name}`}
                        >
                          <span
                            className={`absolute inset-0 rounded-2xl border-2 shadow-2xl transition ${
                              isSelected ? "border-[#D4A73C] shadow-[#D4A73C]/30" : "border-white/20 group-hover:border-[#D4A73C]/80"
                            }`}
                          />
                          <img
                            src={image}
                            alt={isSelected ? card.name : "Tarot card back"}
                            className="h-full w-full rounded-2xl object-cover"
                            draggable="false"
                          />
                          {isSelected && (
                            <span className="absolute -bottom-3 left-1/2 w-max -translate-x-1/2 rounded-full bg-[#D4A73C] px-3 py-1 text-[11px] font-black uppercase tracking-[0.12em] text-[#1E3557] shadow">
                              {selection.label}
                            </span>
                          )}
                        </button>
                      );
                    })}
                  </div>
                </div>

                <div className="mt-3 flex flex-wrap items-center justify-between gap-3 border-t border-white/10 pt-5">
                  <button
                    type="button"
                    onClick={resetReading}
                    className="rounded-2xl border border-white/15 px-5 py-3 text-sm font-bold text-white/80 transition hover:bg-white/10"
                  >
                    Clear Selection
                  </button>
                  <button
                    type="submit"
                    disabled={loading || (mode === "general" ? !allGeneralCardsSelected : !selectedYesNoCard)}
                    className="rounded-2xl bg-[#D4A73C] px-7 py-3 text-sm font-black text-[#1E3557] transition hover:bg-[#e0b84f] disabled:cursor-not-allowed disabled:opacity-60"
                  >
                    {loading ? "Drawing..." : "Draw Reading"}
                  </button>
                </div>
              </div>
            </div>
          </form>
        </section>

        <section className="mt-8 rounded-[2rem] border border-[#EFE3D1] bg-white p-5 shadow-sm md:p-8">
          {!result ? (
            <div className="flex min-h-[300px] items-center justify-center rounded-3xl border border-dashed border-[#EFE3D1] bg-[#FFFBF3] p-8 text-center">
              <div>
                <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[#D4A73C]">Ready</p>
                <h2 className="mt-3 text-2xl font-bold">Your tarot reading will appear here</h2>
              </div>
            </div>
          ) : result.type === "yes-no" ? (
            <div className="grid gap-6 lg:grid-cols-[220px_minmax(0,1fr)]">
              <div className="rounded-3xl bg-[#FFFBF3] p-5 text-center">
                <img
                  src={result.selectedCards?.tarot_id?.image || findYesNoCardById(result.cards?.tarot_id)?.image || cardBack}
                  alt=""
                  className="mx-auto h-72 w-48 rounded-2xl object-cover shadow-xl"
                />
                <p className="mt-4 text-sm font-black">{result.selectedCards?.tarot_id?.name || reading.name || "Tarot Card"}</p>
              </div>
              <div className="rounded-3xl border border-slate-100 bg-[#FFFBF3] p-6">
                <p className="text-xs font-semibold uppercase tracking-[0.18em] text-[#D4A73C]">Answer</p>
                <h2 className="mt-3 text-4xl font-black">{reading.value || "-"}</h2>
                {question.trim() && <p className="mt-4 text-sm font-semibold text-slate-500">{question.trim()}</p>}
                <p className="mt-5 whitespace-pre-line text-sm leading-7 text-slate-700">{reading.description || "-"}</p>
              </div>
            </div>
          ) : (
            <div className="grid gap-5">
              {readingSlots.map((slot) => {
                const card = result.selectedCards?.[slot.key] || findCardById(result.cards?.[slot.key]);

                return (
                  <article
                    key={slot.key}
                    className={`overflow-hidden rounded-3xl border ${slot.border} bg-gradient-to-br ${slot.gradient}`}
                  >
                    <div className="grid gap-5 p-5 md:grid-cols-[180px_minmax(0,1fr)] md:p-7">
                      <div className="rounded-3xl bg-white/70 p-4 text-center shadow-sm">
                        <img
                          src={card?.image || cardBack}
                          alt={card?.name || ""}
                          className="mx-auto h-60 w-40 rounded-2xl object-cover shadow-xl"
                        />
                        <p className="mt-4 text-xs font-bold uppercase tracking-[0.16em] text-[#D4A73C]">
                          Card #{result.cards?.[slot.key] || card?.id || "-"}
                        </p>
                        <h3 className="mt-1 text-base font-black text-[#1E3557]">{card?.name || "Selected Card"}</h3>
                      </div>
                      <div className="min-w-0">
                        <p className="text-xs font-semibold uppercase tracking-[0.18em] text-[#D4A73C]">{slot.eyebrow}</p>
                        <h2 className="mt-2 text-2xl font-black text-[#1E3557]">{slot.title}</h2>
                        <p className="mt-4 whitespace-pre-line text-sm leading-7 text-slate-700 md:text-base">
                          {reading[slot.key] || "-"}
                        </p>
                      </div>
                    </div>
                  </article>
                );
              })}

              <div className="flex justify-end">
                <button
                  type="button"
                  onClick={resetReading}
                  className="rounded-2xl border border-[#D4A73C] bg-white px-5 py-3 text-sm font-bold text-[#1E3557] transition hover:bg-[#FFFBF3]"
                >
                  Start New Reading
                </button>
              </div>
            </div>
          )}
        </section>
      </main>

      <Footer />
    </div>
  );
}
