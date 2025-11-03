"use client"
import { motion } from "framer-motion"
import { ArrowLeft } from "lucide-react"
import { useState } from "react"
import Image from "next/image"
import { useRouter } from "next/navigation"

export default function AddCardPage() {
  const [activeTab, setActiveTab] = useState("debito")
  const router = useRouter()

  const cardTypes = [
    {
      id: "fisica",
      name: "Física",
      description: "Elige tu diseño de tarjeta favorito o personalízala",
      image: "/images/card_visa_grey.png",
    },
    {
      id: "virtual",
      name: "Virtual",
      description: "Nuestra tarjeta virtual gratuita y segura que no volverás a perder",
      image: "/images/card_mastercard_gold.png",
    },
    {
      id: "desechable",
      name: "Desechable",
      description: "Sus datos se vuelven a generar después de cada uso para garantizar más seguridad",
      image: "/images/card_ultra_grey.png",
    },
  ]

  return (
    <div className="min-h-screen bg-white text-gray-900">
      {/* Header */}
      <div className="flex items-center p-4 pt-12">
        <div
          className="w-10 h-10 bg-gray-100 rounded-xl border border-gray-200 flex items-center justify-center cursor-pointer hover:bg-gray-200 transition-colors duration-200"
          onClick={() => {
            // Handle back navigation
            window.history.back()
          }}
        >
          <ArrowLeft className="h-5 w-5 stroke-2 text-gray-700" />
        </div>
      </div>

      {/* Title */}
      <div className="px-6 mb-8">
        <h1 className="text-3xl font-bold">Escoge tus tarjetas</h1>
      </div>

      {/* Tabs */}
      <div className="px-6 mb-8">
        <div className="flex gap-2">
          <div
            onClick={() => setActiveTab("debito")}
            className="w-20 h-10 bg-gray-100 rounded-xl border border-gray-200 flex items-center justify-center cursor-pointer hover:bg-gray-200 transition-colors duration-200"
          >
            <span className="text-gray-700 text-sm font-medium">Débito</span>
          </div>
        </div>
      </div>

      {/* Card Types */}
      <div className="px-6 mb-8">
        <div className="space-y-4">
          {cardTypes.map((cardType, index) => (
            <motion.div
              key={cardType.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              className="bg-white rounded-3xl p-6 cursor-pointer hover:bg-gray-50 transition-colors border border-gray-200 shadow-sm"
              onClick={() => {
                router.push("/select-card")
              }}
            >
              <div className="flex items-center gap-4">
                {/* Card Image */}
                <div className="relative w-16 h-10 rounded-[5px] overflow-hidden bg-gray-100 flex-shrink-0 animate-pulse shadow-lg">
                  <Image src={cardType.image || "/placeholder.svg"} alt={cardType.name} fill className="object-cover" />
                  <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent animate-shimmer rounded-[5px]"></div>
                </div>

                {/* Content */}
                <div className="flex-1">
                  <h3 className="text-gray-900 font-semibold text-lg mb-1">{cardType.name}</h3>
                  <p className="text-gray-600 text-sm leading-relaxed">{cardType.description}</p>
                </div>

                {/* Arrow */}
                <div className="text-gray-400">
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                  </svg>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Link Existing Card */}
      <div className="px-6 mb-8">
        <button className="text-gray-600 text-sm font-medium hover:text-gray-800 transition-colors">
          ¿Tienes una tarjeta? Vincular ahora
        </button>
      </div>
    </div>
  )
}
