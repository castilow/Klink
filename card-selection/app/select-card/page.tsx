"use client"
import { motion, AnimatePresence } from "framer-motion"
import { ArrowLeft } from "lucide-react"
import { useState } from "react"
import Image from "next/image"
import { Button } from "@/components/ui/button"

export default function SelectCardPage() {
  const [currentCardIndex, setCurrentCardIndex] = useState(0)

  const cards = [
    {
      id: "visa-grey",
      name: "Space Grey",
      description:
        "Nuestra tarjeta más elegante hasta la fecha: fabricada con ingeniería de precisión y diseñada para impresionar",
      image: "/images/card_visa_grey.png",
      price: "49,99 €",
    },
    {
      id: "mastercard-gold",
      name: "Gold Premium",
      description: "Tarjeta premium con acabados dorados: diseñada para quienes buscan exclusividad y prestigio",
      image: "/images/card_mastercard_gold.png",
      price: "79,99 €",
    },
    {
      id: "ultra-grey",
      name: "Ultra Platino",
      description:
        "Nuestra tarjeta más preciada hasta la fecha: fabricada con ingeniería de precisión y diseñada para impresionar",
      image: "/images/card_ultra_grey.png",
      price: "99,99 €",
    },
    {
      id: "mastercard-white",
      name: "Classic White",
      description: "Diseño minimalista y elegante: perfecta para el uso diario con un toque de sofisticación",
      image: "/images/card_mastercard_white.png",
      price: "39,99 €",
    },
  ]

  const nextCard = () => {
    setCurrentCardIndex((prev) => (prev + 1) % cards.length)
  }

  const prevCard = () => {
    setCurrentCardIndex((prev) => (prev - 1 + cards.length) % cards.length)
  }

  const currentCard = cards[currentCardIndex]

  return (
    <div className="min-h-screen bg-gray-50 text-gray-900">
      {/* Header */}
      <div className="flex items-center p-4 pt-12">
        <div
          className="w-10 h-10 bg-gray-100 rounded-xl border border-gray-200 flex items-center justify-center cursor-pointer hover:bg-gray-200 transition-colors duration-200"
          onClick={() => {
            window.history.back()
          }}
        >
          <ArrowLeft className="h-5 w-5 stroke-2 text-gray-700" />
        </div>
      </div>

      {/* Card Display */}
      <div className="flex-1 flex flex-col items-center justify-center px-6 py-8">
        {/* Card Container */}
        <div className="relative w-64 h-40 mb-8 cursor-pointer" onClick={nextCard} style={{ perspective: "1000px" }}>
          <AnimatePresence mode="wait">
            <motion.div
              key={currentCardIndex}
              initial={{ rotateY: 180, opacity: 0 }}
              animate={{ rotateY: 0, opacity: 1 }}
              exit={{ rotateY: -180, opacity: 0 }}
              transition={{ duration: 0.8, ease: "easeInOut" }}
              className="absolute inset-0 transform-style-preserve-3d backface-visibility-hidden"
            >
              <div className="w-full h-full rounded-2xl overflow-hidden shadow-2xl relative">
                <Image
                  src={currentCard.image || "/placeholder.svg"}
                  alt={currentCard.name}
                  fill
                  className="object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/30 to-transparent animate-shimmer rounded-2xl"></div>
              </div>
            </motion.div>
          </AnimatePresence>
        </div>

        {/* Card Info */}
        <div className="text-center mb-8 max-w-sm">
          <motion.h2
            key={`title-${currentCardIndex}`}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
            className="text-2xl font-bold mb-4"
          >
            {currentCard.name}
          </motion.h2>
          <motion.p
            key={`desc-${currentCardIndex}`}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4 }}
            className="text-gray-600 text-sm leading-relaxed"
          >
            {currentCard.description}
          </motion.p>
        </div>

        {/* Navigation Dots */}
        <div className="flex gap-2 mb-8">
          {cards.map((_, index) => (
            <button
              key={index}
              onClick={() => setCurrentCardIndex(index)}
              className={`w-2 h-2 rounded-full transition-colors duration-200 ${
                index === currentCardIndex ? "bg-gray-800" : "bg-gray-300"
              }`}
            />
          ))}
        </div>

        {/* Swipe Indicator */}
        <div className="w-12 h-12 bg-gray-100 rounded-full border border-gray-200 flex items-center justify-center mb-8">
          <div className="w-6 h-6 bg-gray-400 rounded-full"></div>
        </div>
      </div>

      {/* Swipe Gestures */}
      <div
        className="fixed inset-0 z-10 pointer-events-none"
        onTouchStart={(e) => {
          e.currentTarget.style.pointerEvents = "auto"
          const touch = e.touches[0]
          const startX = touch.clientX

          const handleTouchMove = (moveEvent: TouchEvent) => {
            moveEvent.preventDefault()
          }

          const handleTouchEnd = (endEvent: TouchEvent) => {
            const endTouch = endEvent.changedTouches[0]
            const endX = endTouch.clientX
            const diff = startX - endX

            if (Math.abs(diff) > 50) {
              if (diff > 0) {
                nextCard() // Swipe left - next card
              } else {
                prevCard() // Swipe right - previous card
              }
            }

            document.removeEventListener("touchmove", handleTouchMove)
            document.removeEventListener("touchend", handleTouchEnd)
            e.currentTarget.style.pointerEvents = "none"
          }

          document.addEventListener("touchmove", handleTouchMove, { passive: false })
          document.addEventListener("touchend", handleTouchEnd)
        }}
      />

      {/* Order Button */}
      <div className="px-6 pb-8">
        <Button className="w-full bg-white hover:bg-gray-50 text-gray-900 border border-gray-200 py-4 rounded-full text-base font-medium shadow-sm">
          Pedir tarjeta por {currentCard.price}
        </Button>
      </div>
    </div>
  )
}
