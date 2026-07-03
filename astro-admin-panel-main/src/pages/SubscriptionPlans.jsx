import { useState, useEffect } from "react"
import { PlusCircle, Trash2, Edit2, Save, X } from "lucide-react"

const API_BASE = import.meta.env.VITE_API_BASE_URL || "https://astrozura.com/apigateway/index.php/api"

function SubscriptionPlans() {
  const [plans, setPlans]       = useState([])
  const [loading, setLoading]   = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [editPlan, setEditPlan] = useState(null)
  const [toast, setToast]       = useState("")

  const emptyForm = { name: "", price: "", features: "", is_popular: false, is_active: true }
  const [form, setForm] = useState(emptyForm)

  const showToast = (msg) => {
    setToast(msg)
    setTimeout(() => setToast(""), 3000)
  }

  const fetchPlans = () => {
    setLoading(true)
    fetch(`${API_BASE}/admin/subscription-plans`)
      .then(r => r.json())
      .then(data => { if (data.success) setPlans(data.plans) })
      .catch(() => {})
      .finally(() => setLoading(false))
  }

  useEffect(() => { fetchPlans() }, [])

  const handleEdit = (plan) => {
    setEditPlan(plan)
    const features = Array.isArray(plan.features) ? plan.features : JSON.parse(plan.features || "[]")
    setForm({ name: plan.name, price: plan.price, features: features.join("\n"), is_popular: plan.is_popular, is_active: plan.is_active })
    setShowForm(true)
  }

  const handleNew = () => {
    setEditPlan(null)
    setForm(emptyForm)
    setShowForm(true)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    const payload = {
      name:       form.name,
      price:      parseFloat(form.price),
      features:   form.features.split("\n").map(f => f.trim()).filter(Boolean),
      is_popular: form.is_popular,
      is_active:  form.is_active,
    }
    const url     = editPlan ? `${API_BASE}/admin/subscription-plans/${editPlan.id}` : `${API_BASE}/admin/subscription-plans`
    const res     = await fetch(url, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload) })
    const data    = await res.json()
    if (data.success) {
      showToast(editPlan ? "Plan updated!" : "Plan created!")
      setShowForm(false)
      fetchPlans()
    }
  }

  const handleDelete = async (id) => {
    if (!confirm("Delete this plan?")) return
    const res  = await fetch(`${API_BASE}/admin/subscription-plans/${id}`, { method: "DELETE" })
    const data = await res.json()
    if (data.success) { showToast("Plan deleted!"); fetchPlans() }
  }

  return (
    <div className="space-y-6">
      {toast && (
        <div className="fixed top-6 left-1/2 -translate-x-1/2 bg-yellow-500 text-white px-6 py-2 rounded-full z-50 shadow-lg">
          {toast}
        </div>
      )}

      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Subscription Plans</h1>
        <button onClick={handleNew} className="flex items-center gap-2 bg-yellow-500 text-black px-4 py-2 rounded-lg text-sm font-semibold hover:bg-yellow-400">
          <PlusCircle size={16} /> Add Plan
        </button>
      </div>

      {/* FORM */}
      {showForm && (
        <div className="bg-white rounded-xl shadow p-6 border border-yellow-200">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-bold text-lg">{editPlan ? "Edit Plan" : "New Plan"}</h2>
            <button onClick={() => setShowForm(false)}><X size={20} /></button>
          </div>
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="text-xs text-gray-500 block mb-1">Plan Name</label>
              <input value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} required
                className="border rounded-lg px-3 py-2 w-full text-sm" placeholder="e.g. Scholar" />
            </div>
            <div>
              <label className="text-xs text-gray-500 block mb-1">Price (₹/month)</label>
              <input value={form.price} onChange={e => setForm({ ...form, price: e.target.value })} required type="number"
                className="border rounded-lg px-3 py-2 w-full text-sm" placeholder="e.g. 49" />
            </div>
            <div className="md:col-span-2">
              <label className="text-xs text-gray-500 block mb-1">Features (one per line)</label>
              <textarea value={form.features} onChange={e => setForm({ ...form, features: e.target.value })} rows={5} required
                className="border rounded-lg px-3 py-2 w-full text-sm" placeholder={"Daily Horoscopes\nBasic Birth Chart\nEmail Support"} />
            </div>
            <div className="flex items-center gap-4">
              <label className="flex items-center gap-2 text-sm cursor-pointer">
                <input type="checkbox" checked={form.is_popular} onChange={e => setForm({ ...form, is_popular: e.target.checked })} />
                Mark as Popular
              </label>
              <label className="flex items-center gap-2 text-sm cursor-pointer">
                <input type="checkbox" checked={form.is_active} onChange={e => setForm({ ...form, is_active: e.target.checked })} />
                Active
              </label>
            </div>
            <div className="flex justify-end">
              <button type="submit" className="flex items-center gap-2 bg-yellow-500 text-black px-5 py-2 rounded-lg font-semibold text-sm hover:bg-yellow-400">
                <Save size={16} /> {editPlan ? "Update Plan" : "Create Plan"}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* PLANS GRID */}
      {loading ? (
        <p className="text-gray-400">Loading plans...</p>
      ) : plans.length === 0 ? (
        <div className="bg-white rounded-xl shadow p-8 text-center text-gray-400">
          <p>No plans yet. Click "Add Plan" to create one.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
          {plans.map(plan => {
            const features = Array.isArray(plan.features) ? plan.features : JSON.parse(plan.features || "[]")
            return (
              <div key={plan.id} className={`bg-white rounded-2xl shadow p-6 border ${plan.is_popular ? "border-yellow-400" : "border-gray-100"}`}>
                {plan.is_popular && (
                  <span className="bg-yellow-500 text-black text-xs px-3 py-1 rounded-full mb-3 inline-block">Most Popular</span>
                )}
                <h3 className="text-xl font-bold">{plan.name}</h3>
                <p className="text-2xl font-extrabold text-yellow-600 my-2">₹{plan.price}<span className="text-sm font-normal text-gray-400">/month</span></p>
                <ul className="text-sm text-gray-600 space-y-1 mb-4">
                  {features.map((f, i) => <li key={i}>✔ {f}</li>)}
                </ul>
                <div className="flex items-center gap-2 mb-2">
                  <span className={`text-xs px-2 py-1 rounded-full ${plan.is_active ? "bg-green-100 text-green-700" : "bg-gray-100 text-gray-500"}`}>
                    {plan.is_active ? "Active" : "Inactive"}
                  </span>
                </div>
                <div className="flex gap-2 mt-3">
                  <button onClick={() => handleEdit(plan)} className="flex items-center gap-1 text-xs border px-3 py-1.5 rounded-lg hover:bg-yellow-50">
                    <Edit2 size={13} /> Edit
                  </button>
                  <button onClick={() => handleDelete(plan.id)} className="flex items-center gap-1 text-xs border px-3 py-1.5 rounded-lg text-red-500 hover:bg-red-50">
                    <Trash2 size={13} /> Delete
                  </button>
                </div>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}

export default SubscriptionPlans
