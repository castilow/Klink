import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class WCService {
  static const _projectId = '86dd74caf10d75e4c6be7c66bcac5ffb';
  static const _chain = 'eip155:56'; // BSC mainnet

  // Claves para persistencia
  static const _keySessionTopic = 'wc_session_topic';
  static const _keySessionExpiry = 'wc_session_expiry';
  static const _keyConnectedAddress = 'wc_connected_address';
  static const _keySessionData = 'wc_session_data';

  static final WCService _instance = WCService._internal();

  Web3App? _web3app;
  SessionData? _sessionData;
  String? _connectedAddress;
  bool _initialized = false;
  SharedPreferences? _prefs;

  factory WCService() {
    return _instance;
  }

  WCService._internal();

  /// Inicializa el servicio WalletConnect
  Future<void> init() async {
    if (_initialized) return;

    try {
      // Inicializar SharedPreferences
      _prefs = await SharedPreferences.getInstance();
      print('✅ WCService: SharedPreferences initialized');

      _web3app = await Web3App.createInstance(
        projectId: _projectId,
        relayUrl: 'wss://relay.walletconnect.com',
        metadata: const PairingMetadata(
                  name: 'Arious',
        description: 'Chat + WOOP Wallet',
        url: 'https://arious.com',
        icons: ['https://arious.com/icon.png'],
        redirect: Redirect(
          native: 'arious://',
          universal: 'https://arious.com',
          ),
        ),
      );
      print('✅ WCService: Web3App instance created');

      _initialized = true;

      // Intentar restaurar sesión persistida
      await _restorePersistedSession();
      print('✅ WCService: Session restoration attempted');

      // Verificar sesiones activas existentes
      await _checkExistingSessions();
      print('✅ WCService: Existing sessions checked');

      print('✅ WCService initialized successfully');
    } catch (e) {
      print('❌ Error initializing WCService: $e');
      _initialized = false;
      rethrow;
    }
  }

  /// Restaura una sesión previamente guardada
  Future<void> _restorePersistedSession() async {
    try {
      final sessionDataString = _prefs?.getString(_keySessionData);
      if (sessionDataString != null && sessionDataString.isNotEmpty) {
        final sessionDataMap = jsonDecode(sessionDataString) as Map<String, dynamic>;
        _sessionData = SessionData.fromJson(sessionDataMap);
        _connectedAddress = _prefs?.getString(_keyConnectedAddress);
        print('✅ WCService: Session restored successfully');
      }
    } catch (e) {
      print('❌ Error restoring WCService session: $e');
      // Clear potentially corrupted data
      await _clearPersistedSession();
    }
  }

  /// Guarda la sesión actual en persistencia
  Future<void> _persistSession() async {
    if (_prefs == null || _sessionData == null || _connectedAddress == null)
      return;

    try {
      // Verificar si ya tenemos la misma sesión guardada para evitar escrituras innecesarias
      final existingSessionData = _prefs!.getString(_keySessionData);
      final existingAddress = _prefs!.getString(_keyConnectedAddress);

      final sessionMap = {
        'topic': _sessionData!.topic,
        'expiry': _sessionData!.expiry,
      };
      final currentSessionJson = json.encode(sessionMap);

      // Solo guardar si la sesión ha cambiado
      if (existingSessionData != currentSessionJson ||
          existingAddress != _connectedAddress) {
        await _prefs!.setString(_keySessionData, currentSessionJson);
        await _prefs!.setString(_keyConnectedAddress, _connectedAddress!);
        await _prefs!.setInt(_keySessionExpiry, _sessionData!.expiry);

        if (kDebugMode) {
          print('💾 Sesión actualizada en persistencia');
        }
      } else {
        if (kDebugMode) {
          print('✅ Sesión ya persistida (sin cambios)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error guardando sesión: $e');
      }
    }
  }

  /// Limpia los datos de sesión persistidos
  Future<void> _clearPersistedSession() async {
    try {
      await _prefs?.remove(_keySessionTopic);
      await _prefs?.remove(_keySessionExpiry);
      await _prefs?.remove(_keyConnectedAddress);
      await _prefs?.remove(_keySessionData);
      _sessionData = null;
      _connectedAddress = null;
      print('✅ WCService: Session data cleared');
    } catch (e) {
      print('❌ Error clearing WCService session: $e');
    }
  }

  /// Verifica sesiones existentes
  Future<void> _checkExistingSessions() async {
    try {
      if (_web3app == null) return;
      
      final sessions = _web3app!.sessions.getAll();
      if (sessions.isNotEmpty) {
        // Use the most recent session
        final latestSession = sessions.last;
        _sessionData = latestSession;
        _connectedAddress = latestSession.namespaces[_chain]?.accounts.firstOrNull;
        print('✅ WCService: Found existing session');
      }
    } catch (e) {
      print('❌ Error checking WCService sessions: $e');
    }
  }

  /// Abre MetaMask/Trust y devuelve la sesión con la cuenta elegida
  Future<SessionData> connect() async {
    if (!_initialized) await init();

    try {
      final connectResponse = await _web3app!.connect(
        optionalNamespaces: {
          'eip155': const RequiredNamespace(
            chains: [_chain],
            methods: ['eth_sendTransaction', 'personal_sign'],
            events: ['accountsChanged', 'chainChanged'],
          ),
        },
      );

      final Uri? uri = connectResponse.uri;

      if (uri == null) {
        throw Exception('No se pudo generar la URI de conexión');
      }

      // Abrir wallet con deep links
      await _launchWallet(uri.toString());

      // Esperar conexión
      final SessionData sessionData = await connectResponse.session.future;

      _sessionData = sessionData;

      // Extraer dirección
      final accounts = sessionData.namespaces['eip155']?.accounts;
      if (accounts != null && accounts.isNotEmpty) {
        _connectedAddress = accounts.first.split(':').last;
      }

      if (kDebugMode) {
        print('✅ Wallet connected: $_connectedAddress');
      }

      // Guardar sesión en persistencia
      await _persistSession();

      return sessionData;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error connecting wallet: $e');
      }
      throw Exception('Failed to connect wallet: $e');
    }
  }

  /// Lanza la wallet usando deep links
  Future<void> _launchWallet(String wcUri) async {
    try {
      print('🔗 Intentando abrir MetaMask...');
      
      final List<String> walletUrls = [
        'https://metamask.app.link/wc?uri=${Uri.encodeComponent(wcUri)}',
        'https://link.trustwallet.com/wc?uri=${Uri.encodeComponent(wcUri)}',
      ];

      bool launched = false;
      
      for (final url in walletUrls) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          print('✅ Abriendo wallet con URL: $url');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          launched = true;
          break;
        } else {
          print('❌ No se puede abrir URL: $url');
        }
      }
      
      if (!launched) {
        print('❌ No se pudo abrir ninguna wallet');
        throw Exception('No se pudo abrir MetaMask. Verifica que esté instalado.');
      }
    } catch (e) {
      print('❌ Error launching wallet: $e');
      throw Exception('Error al abrir MetaMask: $e');
    }
  }

  /// Firma y envía la transacción a la wallet del usuario
  Future<String> sendTx(Map<String, dynamic> tx) async {
    if (_sessionData == null) {
      throw Exception('No wallet connected');
    }

    try {
      // Verificar que la sesión aún sea válida antes de enviar
      if (!await _isSessionValid()) {
        throw Exception('Session expired or invalid');
      }

      final dynamic result = await _web3app!.request(
        topic: _sessionData!.topic,
        chainId: _chain,
        request: SessionRequestParams(
          method: 'eth_sendTransaction',
          params: [tx],
        ),
      );

      final String txHash = result.toString();

      if (kDebugMode) {
        print('✅ Transaction sent: $txHash');
      }

      return txHash;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending transaction: $e');
      }

      // Si es error de sesión, limpiar estado
      if (_isSessionError(e)) {
        await _clearInvalidSession();
      }

      throw Exception('Failed to send transaction: $e');
    }
  }

  /// Verifica si la sesión actual es válida
  Future<bool> _isSessionValid() async {
    if (_sessionData == null) return false;

    try {
      // Verificar que la sesión existe en el cliente Web3
      final sessions = _web3app!.sessions.getAll();
      SessionData? currentSession;

      try {
        currentSession = sessions.firstWhere(
          (session) => session.topic == _sessionData!.topic,
        );
      } catch (e) {
        // No se encontró la sesión
        if (kDebugMode) {
          print('⚠️ Sesión no encontrada en el cliente');
        }
        return false;
      }

      // Verificar que la sesión no haya expirado
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (currentSession.expiry < now) {
        if (kDebugMode) {
          print('⚠️ Sesión expirada');
        }
        return false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error verificando validez de sesión: $e');
      }
      return false;
    }
  }

  /// Verifica si el error está relacionado con sesión inválida
  bool _isSessionError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('session topic doesn\'t exist') ||
        errorString.contains('no matching key') ||
        errorString.contains('session expired') ||
        errorString.contains('invalid session') ||
        errorString.contains('walletconnecterror(code: 2');
  }

  /// Limpia una sesión inválida
  Future<void> _clearInvalidSession() async {
    try {
      if (kDebugMode) {
        print('🧹 Limpiando sesión inválida...');
      }

      _sessionData = null;
      _connectedAddress = null;

      // Limpiar persistencia
      await _clearPersistedSession();

      // Intentar desconectar cualquier sesión restante
      final sessions = _web3app?.sessions.getAll() ?? [];
      for (final session in sessions) {
        try {
          await _web3app!.disconnectSession(
            topic: session.topic,
            reason: Errors.getSdkError(Errors.USER_DISCONNECTED),
          );
        } catch (e) {
          // Ignorar errores al desconectar sesiones ya inválidas
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error limpiando sesión: $e');
      }
    }
  }

  /// Refresca la conexión y obtiene la información más reciente
  Future<void> refreshConnection() async {
    if (!_initialized) await init();

    try {
      await _checkExistingSessions();

      // Verificar validez de la sesión actual
      if (_sessionData != null && !await _isSessionValid()) {
        if (kDebugMode) {
          print('⚠️ Sesión actual inválida, limpiando...');
        }
        await _clearInvalidSession();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error en refresh connection: $e');
      }
    }
  }

  /// Obtiene información detallada del estado de conexión
  Map<String, dynamic> getConnectionStatus() {
    return {
      'isConnected': isConnected,
      'address': _connectedAddress,
      'hasSession': _sessionData != null,
      'sessionTopic': _sessionData?.topic,
      'sessionExpiry': _sessionData?.expiry,
      'isExpired': _sessionData != null
          ? (_sessionData!.expiry <
                DateTime.now().millisecondsSinceEpoch ~/ 1000)
          : null,
    };
  }

  /// Getters
  String? get connectedAddress => _connectedAddress;
  bool get isConnected => _sessionData != null && _connectedAddress != null;
  SessionData? get sessionData => _sessionData;

  /// Desconecta la wallet
  Future<void> disconnect() async {
    if (_sessionData != null) {
      try {
        await _web3app!.disconnectSession(
          topic: _sessionData!.topic,
          reason: Errors.getSdkError(Errors.USER_DISCONNECTED),
        );

        _sessionData = null;
        _connectedAddress = null;

        // Limpiar persistencia
        await _clearPersistedSession();

        if (kDebugMode) {
          print('🔌 Wallet disconnected');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error disconnecting: $e');
        }
      }
    }
  }

  /// Verifica el estado de conexión y persiste si es necesario
  Future<void> maintainSession() async {
    if (isConnected && _sessionData != null) {
      // Verificar que la sesión siga siendo válida
      if (await _isSessionValid()) {
        // Actualizar persistencia con información fresca
        await _persistSession();
      } else {
        // Sesión inválida, limpiar
        await _clearInvalidSession();
      }
    }
  }
}
