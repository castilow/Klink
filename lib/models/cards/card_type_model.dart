class CardTypeModel {
  final String id;
  final String name;
  final String description;
  final String imagePath;

  const CardTypeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
  });

  static List<CardTypeModel> get cardTypes => [
    const CardTypeModel(
      id: "fisica",
      name: "Física",
      description: "Elige tu diseño de tarjeta favorito o personalízala",
      imagePath: "assets/images/cards/card_visa_grey.png",
    ),
    const CardTypeModel(
      id: "virtual",
      name: "Virtual",
      description: "Nuestra tarjeta virtual gratuita y segura que no volverás a perder",
      imagePath: "assets/images/cards/card_mastercard_gold.png",
    ),
    const CardTypeModel(
      id: "desechable",
      name: "Desechable",
      description: "Sus datos se vuelven a generar después de cada uso para garantizar más seguridad",
      imagePath: "assets/images/cards/card_ultra_grey.png",
    ),
  ];
}