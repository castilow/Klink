import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:url_launcher/url_launcher.dart';

class WalletConnectService {
  static final WalletConnectService _instance =
      WalletConnectService._internal();

  late WalletConnect _connector;
  String? _connectedAddress;
  bool _initialized = false;

  factory WalletConnectService() {
    return _instance;
  }

  WalletConnectService._internal();

  Future<void> initialize() async {
    if (_initialized) return;

    _connector = WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      clientMeta: PeerMeta(
        name: 'Klink App',
        description: 'Klink Mobile App',
        url: 'https://klink.com',
        icons: ['https://klink.com/icon.png'],
      ),
    );

    _connector.on('connect', (session) {
      if (session is SessionStatus) {
        _connectedAddress = session.accounts[0];
      }
    });

    _connector.on('disconnect', (session) {
      _connectedAddress = null;
    });

    _initialized = true;
  }

  Future<String?> connectWallet() async {
    if (!_initialized) await initialize();

    try {
      // Create session
      final session = await _connector.createSession(
        chainId: 56, // BSC Chain ID
        onDisplayUri: (uri) async {
          final trustWalletUrl = 'trust://wc?uri=${Uri.encodeComponent(uri)}';
          final universalLink =
              'https://link.trustwallet.com/wc?uri=${Uri.encodeComponent(uri)}';

          // Try deep linking first
          if (await canLaunchUrl(Uri.parse(trustWalletUrl))) {
            await launchUrl(Uri.parse(trustWalletUrl));
          }
          // Fallback to universal link
          else if (await canLaunchUrl(Uri.parse(universalLink))) {
            await launchUrl(Uri.parse(universalLink));
          }
        },
      );

      if (session.accounts.isNotEmpty) {
        _connectedAddress = session.accounts[0];
        return _connectedAddress;
      }

      return null;
    } catch (e) {
      throw Exception('Failed to connect wallet: $e');
    }
  }

  Future<void> disconnect() async {
    if (_connector.connected) {
      await _connector.killSession();
      _connectedAddress = null;
    }
  }

  String? get connectedAddress => _connectedAddress;

  bool get isConnected => _connectedAddress != null;
}
