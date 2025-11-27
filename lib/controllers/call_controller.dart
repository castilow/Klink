import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/api/call_history_api.dart';
import 'package:chat_messenger/api/user_api.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';
import 'package:chat_messenger/models/call_history.dart';
import 'package:chat_messenger/services/zego_call_service.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class CallController extends GetxController {
  // Call state
  final RxBool isCallActive = RxBool(false);
  final RxBool isMuted = RxBool(false);
  final RxBool isSpeakerOn = RxBool(false);
  final RxString callDuration = RxString('00:00');
  final RxBool isVideoCall = RxBool(false);
  
  // Timer for call duration
  Timer? _callTimer;
  int _callSeconds = 0;

  // ZEGOCLOUD service
  late final ZegoCallService _zegoService;
  
  // Ringtone player
  final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();
  
  // Call tracking
  User? _currentCallReceiver;
  bool _isIncomingCall = false;
  bool _wasCallAnswered = false;
  Timer? _incomingCallTimeoutTimer;

  @override
  void onInit() {
    super.onInit();
    _zegoService = Get.find<ZegoCallService>();
    _setupZegoCallbacks();
    
    // Start call timer when call becomes active
    ever(isCallActive, (bool active) {
      if (active) {
        _startCallTimer();
      } else {
        _stopCallTimer();
      }
    });
  }

  @override
  void onClose() {
    _stopCallTimer();
    _incomingCallTimeoutTimer?.cancel();
    // Stop ringtone when controller is closed
    _ringtonePlayer.stop();
    super.onClose();
  }

  /// Configura los callbacks del servicio ZEGOCLOUD
  void _setupZegoCallbacks() {
    _zegoService.onCallAnswered = () {
      isCallActive.value = true;
      _wasCallAnswered = true;
      // Stop ringtone when call is answered
      _ringtonePlayer.stop();
      DialogHelper.showSnackbarMessage(
        SnackMsgType.success,
        'Llamada conectada',
      );
    };

    _zegoService.onCallEnded = () {
      isCallActive.value = false;
      final duration = _callSeconds;
      _stopCallTimer();
      // Stop ringtone when call ends
      _ringtonePlayer.stop();
      
      // Registrar llamada en historial
      if (_currentCallReceiver != null) {
        _registerCall(
          receiver: _currentCallReceiver!,
          callStatus: _wasCallAnswered 
              ? (_isIncomingCall ? CallStatus.incoming : CallStatus.outgoing)
              : CallStatus.missed,
          duration: duration,
        );
      }
      
      // Limpiar estado
      _currentCallReceiver = null;
      _isIncomingCall = false;
      _wasCallAnswered = false;
      
      DialogHelper.showSnackbarMessage(
        SnackMsgType.info,
        'Llamada terminada',
      );
      Get.back();
    };

    _zegoService.onCallRejected = () {
      isCallActive.value = false;
      _stopCallTimer();
      // Stop ringtone when call is rejected
      _ringtonePlayer.stop();
      
      // Registrar llamada perdida
      if (_currentCallReceiver != null) {
        _registerCall(
          receiver: _currentCallReceiver!,
          callStatus: CallStatus.missed,
          duration: 0,
        );
      }
      
      // Limpiar estado
      _currentCallReceiver = null;
      _isIncomingCall = false;
      _wasCallAnswered = false;
      
      DialogHelper.showSnackbarMessage(
        SnackMsgType.info,
        'Llamada rechazada',
      );
      Get.back();
    };
  }

  /// Inicia una llamada saliente
  Future<void> startOutgoingCall({
    required User receiver,
    required bool isVideo,
  }) async {
    try {
      // Guardar información de la llamada
      _currentCallReceiver = receiver;
      _isIncomingCall = false;
      _wasCallAnswered = false;
      
      isVideoCall.value = isVideo;
      await _zegoService.startOutgoingCall(
        receiver: receiver,
        isVideo: isVideo,
      );
      
      DialogHelper.showSnackbarMessage(
        SnackMsgType.info,
        'Iniciando llamada...',
      );
    } catch (e) {
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Error iniciando llamada: $e',
      );
    }
  }

  /// Maneja una llamada entrante desde notificación
  Future<void> handleIncomingCall({
    required String callerId,
    required String channelId,
    required bool isVideo,
    required String callerName,
  }) async {
    try {
      // Obtener información del llamante
      try {
        final caller = await UserApi.getUser(callerId);
        if (caller != null) {
          _currentCallReceiver = caller;
          _isIncomingCall = true;
          _wasCallAnswered = false;
        }
      } catch (e) {
        debugPrint('Error obteniendo información del llamante: $e');
      }
      
      isVideoCall.value = isVideo;
      
      // Start ringtone for incoming call
      _ringtonePlayer.playRingtone();
      
      // Iniciar timeout para llamada entrante (30 segundos)
      _startIncomingCallTimeout();
      
      await _zegoService.handleIncomingCall(
        callerId: callerId,
        channelId: channelId,
        isVideo: isVideo,
        callerName: callerName,
      );
    } catch (e) {
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Error manejando llamada entrante: $e',
      );
    }
  }
  
  /// Inicia el timeout para llamadas entrantes no contestadas
  void _startIncomingCallTimeout() {
    _incomingCallTimeoutTimer?.cancel();
    _incomingCallTimeoutTimer = Timer(const Duration(seconds: 30), () {
      // Si la llamada no fue contestada después de 30 segundos, registrarla como perdida
      if (_isIncomingCall && !_wasCallAnswered && _currentCallReceiver != null) {
        debugPrint('⏰ Timeout de llamada entrante - registrando como perdida');
        _ringtonePlayer.stop();
        _registerCall(
          receiver: _currentCallReceiver!,
          callStatus: CallStatus.missed,
          duration: 0,
        );
        // Limpiar estado
        _currentCallReceiver = null;
        _isIncomingCall = false;
        _wasCallAnswered = false;
        Get.back();
      }
    });
  }
  
  /// Cancela el timeout de llamada entrante
  void _cancelIncomingCallTimeout() {
    _incomingCallTimeoutTimer?.cancel();
  }

  /// Contesta una llamada entrante
  Future<void> answerCall() async {
    try {
      // Stop ringtone when answering
      _ringtonePlayer.stop();
      // Cancelar timeout ya que la llamada fue contestada
      _cancelIncomingCallTimeout();
      
      await _zegoService.answerCall();
      isCallActive.value = true;
      _wasCallAnswered = true;
      DialogHelper.showSnackbarMessage(
        SnackMsgType.success,
        'Llamada contestada',
      );
    } catch (e) {
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Error contestando llamada: $e',
      );
    }
  }

  /// Rechaza una llamada entrante
  Future<void> rejectCall() async {
    try {
      // Stop ringtone when rejecting
      _ringtonePlayer.stop();
      // Cancelar timeout
      _cancelIncomingCallTimeout();
      
      await _zegoService.rejectCall();
      DialogHelper.showSnackbarMessage(
        SnackMsgType.info,
        'Llamada rechazada',
      );
    } catch (e) {
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Error rechazando llamada: $e',
      );
    }
  }

  /// Termina la llamada actual
  Future<void> endCall() async {
    try {
      // Stop ringtone when ending call
      _ringtonePlayer.stop();
      
      final duration = _callSeconds;
      await _zegoService.endCall();
      isCallActive.value = false;
      _stopCallTimer();
      
      // Registrar llamada en historial
      if (_currentCallReceiver != null) {
        _registerCall(
          receiver: _currentCallReceiver!,
          callStatus: _wasCallAnswered 
              ? (_isIncomingCall ? CallStatus.incoming : CallStatus.outgoing)
              : CallStatus.missed,
          duration: duration,
        );
      }
      
      // Limpiar estado
      _currentCallReceiver = null;
      _isIncomingCall = false;
      _wasCallAnswered = false;
      
      DialogHelper.showSnackbarMessage(
        SnackMsgType.info,
        'Llamada terminada',
      );
      Get.back();
    } catch (e) {
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Error terminando llamada: $e',
      );
    }
  }
  
  /// Registrar llamada en historial
  Future<void> _registerCall({
    required User receiver,
    required CallStatus callStatus,
    required int duration,
  }) async {
    try {
      await CallHistoryApi.addCallToHistory(
        receiverId: receiver.userId,
        callType: isVideoCall.value ? CallType.video : CallType.audio,
        callStatus: callStatus,
        duration: duration,
      );
      debugPrint('✅ Llamada registrada en historial: ${callStatus.name}, duración: ${duration}s');
    } catch (e) {
      debugPrint('❌ Error registrando llamada en historial: $e');
    }
  }

  /// Alterna el estado del micrófono
  Future<void> toggleMute() async {
    try {
      await _zegoService.toggleMute();
      isMuted.value = _zegoService.isMuted;
      DialogHelper.showSnackbarMessage(
        SnackMsgType.info,
        isMuted.value ? 'Micrófono silenciado' : 'Micrófono activado',
      );
    } catch (e) {
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Error alternando micrófono: $e',
      );
    }
  }

  /// Alterna el altavoz
  Future<void> toggleSpeaker() async {
    try {
      await _zegoService.toggleSpeaker();
      isSpeakerOn.value = _zegoService.isSpeakerOn;
      DialogHelper.showSnackbarMessage(
        SnackMsgType.info,
        isSpeakerOn.value ? 'Altavoz activado' : 'Altavoz desactivado',
      );
    } catch (e) {
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Error alternando altavoz: $e',
      );
    }
  }

  // Start call timer
  void _startCallTimer() {
    _callSeconds = 0;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callSeconds++;
      final minutes = _callSeconds ~/ 60;
      final seconds = _callSeconds % 60;
      callDuration.value = 
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    });
  }

  // Stop call timer
  void _stopCallTimer() {
    _callTimer?.cancel();
    _callSeconds = 0;
    callDuration.value = '00:00';
  }

  // Show more options
  void showMoreOptions() {
    Get.bottomSheet(
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.record_voice_over),
              title: const Text('Grabar llamada'),
              onTap: () {
                Get.back();
                _recordCall();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bluetooth),
              title: const Text('Conectar Bluetooth'),
              onTap: () {
                Get.back();
                _connectBluetooth();
              },
            ),
            ListTile(
              leading: const Icon(Icons.keyboard),
              title: const Text('Teclado'),
              onTap: () {
                Get.back();
                _showDialpad();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Record call
  void _recordCall() {
    DialogHelper.showSnackbarMessage(
      SnackMsgType.info,
      'Grabación iniciada',
    );
  }

  // Connect Bluetooth
  void _connectBluetooth() {
    DialogHelper.showSnackbarMessage(
      SnackMsgType.info,
      'Conectando Bluetooth...',
    );
  }

  // Show dialpad
  void _showDialpad() {
    DialogHelper.showSnackbarMessage(
      SnackMsgType.info,
      'Teclado disponible',
    );
  }
} 