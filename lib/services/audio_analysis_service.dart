import 'dart:io';
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class AudioAnalysisService {
  static const int _sampleRate = 44100;
  static const int _frameSize = 1024;
  static const double _minAmplitudeThreshold = 0.01; // Umbral mínimo de amplitud
  
  /// Analiza un archivo de audio y extrae datos de amplitud por frame
  static Future<List<double>> analyzeAudioFile(String audioPath) async {
    try {
      // Crear un player temporal para análisis
      final player = AudioPlayer();
      
      // Cargar el audio
      if (audioPath.startsWith('http')) {
        await player.setUrl(audioPath);
      } else {
        await player.setFilePath(audioPath);
      }
      
      // Obtener la duración
      final duration = await player.duration;
      if (duration == null || duration.inMilliseconds <= 0) {
        await player.dispose();
        return [];
      }
      
      // Calcular número de frames
      final totalFrames = (duration.inMilliseconds / (_frameSize * 1000 / _sampleRate)).ceil();
      final List<double> amplitudes = [];
      
      // Analizar cada frame
      for (int i = 0; i < totalFrames; i++) {
        final frameStart = Duration(milliseconds: (i * _frameSize * 1000 / _sampleRate).round());
        final frameEnd = Duration(milliseconds: ((i + 1) * _frameSize * 1000 / _sampleRate).round());
        
        // Extraer datos de audio para este frame
        final amplitude = await _extractFrameAmplitude(player, frameStart, frameEnd);
        amplitudes.add(amplitude);
      }
      
      await player.dispose();
      return amplitudes;
      
    } catch (e) {
      print('Error analyzing audio: $e');
      return [];
    }
  }
  
  /// Extrae la amplitud promedio de un frame específico
  static Future<double> _extractFrameAmplitude(AudioPlayer player, Duration start, Duration end) async {
    try {
      // Simular extracción de datos de audio
      // En una implementación real, aquí se extraerían los datos PCM del frame
      
      // Por ahora, simulamos basándonos en la posición del frame
      final framePosition = start.inMilliseconds / (end.inMilliseconds - start.inMilliseconds);
      
      // Simular diferentes patrones de amplitud basados en la posición
      double amplitude = 0.0;
      
      // Patrón de voz humana típico
      if (framePosition < 0.2) {
        // Inicio con voz suave
        amplitude = 0.3 + (framePosition * 0.4);
      } else if (framePosition < 0.4) {
        // Silencio
        amplitude = 0.0;
      } else if (framePosition < 0.7) {
        // Voz fuerte
        amplitude = 0.6 + (framePosition * 0.3);
      } else if (framePosition < 0.9) {
        // Silencio
        amplitude = 0.0;
      } else {
        // Final con voz
        amplitude = 0.4 * (1.0 - framePosition);
      }
      
      // Agregar variaciones aleatorias para simular audio real
      amplitude += (DateTime.now().millisecondsSinceEpoch % 100) / 1000.0;
      
      // Aplicar umbral mínimo
      if (amplitude < _minAmplitudeThreshold) {
        amplitude = 0.0;
      }
      
      return amplitude.clamp(0.0, 1.0);
      
    } catch (e) {
      return 0.0;
    }
  }
  
  /// Descarga un archivo de audio desde URL y lo analiza
  static Future<List<double>> analyzeAudioFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        
        final amplitudes = await analyzeAudioFile(file.path);
        
        // Limpiar archivo temporal
        try {
          await file.delete();
        } catch (e) {
          // Ignorar errores de limpieza
        }
        
        return amplitudes;
      }
    } catch (e) {
      print('Error downloading audio: $e');
    }
    return [];
  }
  
  /// Valida si el audio tiene contenido útil
  static bool hasValidAudioContent(List<double> amplitudes) {
    if (amplitudes.isEmpty) return false;
    
    // Verificar que haya al menos algunas amplitudes significativas
    final significantAmplitudes = amplitudes.where((amp) => amp > _minAmplitudeThreshold).length;
    if (significantAmplitudes < (amplitudes.length * 0.1)) {
      return false;
    }
    
    // Verificar que el promedio esté por encima del umbral
    final averageAmplitude = amplitudes.reduce((a, b) => a + b) / amplitudes.length;
    if (averageAmplitude < _minAmplitudeThreshold) {
      return false;
    }
    
    return true;
  }
  
  /// Genera datos de waveform para visualización
  static List<double> generateWaveformData(List<double> amplitudes, int numBars) {
    if (amplitudes.isEmpty) return List.filled(numBars, 0.0);
    
    final List<double> waveform = [];
    final int samplesPerBar = (amplitudes.length / numBars).ceil();
    
    for (int i = 0; i < numBars; i++) {
      final startIndex = i * samplesPerBar;
      final endIndex = (i + 1) * samplesPerBar;
      
      // Calcular amplitud promedio para esta barra
      double barAmplitude = 0.0;
      int validSamples = 0;
      
      for (int j = startIndex; j < endIndex && j < amplitudes.length; j++) {
        if (amplitudes[j] > _minAmplitudeThreshold) {
          barAmplitude += amplitudes[j];
          validSamples++;
        }
      }
      
      // Calcular promedio de amplitud para esta barra
      if (validSamples > 0) {
        barAmplitude = barAmplitude / validSamples;
      } else {
        barAmplitude = 0.0;
      }
      
      waveform.add(barAmplitude.clamp(0.0, 1.0));
    }
    
    return waveform;
  }
} 