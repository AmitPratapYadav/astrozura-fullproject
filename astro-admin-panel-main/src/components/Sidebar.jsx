import { NavLink } from "react-router-dom";
import {
LayoutDashboard,
Star,
Users,
Calendar,
MessageCircle,
CreditCard,
FileText,
Settings,
User,
UserPlus,
X,
ShoppingCart,
Tags,
BadgeCheck,
Crown,
BookOpen,
PackageCheck
} from "lucide-react";
import logo from "../assets/astrozura-logo.png";

function Sidebar({ isOpen, onClose }) {

const menu = [

{ name:"Dashboard", icon:LayoutDashboard, path:"/dashboard"},
{ name:"Astrologers", icon:Star, path:"/astrologers"},
{ name:"Add Astrologer", icon:UserPlus, path:"/add-astrologer"},
{ name:"Users", icon:Users, path:"/users"},
{ name:"Bookings", icon:Calendar, path:"/bookings"},
{ name:"Consultations", icon:MessageCircle, path:"/consultations"},
{ name:"Payments", icon:CreditCard, path:"/payments"},
{ name:"Reports", icon:FileText, path:"/reports"},
{ name:"Reviews", icon:Star, path:"/reviews"},
{ name:"Settings", icon:Settings, path:"/settings"}

]

const ecommMenu = [
{ name:"Categories", icon:Tags, path:"/categories"},
{ name:"Products", icon:ShoppingCart, path:"/products"},
{ name:"Orders", icon:PackageCheck, path:"/orders"},
{ name:"Rituals", icon:BookOpen, path:"/rituals"},
]

const subscriptionMenu = [
{ name:"Plans Manager", icon:Crown, path:"/subscription-plans"},
{ name:"Subscribers", icon:BadgeCheck, path:"/user-subscriptions"},
]

return(

<>

{isOpen && (
<div
className="fixed inset-0 bg-black/40 z-40 md:hidden"
onClick={onClose}
/>
)}

<div
className={`fixed md:static top-0 left-0 z-50
h-screen w-64 bg-black text-white
flex flex-col
transform transition-transform duration-300
${isOpen ? "translate-x-0" : "-translate-x-full"}
md:translate-x-0`}
>

<div className="relative flex items-center gap-3 p-4 border-b border-gray-800">
<img src={logo} alt="AstroZura" className="h-11 w-11 rounded-full object-contain" />
<div>
  <h1 className="text-base font-bold text-yellow-500">AstroZura</h1>
  <p className="text-[10px] uppercase tracking-[0.2em] text-gray-500">Admin Panel</p>
</div>

<button
className="absolute right-4 md:hidden"
onClick={onClose}
>
<X size={22}/>
</button>

</div>

<div className="flex-1 overflow-y-auto p-3 space-y-2">

{menu.map((item,index)=>{

const Icon = item.icon

return(

<NavLink
key={index}
to={item.path}
onClick={onClose}
className={({isActive})=>
`flex items-center gap-3 px-4 py-3 rounded-lg text-sm font-medium transition
${isActive
? "bg-yellow-500 text-black"
: "text-gray-400 hover:bg-yellow-500 hover:text-black"}`
}
>

<Icon size={18}/>
{item.name}

</NavLink>

)

})}

<div className="pt-4 pb-2 px-4 mt-2">
  <p className="text-sm font-bold text-gray-300 uppercase tracking-wider">E-Commerce</p>
</div>

      {ecommMenu.map((item,index)=>{
        const Icon = item.icon
        return(
          <NavLink
            key={`ecomm-${index}`}
            to={item.path}
            onClick={onClose}
            className={({isActive})=>
              `flex items-center gap-3 px-4 py-3 rounded-lg text-sm font-medium transition
              ${isActive
                ? "bg-yellow-500 text-black"
                : "text-gray-400 hover:bg-yellow-500 hover:text-black"}`
            }
          >
            <Icon size={18}/>
            {item.name}
          </NavLink>
        )
      })}

      <div className="pt-4 pb-2 px-4 mt-2">
        <p className="text-sm font-bold text-gray-300 uppercase tracking-wider">Subscriptions</p>
      </div>

      {subscriptionMenu.map((item,index)=>{
        const Icon = item.icon
        return(
          <NavLink
            key={`sub-${index}`}
            to={item.path}
            onClick={onClose}
            className={({isActive})=>
              `flex items-center gap-3 px-4 py-3 rounded-lg text-sm font-medium transition
              ${isActive
                ? "bg-yellow-500 text-black"
                : "text-gray-400 hover:bg-yellow-500 hover:text-black"}`
            }
          >
            <Icon size={18}/>
            {item.name}
          </NavLink>
        )
      })}
    </div>

<div className="p-3 border-t border-gray-800">

<NavLink
to="/profile"
className="flex items-center gap-3 px-4 py-3 rounded-lg text-gray-400 hover:bg-yellow-500 hover:text-black transition"
>

<User size={18}/>
Admin Profile

</NavLink>

</div>

</div>

</>

)

}

export default Sidebar
