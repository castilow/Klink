import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:chat_messenger/main.dart' as main;
import 'package:chat_messenger/config/app_config.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/services/push_notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Servicio para manejar llamadas usando ZEGOCLOUD oficial
class ZegoCallService extends GetxController {
  static ZegoCallService get instance => Get.find<ZegoCallService>();
  
  // Call state
  final RxBool isInCall = RxBool(false);
  final RxString currentCallId = RxString('');
  final RxString currentCalleeId = RxString('');
  final RxString currentCallerName = RxString('');
  
  // Estado de disponibilidad de ZEGOCLOUD
  bool _isZegoCloudAvailable = true;
  
  // Callbacks públicos para CallController
  VoidCallback? onCallAnswered;
  VoidCallback? onCallEnded;
  VoidCallback? onCallRejected;
  VoidCallback? onUserJoined;
  VoidCallback? onUserLeft;
  
  // Timer para timeout de llamadas
  Timer? _callTimeoutTimer;

  @override
  void onInit() {
    super.onInit();
    // No inicializar ZEGOCLOUD aquí, esperar a que el usuario esté autenticado
  }

  /// Verificar permisos sin solicitarlos (para inicialización)
  Future<bool> _checkCallPermissions() async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 Verificando permisos existentes...');
      }
      
      // Solo verificar, no solicitar permisos aún
      final micStatus = await Permission.microphone.status;
      final cameraStatus = await Permission.camera.status;
      
      if (kDebugMode) {
        debugPrint('🎤 Estado micrófono: $micStatus');
        debugPrint('📹 Estado cámara: $cameraStatus');
      }
      
      // Siempre permitir inicialización - los permisos se solicitarán después
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error verificando permisos: $e');
      }
      return true; // Permitir inicialización aunque haya error
    }
  }

  /// Inicializa ZEGOCLOUD cuando el usuario esté autenticado
  Future<void> initializeWhenUserAuthenticated() async {
    try {
      // PASO 1: Verificar permisos (sin solicitar)
      final hasPermissions = await _checkCallPermissions();
      if (!hasPermissions) {
        if (kDebugMode) {
          debugPrint('❌ Error verificando permisos');
        }
        _isZegoCloudAvailable = false;
        return;
      }
      
      // PASO 2: Inicializar ZEGOCLOUD con timeout
      await _initializeZegoCloud().timeout(
        const Duration(seconds: 60), // Aumentar timeout para signaling
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('⏰ Timeout de inicialización ZEGOCLOUD después de 60 segundos');
            debugPrint('🔄 Intentando inicializar sin signaling como fallback...');
          }
          throw TimeoutException('ZEGOCLOUD initialization timeout', const Duration(seconds: 60));
        },
      );
      
      if (kDebugMode) {
        debugPrint('✅ ZEGOCLOUD inicializado correctamente con signaling');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error inicializando ZEGOCLOUD después de autenticación: $e');
        debugPrint('🔄 Intentando inicializar en modo básico...');
      }
      
      // Intentar inicializar sin signaling como fallback
      try {
        await _initializeZegoCloudBasic();
        if (kDebugMode) {
          debugPrint('✅ ZEGOCLOUD inicializado en modo básico (sin invitaciones)');
        }
      } catch (fallbackError) {
        if (kDebugMode) {
          debugPrint('❌ Error en inicialización de fallback: $fallbackError');
          debugPrint('⚠️ ZEGOCLOUD no disponible - llamadas deshabilitadas');
        }
        
        // Marcar que ZEGOCLOUD no está disponible
        _isZegoCloudAvailable = false;
      }
    }
  }

  @override
  void onClose() {
    _callTimeoutTimer?.cancel();
    uninit();
    super.onClose();
  }

  /// Inicializa ZEGOCLOUD UIKit
  Future<void> _initializeZegoCloud() async {
    try {
      final User currentUser = AuthController.instance.currentUser;
      
      if (kDebugMode) {
        debugPrint('🎯 Inicializando ZEGOCLOUD para: ${currentUser.fullname}');
        debugPrint('🎯 UserID: ${currentUser.userId}');
        debugPrint('🎯 AppID: ${AppConfig.zegoAppID}');
        debugPrint('🎯 AppSign: ${AppConfig.zegoAppSign.substring(0, 20)}...');
        debugPrint('🎯 AppSign length: ${AppConfig.zegoAppSign.length}');
      }
      
      // Inicializar ZEGO UIKit con signaling plugin
      await ZegoUIKitPrebuiltCallInvitationService().init(
        appID: AppConfig.zegoAppID,
        appSign: AppConfig.zegoAppSign,
        userID: currentUser.userId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ''), // Limpiar caracteres especiales
        userName: currentUser.fullname.isNotEmpty ? currentUser.fullname : 'User',
        plugins: [ZegoUIKitSignalingPlugin()], // Necesario para invitaciones de llamada
        requireConfig: (ZegoCallInvitationData data) {
          final config = (data.invitees.length > 1)
              ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
              : (data.type == ZegoCallInvitationType.videoCall)
                  ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                  : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();
          
          // 🎨 DISEÑO ELEGANTE Y MODERNO - WHATSAPP STYLE
          
          // Configurar botones de la barra inferior con orden elegante
          if (data.type == ZegoCallInvitationType.videoCall) {
            config.bottomMenuBar.buttons = [
              ZegoCallMenuBarButtonName.toggleMicrophoneButton,
              ZegoCallMenuBarButtonName.toggleCameraButton,
              ZegoCallMenuBarButtonName.hangUpButton,
              ZegoCallMenuBarButtonName.switchCameraButton,
              ZegoCallMenuBarButtonName.switchAudioOutputButton,
            ];
          } else {
            // Para llamadas de voz - diseño minimalista
            config.bottomMenuBar.buttons = [
              ZegoCallMenuBarButtonName.toggleMicrophoneButton,
              ZegoCallMenuBarButtonName.hangUpButton,
              ZegoCallMenuBarButtonName.switchAudioOutputButton,
            ];
          }
          
          // Configurar estilo de la barra de botones
          config.bottomMenuBar.backgroundColor = Colors.transparent;
          config.bottomMenuBar.height = 100;
          config.bottomMenuBar.margin = const EdgeInsets.only(bottom: 30);
          
          // Configurar visibilidad
          config.bottomMenuBar.isVisible = true;

          // 🔊 CONFIGURACIÓN DE AUDIO MEJORADA
          config.turnOnCameraWhenJoining = data.type == ZegoCallInvitationType.videoCall;
          config.turnOnMicrophoneWhenJoining = true; // SIEMPRE activar micrófono
          config.useSpeakerWhenJoining = data.type == ZegoCallInvitationType.videoCall;
          
          // Configuración avanzada de audio
          config.audioVideoView.useVideoViewAspectFill = true;
          config.audioVideoView.isVideoMirror = false;
          
          // Configurar comportamiento de la llamada
          config.duration.isVisible = true;
          
          // Configurar topbar con información elegante
          config.topMenuBar.isVisible = true;
          config.topMenuBar.backgroundColor = Colors.transparent;
          config.topMenuBar.height = 80;
          
          // Configurar fondo elegante para llamadas de voz (Blurred style)
          if (data.type == ZegoCallInvitationType.voiceCall) {
            config.background = Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0F1C24), // Dark background
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                ),
              ),
            );
          }
          
          // Configurar estilo del avatar para llamadas de voz
          config.avatarBuilder = (context, size, user, extraInfo) {
            return Container(
              width: size.width * 0.4, // Smaller avatar
              height: size.width * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade800,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipOval(
                child: Center(
                  child: Text(
                    user?.name?.isNotEmpty == true 
                        ? user!.name!.substring(0, 1).toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: size.width * 0.15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          };

          return config;
        },
        notificationConfig: ZegoCallInvitationNotificationConfig(
          // Configurar sonidos personalizados si los tienes
          // incomingCallRingtone: 'assets/sounds/phone-calling.mp3',
          // outgoingCallRingtone: 'assets/sounds/phone-calling.mp3',
        ),
        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (event, defaultAction) {
            if (kDebugMode) {
              debugPrint('📞 Llamada terminada');
              debugPrint('📞 Razón: ${event.reason}');
            }
            
            // Verificar si la llamada fue cancelada o expirada
            // Las razones comunes incluyen: canceled, timeout, rejected
            final reason = event.reason?.toString().toLowerCase() ?? '';
            if (reason.contains('cancel') || reason.contains('timeout') || reason.contains('reject')) {
              if (kDebugMode) {
                debugPrint('📞 Llamada cancelada/rechazada/expirada');
              }
              onCallRejected?.call();
            } else {
              onCallEnded?.call();
            }
            
            _onCallEnded();
            defaultAction.call();
          },
          onError: (error) {
            if (kDebugMode) {
              debugPrint('❌ Error en ZEGOCLOUD: $error');
            }
          },
        ),
      );
      
      // CRÍTICO: Configurar el navigator key para que las llamadas se abran correctamente
      ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(main.navigatorKey);
      
      if (kDebugMode) {
        debugPrint('✅ ZEGOCLOUD inicializado correctamente');
        debugPrint('✅ Navigator key configurado para llamadas');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error inicializando ZEGOCLOUD: $e');
        debugPrint('❌ Stack trace: $stackTrace');
      }
      rethrow; // Re-lanzar el error para que se pueda manejar en el nivel superior
    }
  }

  /// Inicializa ZEGOCLOUD en modo básico (sin signaling) como fallback
  Future<void> _initializeZegoCloudBasic() async {
    try {
      final User currentUser = AuthController.instance.currentUser;
      
      if (kDebugMode) {
        debugPrint('🔄 Inicializando ZEGOCLOUD en modo básico para: ${currentUser.fullname}');
      }
      
      // Inicializar ZEGO UIKit sin signaling plugin
      await ZegoUIKitPrebuiltCallInvitationService().init(
        appID: AppConfig.zegoAppID,
        appSign: AppConfig.zegoAppSign,
        userID: currentUser.userId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ''),
        userName: currentUser.fullname.isNotEmpty ? currentUser.fullname : 'User',
        plugins: [], // Sin signaling plugin para modo básico
        requireConfig: (ZegoCallInvitationData data) {
          final config = (data.invitees.length > 1)
              ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
              : (data.type == ZegoCallInvitationType.videoCall)
                  ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                  : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

          // Configuración básica para modo fallback
          config.bottomMenuBar.buttons = [
            ZegoCallMenuBarButtonName.hangUpButton,
            ZegoCallMenuBarButtonName.toggleMicrophoneButton,
            ZegoCallMenuBarButtonName.switchAudioOutputButton,
          ];

          return config;
        },
      );

      if (kDebugMode) {
        debugPrint('✅ ZEGOCLOUD modo básico inicializado correctamente');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error inicializando ZEGOCLOUD modo básico: $e');
      }
      rethrow;
    }
  }

  /// Solicitar permisos justo antes de iniciar llamada
  Future<bool> _ensureCallPermissions() async {
    try {
      final micStatus = await Permission.microphone.status;
      
      if (micStatus.isDenied) {
        if (kDebugMode) {
          debugPrint('🎤 Solicitando permiso de micrófono...');
        }
        final result = await Permission.microphone.request();
        return result.isGranted;
      }
      
      return micStatus.isGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error verificando permisos: $e');
      }
      return false;
    }
  }

  /// Iniciar llamada de voz
  Future<void> startVoiceCall({
    required User targetUser,
  }) async {
    try {
      if (!_isZegoCloudAvailable) {
        if (kDebugMode) {
          debugPrint('❌ ZEGOCLOUD no está disponible');
        }
        throw Exception('ZEGOCLOUD no está disponible');
      }
      
      // Verificar permisos justo antes de la llamada
      final hasPermissions = await _ensureCallPermissions();
      if (!hasPermissions) {
        if (kDebugMode) {
          debugPrint('❌ Permisos de micrófono requeridos para llamadas');
        }
        throw Exception('Permisos de micrófono requeridos');
      }
      
      if (isInCall.value) {
        if (kDebugMode) {
          debugPrint('⚠️ Ya hay una llamada en curso');
        }
        return;
      }

      currentCallId.value = 'voice_${DateTime.now().millisecondsSinceEpoch}';
      currentCalleeId.value = targetUser.userId;
      currentCallerName.value = targetUser.fullname;
      isInCall.value = true;
      
      if (kDebugMode) {
        debugPrint('🔊 Iniciando llamada de voz a: ${targetUser.fullname}');
      }
      
      // Enviar notificación de llamada
      await _sendCallNotification(
        targetUser: targetUser,
        isVideoCall: false,
      );
      
      // Iniciar llamada de voz usando ZEGOCLOUD
      ZegoUIKitPrebuiltCallInvitationService().send(
        isVideoCall: false,
        invitees: [
          ZegoCallUser(
            targetUser.userId,
            targetUser.fullname,
          ),
        ],
      );
      
      // Configurar timeout
      _startCallTimeout();
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error iniciando llamada de voz: $e');
      }
      _onCallEnded();
    }
  }

  /// Iniciar llamada de video
  Future<void> startVideoCall({
    required User targetUser,
  }) async {
    try {
      if (!_isZegoCloudAvailable) {
        if (kDebugMode) {
          debugPrint('❌ ZEGOCLOUD no está disponible');
        }
        throw Exception('ZEGOCLOUD no está disponible');
      }
      
      // Verificar permisos justo antes de la llamada
      final hasPermissions = await _ensureCallPermissions();
      if (!hasPermissions) {
        if (kDebugMode) {
          debugPrint('❌ Permisos de micrófono requeridos para videollamadas');
        }
        throw Exception('Permisos de micrófono requeridos');
      }
      
      if (isInCall.value) {
        if (kDebugMode) {
          debugPrint('⚠️ Ya hay una llamada en curso');
        }
        return;
      }

      currentCallId.value = 'video_${DateTime.now().millisecondsSinceEpoch}';
      currentCalleeId.value = targetUser.userId;
      currentCallerName.value = targetUser.fullname;
      isInCall.value = true;
      
      if (kDebugMode) {
        debugPrint('📹 Iniciando llamada de video a: ${targetUser.fullname}');
      }
      
      // Enviar notificación de llamada
      await _sendCallNotification(
        targetUser: targetUser,
        isVideoCall: true,
      );
      
      // Iniciar llamada de video usando ZEGOCLOUD
      ZegoUIKitPrebuiltCallInvitationService().send(
        isVideoCall: true,
        invitees: [
          ZegoCallUser(
            targetUser.userId,
            targetUser.fullname,
          ),
        ],
      );
      
      // Configurar timeout
      _startCallTimeout();
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error iniciando llamada de video: $e');
      }
      _onCallEnded();
    }
  }

  /// Enviar notificación de llamada
  Future<void> _sendCallNotification({
    required User targetUser,
    required bool isVideoCall,
  }) async {
    try {
      final User currentUser = AuthController.instance.currentUser;
      
      await PushNotificationService.sendNotification(
        type: NotificationType.call,
        title: isVideoCall ? '📹 Video call' : '🔊 Voice call',
        body: '${currentUser.fullname} is calling you...',
        deviceToken: targetUser.deviceToken,
        call: {
          'callerId': currentUser.userId,
          'callerName': currentUser.fullname,
          'callerPhoto': currentUser.photoUrl,
          'callId': currentCallId.value,
          'isVideoCall': isVideoCall,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'toUserId': targetUser.userId,
        },
      );
      
      if (kDebugMode) {
        debugPrint('📲 Notificación de llamada enviada');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error enviando notificación de llamada: $e');
      }
    }
  }

  /// Configurar timeout para llamadas
  void _startCallTimeout() {
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = Timer(const Duration(seconds: 60), () {
      if (kDebugMode) {
        debugPrint('⏰ Timeout de llamada alcanzado');
      }
      _onCallEnded();
    });
  }

  /// Finalizar llamada
  void _onCallEnded() {
    isInCall.value = false;
    currentCallId.value = '';
    currentCalleeId.value = '';
    currentCallerName.value = '';
    _callTimeoutTimer?.cancel();
    
    if (kDebugMode) {
      debugPrint('📞 Llamada finalizada y estado limpiado');
    }
    
    // Limpiar estado de ZEGOCLOUD de forma segura
    try {
      // No llamar uninit aquí para evitar problemas de contexto
      if (kDebugMode) {
        debugPrint('🧹 Estado de llamada limpiado correctamente');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error limpiando estado (no crítico): $e');
      }
    }
  }

  /// Aceptar llamada entrante
  void acceptIncomingCall() {
    if (kDebugMode) {
      debugPrint('✅ Aceptando llamada entrante');
    }
    isInCall.value = true;
  }

  /// Rechazar llamada entrante
  void rejectIncomingCall() {
    if (kDebugMode) {
      debugPrint('❌ Rechazando llamada entrante');
    }
    _onCallEnded();
  }

  /// Cancelar llamada saliente
  void cancelOutgoingCall() {
    if (kDebugMode) {
      debugPrint('🚫 Cancelando llamada saliente');
    }
    _onCallEnded();
  }

  /// Verificar si el usuario está en una llamada
  bool get isUserInCall => isInCall.value;

  /// Obtener información de la llamada actual
  Map<String, dynamic> get currentCallInfo => {
    'callId': currentCallId.value,
    'calleeId': currentCalleeId.value,
    'callerName': currentCallerName.value,
    'isInCall': isInCall.value,
  };

  /// Inicia una llamada saliente (método para CallController)
  Future<void> startOutgoingCall({
    required User receiver,
    required bool isVideo,
  }) async {
    if (isVideo) {
      await startVideoCall(targetUser: receiver);
    } else {
      await startVoiceCall(targetUser: receiver);
    }
  }

  /// Maneja una llamada entrante (método para CallController)
  Future<void> handleIncomingCall({
    required String callerId,
    required String channelId,
    required bool isVideo,
    required String callerName,
  }) async {
    // Este método se maneja automáticamente por ZEGOCLOUD
    // cuando se recibe una notificación de llamada
    if (kDebugMode) {
      debugPrint('📞 Llamada entrante recibida: $callerName');
    }
  }

  /// Contesta una llamada entrante
  Future<void> answerCall() async {
    try {
      if (kDebugMode) {
        debugPrint('✅ Contestando llamada entrante');
      }
      onCallAnswered?.call();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error contestando llamada: $e');
      }
    }
  }

  /// Rechaza una llamada entrante
  Future<void> rejectCall() async {
    try {
      if (kDebugMode) {
        debugPrint('❌ Rechazando llamada entrante');
      }
      onCallRejected?.call();
      _onCallEnded();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error rechazando llamada: $e');
      }
    }
  }

  /// Termina la llamada actual
  Future<void> endCall() async {
    try {
      if (kDebugMode) {
        debugPrint('📞 Terminando llamada');
      }
      onCallEnded?.call();
      _onCallEnded();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error terminando llamada: $e');
      }
    }
  }

  /// Alterna el estado de silencio
  Future<void> toggleMute() async {
    try {
      // Esta funcionalidad se maneja automáticamente por ZEGOCLOUD
      if (kDebugMode) {
        debugPrint('🔇 Alternando silencio');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error alternando silencio: $e');
      }
    }
  }

  /// Obtiene el estado de silencio
  bool get isMuted => false; // Se maneja automáticamente por ZEGOCLOUD

  /// Alterna el altavoz
  Future<void> toggleSpeaker() async {
    try {
      // Esta funcionalidad se maneja automáticamente por ZEGOCLOUD
      if (kDebugMode) {
        debugPrint('🔊 Alternando altavoz');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error alternando altavoz: $e');
      }
    }
  }

  /// Obtiene el estado del altavoz
  bool get isSpeakerOn => false; // Se maneja automáticamente por ZEGOCLOUD

  /// Limpiar recursos y desinicializar ZEGOCLOUD
  void uninit() {
    try {
      _callTimeoutTimer?.cancel();
      ZegoUIKitPrebuiltCallInvitationService().uninit();
      
      if (kDebugMode) {
        debugPrint('🧹 ZEGOCLOUD recursos limpiados');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error limpiando recursos ZEGOCLOUD: $e');
      }
    }
  }
}