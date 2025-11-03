import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../api/user_api.dart';

class NetworkService extends GetxController {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  static NetworkService get to => Get.find<NetworkService>();

  final RxBool _isConnected = true.obs;
  final RxBool _isFirebaseConnected = true.obs;
  final RxInt _retryAttempts = 0.obs;

  Timer? _connectivityCheckTimer;
  Timer? _firebaseRetryTimer;

  // Network state getters
  bool get isConnected => _isConnected.value;
  bool get isFirebaseConnected => _isFirebaseConnected.value;
  int get retryAttempts => _retryAttempts.value;

  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 5);

  @override
  void onInit() {
    super.onInit();
    _startConnectivityMonitoring();
    _setupFirebaseListeners();
  }

  Future<NetworkService> init() async {
    try {
      // Configurar Firebase Database
      UserApi.configureRealtimeDatabase();
      
      // Inicializar Mobile Ads
      await MobileAds.instance.initialize();
      
      print('✅ Network Service: Firebase y Ads inicializados');
      return this;
    } catch (e) {
      print('❌ Error en NetworkService.init(): $e');
      rethrow;
    }
  }

  /// Inicia el monitoreo de conectividad de red
  void _startConnectivityMonitoring() {
    _connectivityCheckTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) {
      _checkNetworkConnectivity();
    });
  }

  /// Verifica la conectividad de red de forma básica
  Future<void> _checkNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));

      final wasConnected = _isConnected.value;
      _isConnected.value = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      if (!wasConnected && _isConnected.value) {
        if (kDebugMode) {
          print('📶 Conectividad de red restaurada');
        }
        _onNetworkRestored();
      } else if (wasConnected && !_isConnected.value) {
        if (kDebugMode) {
          print('📵 Conectividad de red perdida');
        }
        _onNetworkLost();
      }
    } catch (e) {
      _isConnected.value = false;
      if (kDebugMode) {
        print('❌ Error verificando conectividad: $e');
      }
    }
  }

  /// Configura listeners para el estado de Firebase
  void _setupFirebaseListeners() {
    // Monitor Firebase Realtime Database connectivity
    FirebaseDatabase.instance.ref('.info/connected').onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;
      _isFirebaseConnected.value = connected;

      if (connected) {
        if (kDebugMode) {
          print('🔥 Firebase Realtime Database conectado');
        }
        _retryAttempts.value = 0;
      } else {
        if (kDebugMode) {
          print('🔥 Firebase Realtime Database desconectado');
        }
      }
    });
  }

  /// Ejecuta una operación de Firebase con manejo de errores de red
  Future<T?> executeFirebaseOperation<T>(
    Future<T> Function() operation, {
    String operationName = 'Firebase Operation',
    bool silent = false,
  }) async {
    if (!isConnected) {
      if (!silent && kDebugMode) {
        print('📵 Sin conectividad de red, omitiendo: $operationName');
      }
      return null;
    }

    try {
      return await operation().timeout(const Duration(seconds: 30));
    } on FirebaseException catch (e) {
      return _handleFirebaseError(e, operation, operationName, silent);
    } on SocketException catch (e) {
      return _handleNetworkError(e, operation, operationName, silent);
    } on TimeoutException catch (e) {
      return _handleTimeoutError(e, operation, operationName, silent);
    } catch (e) {
      if (!silent && kDebugMode) {
        print('❌ Error inesperado en $operationName: $e');
      }
      return null;
    }
  }

  /// Maneja errores específicos de Firebase
  Future<T?> _handleFirebaseError<T>(
    FirebaseException error,
    Future<T> Function() operation,
    String operationName,
    bool silent,
  ) async {
    if (!silent && kDebugMode) {
      print(
        '🔥 Error Firebase en $operationName: ${error.code} - ${error.message}',
      );
    }

    // Errores de conectividad que pueden resolverse con retry
    final retryableCodes = [
      'unavailable',
      'deadline-exceeded',
      'resource-exhausted',
      'internal',
      'network-connection-lost',
    ];

    if (retryableCodes.contains(error.code) &&
        _retryAttempts.value < maxRetryAttempts) {
      return _retryOperation(operation, operationName, silent);
    }

    return null;
  }

  /// Maneja errores de red
  Future<T?> _handleNetworkError<T>(
    SocketException error,
    Future<T> Function() operation,
    String operationName,
    bool silent,
  ) async {
    if (!silent && kDebugMode) {
      print('📵 Error de red en $operationName: $error');
    }

    _isConnected.value = false;

    if (_retryAttempts.value < maxRetryAttempts) {
      return _retryOperation(operation, operationName, silent);
    }

    return null;
  }

  /// Maneja errores de timeout
  Future<T?> _handleTimeoutError<T>(
    TimeoutException error,
    Future<T> Function() operation,
    String operationName,
    bool silent,
  ) async {
    if (!silent && kDebugMode) {
      print('⏱️ Timeout en $operationName: $error');
    }

    if (_retryAttempts.value < maxRetryAttempts) {
      return _retryOperation(operation, operationName, silent);
    }

    return null;
  }

  /// Reintenta una operación con backoff exponencial
  Future<T?> _retryOperation<T>(
    Future<T> Function() operation,
    String operationName,
    bool silent,
  ) async {
    _retryAttempts.value++;

    if (!silent && kDebugMode) {
      print(
        '🔄 Reintentando $operationName (intento ${_retryAttempts.value}/$maxRetryAttempts)',
      );
    }

    // Backoff exponencial: 5s, 10s, 20s
    final delay = Duration(
      seconds: retryDelay.inSeconds * _retryAttempts.value,
    );
    await Future.delayed(delay);

    return executeFirebaseOperation(
      operation,
      operationName: operationName,
      silent: silent,
    );
  }

  /// Se ejecuta cuando la red se restaura
  void _onNetworkRestored() {
    _retryAttempts.value = 0;
    // Notificaciones generales deshabilitadas
  }

  /// Se ejecuta cuando se pierde la conexión de red
  void _onNetworkLost() {
    // Notificaciones generales deshabilitadas
  }

  /// Fuerza una verificación de conectividad
  Future<void> checkConnectivity() async {
    await _checkNetworkConnectivity();
  }

  /// Espera hasta que haya conectividad disponible
  Future<void> waitForConnectivity({Duration? timeout}) async {
    if (isConnected) return;

    final completer = Completer<void>();
    late StreamSubscription subscription;

    subscription = _isConnected.listen((connected) {
      if (connected) {
        subscription.cancel();
        completer.complete();
      }
    });

    if (timeout != null) {
      Future.delayed(timeout, () {
        if (!completer.isCompleted) {
          subscription.cancel();
          completer.completeError(
            TimeoutException('Connectivity timeout', timeout),
          );
        }
      });
    }

    return completer.future;
  }

  @override
  void onClose() {
    _connectivityCheckTimer?.cancel();
    _firebaseRetryTimer?.cancel();
    super.onClose();
  }
}
