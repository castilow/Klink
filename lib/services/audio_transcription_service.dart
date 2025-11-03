import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:speech_to_text/speech_to_text.dart';

class AudioTranscriptionService {
  static final AudioTranscriptionService _instance = AudioTranscriptionService._internal();
  factory AudioTranscriptionService() => _instance;
  AudioTranscriptionService._internal();

  // Speech to Text instance
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;

  /// Transcribe un archivo de audio usando Speech-to-Text
  Future<String?> transcribeAudioFile(String audioFilePath) async {
    try {
      debugPrint('🎤 Iniciando transcripción de: $audioFilePath');

      // Verificar que el archivo existe
      final File audioFile = File(audioFilePath);
      if (!await audioFile.exists()) {
        debugPrint('❌ Archivo de audio no encontrado: $audioFilePath');
        return null;
      }

      // Por ahora, usar transcripción simulada
      // En una implementación completa, usarías speech_to_text para transcribir
      return getSimulatedTranscription(audioFilePath);

    } catch (e) {
      debugPrint('❌ Error en transcripción: $e');
      return 'Error procesando el audio. Intenta más tarde.';
    }
  }

  /// Transcribe audio desde una URL
  Future<String?> transcribeAudioFromUrl(String audioUrl) async {
    try {
      debugPrint('🎤 Iniciando transcripción desde URL: $audioUrl');
      
      // Por ahora, usar transcripción simulada
      return getSimulatedTranscription(audioUrl);
      
    } catch (e) {
      debugPrint('❌ Error transcribiendo desde URL: $e');
      return null;
    }
  }

  /// Verifica si el servicio de transcripción está disponible
  Future<bool> isTranscriptionAvailable() async {
    // Por ahora, siempre devolvemos true
    // En una implementación real, verificarías la conectividad y la API key
    return true;
  }

  /// Obtiene una transcripción simulada para pruebas
  String getSimulatedTranscription(String audioPath) {
    // Simular diferentes transcripciones basadas en el nombre del archivo
    final String fileName = audioPath.split('/').last.toLowerCase();
    
    if (fileName.contains('hola') || fileName.contains('hello')) {
      return 'Hola, ¿cómo estás? Espero que tengas un buen día.';
    } else if (fileName.contains('gracias') || fileName.contains('thanks')) {
      return 'Muchas gracias por tu mensaje. Te agradezco mucho.';
    } else if (fileName.contains('reunion') || fileName.contains('meeting')) {
      return 'Necesitamos programar una reunión para discutir el proyecto.';
    } else if (fileName.contains('trabajo') || fileName.contains('work')) {
      return 'El trabajo está progresando bien. Hemos completado la primera fase.';
    } else {
      return 'Este es un mensaje de voz transcrito. La transcripción real aparecerá cuando el servicio esté completamente configurado.';
    }
  }
} 