import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// API para comunicarse con ChatGPT usando Firebase Functions (seguro)
abstract class ChatGPTApi {
  // Intentar primero con la región específica, luego con la instancia por defecto
  static final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  static final _functionsDefault = FirebaseFunctions.instance;

  /// Envía un mensaje a ChatGPT a través de Firebase Functions
  static Future<String?> sendMessage({
    required String message,
    List<Map<String, String>>? conversationHistory,
    String? imageBase64,
  }) async {
    try {
      debugPrint('🤖 ChatGPT: Enviando mensaje a Firebase Functions...');
      debugPrint('🤖 ChatGPT: Mensaje: $message');
      debugPrint('🤖 ChatGPT: Historial length: ${conversationHistory?.length ?? 0}');
      debugPrint('🤖 ChatGPT: Región configurada: us-central1');
      debugPrint('🤖 ChatGPT: Instancia de Functions: ${_functions.app.name}');
      
      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        debugPrint('🤖 ChatGPT: Primer mensaje del historial: ${conversationHistory.first}');
      }

      // Llamar a la función de Firebase
      final callData = <String, dynamic>{
        'message': message,
        'conversationHistory': conversationHistory ?? [],
      };
      
      // Agregar imagen si existe (enviar como 'image' y 'imageBase64' para compatibilidad)
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        // Limpiar el base64 si ya tiene el prefijo data:image
        String cleanBase64 = imageBase64;
        if (imageBase64.contains(',')) {
          cleanBase64 = imageBase64.split(',').last;
        }
        
        // Validar que el base64 sea válido
        final base64Regex = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
        final isValidBase64 = base64Regex.hasMatch(cleanBase64);
        debugPrint('🤖 ChatGPT: Base64 válido: $isValidBase64');
        debugPrint('🤖 ChatGPT: Base64 preview (primeros 50 chars): ${cleanBase64.substring(0, cleanBase64.length > 50 ? 50 : cleanBase64.length)}...');
        
        if (!isValidBase64) {
          debugPrint('⚠️ ChatGPT: El base64 no es válido, pero se enviará de todas formas');
        }
        
        callData['image'] = cleanBase64;
        callData['imageBase64'] = cleanBase64;
        debugPrint('🤖 ChatGPT: Incluyendo imagen en la petición (tamaño: ${cleanBase64.length} caracteres)');
        debugPrint('🤖 ChatGPT: callData keys: ${callData.keys}');
        debugPrint('🤖 ChatGPT: callData tiene image: ${callData.containsKey('image')}');
        debugPrint('🤖 ChatGPT: callData tiene imageBase64: ${callData.containsKey('imageBase64')}');
      } else {
        debugPrint('⚠️ ChatGPT: imageBase64 es null o vacío');
      }
      
      debugPrint('🤖 ChatGPT: Llamando a función chatWithAssistant...');
      debugPrint('🤖 ChatGPT: callData completo: ${callData.keys}');
      
