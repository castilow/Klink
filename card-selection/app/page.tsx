"use client"
import { motion } from "framer-motion"
import { X, Plus } from "lucide-react"
import { Button } from "@/components/ui/button"
import Image from "next/image"
import { useRouter } from "next/navigation"

export default function CardsListPage() {
  const router = useRouter()

  const cards = [
    {
      id: "visa-grey",
      name: "Space Grey",
      description: "··6878, 11/27",
      image: "/images/card_visa_grey.png",
      status: "active",
    },
    {
      id: "mastercard-gold",
      name: "Gold Premium",
      description: "··7374, 09/29",
      image: "/images/card_mastercard_gold.png",
      status: "active",
    },
    {
      id: "ultra-grey",
      name: "Ultra Platino",
      description: "··1982, 05/30",
      image: "/images/card_ultra_grey.png",
      status: "active",
    },
    {
      id: "mastercard-white",
      name: "Classic White",
      description: "··9252, 05/30",
      image: "/images/card_mastercard_white.png",
      status: "active",
      badge: "Principal",
    },
  ]

  return (
    <div className="min-h-screen bg-gray-50 text-gray-900">
      {/* Header */}
      <div className="flex items-center justify-between p-4 pt-12">
        <div
          className="w-10 h-10 bg-gray-100 rounded-xl border border-gray-200 flex items-center justify-center cursor-pointer hover:bg-gray-200 transition-colors duration-200"
          onClick={() => {
            // Handle close action
          }}
        >
          <X className="h-5 w-5 stroke-2 text-gray-700" />
        </div>
        <div className="flex items-center gap-2 text-sm text-gray-600"></div>
      </div>

      {/* Title */}
      <div className="px-6 mb-6">
        <h1 className="text-3xl font-bold">Tarjetas</h1>
      </div>

      {/* Cards List */}
      <div className="px-6 mb-6">
        <div className="bg-white rounded-3xl p-4 shadow-sm border border-gray-200">
          <div className="space-y-6">
            {cards.map((card, index) => (
              <motion.div
                key={card.id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.05 }}
                className="flex items-center gap-4 p-6 rounded-2xl hover:bg-gray-50 hover:scale-105 transition-transform cursor-pointer group"
              >
                {/* Card Image */}
                <div className="relative w-16 h-10 rounded-[5px] overflow-hidden bg-gray-100 flex-shrink-0 animate-pulse shadow-lg">
                  <Image src={card.image || "/placeholder.svg"} alt={card.name} fill className="object-cover" />
                  <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent animate-shimmer rounded-[5px]"></div>
                </div>

                {/* Card Info */}
                <div className="flex-1 min-w-0">
                  <h3 className="font-semibold text-gray-900 text-base">{card.name}</h3>
                  <p className="text-gray-600 text-sm">{card.description}</p>
                </div>

                {/* Badge or Arrow */}
                <div className="flex-shrink-0">
                  {card.badge ? (
                    <div className="bg-gray-200 text-gray-700 px-3 py-1 rounded-full text-xs font-medium">
                      {card.badge}
                    </div>
                  ) : null}
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </div>

      {/* Add Button */}
      <div className="px-6 mb-8">
        <Button
          onClick={() => router.push("/add-card")}
          className="w-full bg-white hover:bg-gray-50 text-gray-900 border border-gray-200 py-4 rounded-full text-base font-medium flex items-center justify-center gap-2"
        >
          <Plus className="h-5 w-5" />
          Añadir
        </Button>
      </div>
    </div>
  )
}
