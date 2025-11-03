class CardModel {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final String status;
  final String? badge;
  final String? price;

  const CardModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.status,
    this.badge,
    this.price,
  });

  static List<CardModel> get sampleCards => [
    const CardModel(
      id: "visa-grey",
      name: "Space Grey",
      description: "··6878, 11/27",
      imagePath: "assets/images/cards/card_visa_grey.png",
      status: "active",
    ),
    const CardModel(
      id: "mastercard-gold",
      name: "Gold Premium",
      description: "··7374, 09/29",
      imagePath: "assets/images/cards/card_mastercard_gold.png",
      status: "active",
      price: "79,99 €",
    ),
    const CardModel(
      id: "ultra-grey",
      name: "Ultra Platino",
      description: "··1982, 05/30",
      imagePath: "assets/images/cards/card_ultra_grey.png",
      status: "active",
      price: "99,99 €",
    ),
    const CardModel(
      id: "mastercard-white",
      name: "Classic White",
      description: "··9252, 05/30",
      imagePath: "assets/images/cards/card_mastercard_white.png",
      status: "active",
      badge: "Principal",
      price: "39,99 €",
    ),
  ];

  static List<CardModel> get selectableCards => [
    const CardModel(
      id: "visa-grey",
      name: "Space Grey",
      description: "Nuestra tarjeta más elegante hasta la fecha: fabricada con ingeniería de precisión y diseñada para impresionar",
      imagePath: "assets/images/cards/card_visa_grey.png",
      status: "available",
      price: "49,99 €",
    ),
    const CardModel(
      id: "mastercard-gold",
      name: "Gold Premium",
      description: "Tarjeta premium con acabados dorados: diseñada para quienes buscan exclusividad y prestigio",
      imagePath: "assets/images/cards/card_mastercard_gold.png",
      status: "available",
      price: "79,99 €",
    ),
    const CardModel(
      id: "ultra-grey",
      name: "Ultra Platino",
      description: "Nuestra tarjeta más preciada hasta la fecha: fabricada con ingeniería de precisión y diseñada para impresionar",
      imagePath: "assets/images/cards/card_ultra_grey.png",
      status: "available",
      price: "99,99 €",
    ),
    const CardModel(
      id: "mastercard-white",
      name: "Classic White",
      description: "Diseño minimalista y elegante: perfecta para el uso diario con un toque de sofisticación",
      imagePath: "assets/images/cards/card_mastercard_white.png",
      status: "available",
      price: "39,99 €",
    ),
  ];
}