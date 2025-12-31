import 'dart:io';
import 'package:flutter/material.dart';

enum OverlayType { text, image }

class StoryOverlay {
  final String id;
  final OverlayType type;
  Offset position;
  double scale;
  double rotation;
  
  // Specific properties
  String? text;
  TextStyle? textStyle;
  TextAlign textAlign;
  bool showBackground;
  double fontSize;
  File? imageFile;
  Color? color;

  StoryOverlay({
    required this.id,
    required this.type,
    this.position = Offset.zero,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.text,
    this.textStyle,
    this.textAlign = TextAlign.center,
    this.showBackground = false,
    this.fontSize = 28.0,
    this.imageFile,
    this.color,
  });
}