      // Intentar primero con la región específica
      dynamic result;
      try {
        debugPrint('🤖 ChatGPT: Intentando con región us-central1...');
        result = await _functions
            .httpsCallable('chatWithAssistant')
            .call(callData).timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            debugPrint('🤖 ChatGPT: Timeout después de 60 segundos (us-central1)');
            throw TimeoutException('La petición tardó demasiado');
          },
        );
        debugPrint('🤖 ChatGPT: ✅ Éxito con región us-central1');
      } catch (e) {
        final errorString = e.toString().toLowerCase();
        debugPrint('🤖 ChatGPT: ❌ Error con región us-central1: $e');
        
        // Si el error es UNAVAILABLE, intentar con la instancia por defecto
        if (errorString.contains('unavailable') || errorString.contains('not-found')) {
          debugPrint('🤖 ChatGPT: Intentando con instancia por defecto...');
          try {
            result = await _functionsDefault
                .httpsCallable('chatWithAssistant')
                .call(callData).timeout(
              const Duration(seconds: 60),
              onTimeout: () {
                debugPrint('🤖 ChatGPT: Timeout después de 60 segundos (default)');
                throw TimeoutException('La petición tardó demasiado');
              },
            );
            debugPrint('🤖 ChatGPT: ✅ Éxito con instancia por defecto');
          } catch (e2) {
            debugPrint('🤖 ChatGPT: ❌ Error también con instancia por defecto: $e2');
            rethrow; // Re-lanzar el error original
          }
        } else {
          rethrow; // Re-lanzar el error si no es UNAVAILABLE
        }
      }

      debugPrint('🤖 ChatGPT: Respuesta recibida de Firebase');
      debugPrint('🤖 ChatGPT: Result data keys: ${(result.data as Map<String, dynamic>).keys}');
      debugPrint('🤖 ChatGPT: Result data: ${result.data}');

      // Extraer la respuesta
      final data = result.data as Map<String, dynamic>;
      final response = data['response'] as String?;
      final success = data['success'] as bool? ?? false;
      
      if (response != null) {
        final previewLength = response.length > 100 ? 100 : response.length;
        debugPrint('🤖 ChatGPT: Response: ${response.substring(0, previewLength)}...');
      }
      debugPrint('🤖 ChatGPT: Success: $success');

      if (success && response != null && response.isNotEmpty) {
        debugPrint('✅ ChatGPT: Respuesta exitosa');
        return response;
      } else {
        debugPrint('❌ ChatGPT: Respuesta sin éxito');
        return response ?? 'Lo siento, no pude procesar tu solicitud.';
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error al comunicarse con ChatGPT: $e');
      debugPrint('❌ Tipo de error: ${e.runtimeType}');
      debugPrint('❌ StackTrace: $stackTrace');
      
      // Detectar errores específicos de Firebase Functions
      final errorString = e.toString().toLowerCase();
      debugPrint('❌ Error string: $errorString');
      
      // Mensajes de error amigables
      if (errorString.contains('timeout') || e is TimeoutException) {
        debugPrint('❌ Error: Timeout');
        return 'La respuesta está tardando demasiado. Por favor, inténtalo de nuevo.';
      } else if (errorString.contains('unauthenticated') || errorString.contains('permission-denied')) {
        debugPrint('❌ Error: Autenticación');
        return 'Debes iniciar sesión para usar el asistente.';
      } else if (errorString.contains('unavailable') || errorString.contains('unavailable')) {
        debugPrint('❌ Error: Función no disponible (UNAVAILABLE)');
        debugPrint('❌ Esto puede significar:');
        debugPrint('   1. La función no está desplegada en Firebase');
        debugPrint('   2. Hay un problema de conectividad');
        debugPrint('   3. La función está en una región diferente');
        debugPrint('   4. Hay un problema con Firebase App Check');
        return 'El asistente no está disponible en este momento. Por favor, verifica tu conexión e inténtalo más tarde.';
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        debugPrint('❌ Error: Red');
        return 'Error de conexión. Verifica tu internet e inténtalo de nuevo.';
      } else if (errorString.contains('not-found')) {
        debugPrint('❌ Error: Función no encontrada');
        return 'La función del asistente no está disponible. Contacta al soporte.';
      }
      
      debugPrint('❌ Error genérico no categorizado');
      return 'Lo siento, ocurrió un error. Por favor, inténtalo más tarde.';
    }
  }

  /// Obtiene una respuesta rápida (sin historial)
  static Future<String?> getQuickResponse(String message) async {
    return await sendMessage(message: message);
  }

  /// Stream para respuestas en tiempo real (simulado)
  static Stream<String> sendMessageStream({
    required String message,
    List<Map<String, String>>? conversationHistory,
  }) async* {
    try {
      final response = await sendMessage(
        message: message,
        conversationHistory: conversationHistory,
      );
      
      if (response != null) {
        // Simular escritura progresiva
        final words = response.split(' ');
        String partial = '';
        
        for (int i = 0; i < words.length; i++) {
          partial += '${words[i]} ';
          yield partial.trim();
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
    } catch (e) {
      debugPrint('❌ Error en stream: $e');
    }
  }
}
