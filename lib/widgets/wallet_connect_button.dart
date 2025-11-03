import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/wallet_connect_service.dart';
import '../services/wallet_service.dart';

class WalletConnectButton extends StatefulWidget {
  final Function(bool) onConnectionChanged;
  final Function(double)? onBalanceUpdated;

  const WalletConnectButton({
    super.key,
    required this.onConnectionChanged,
    this.onBalanceUpdated,
  });

  @override
  State<WalletConnectButton> createState() => _WalletConnectButtonState();
}

class _WalletConnectButtonState extends State<WalletConnectButton> {
  final WalletConnectService _walletConnectService = WalletConnectService();
  final WalletService _walletService = WalletService();
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _initializeWalletConnect();
  }

  Future<void> _initializeWalletConnect() async {
    await _walletConnectService.initialize();
  }

  Future<void> _connectWallet() async {
    if (_walletConnectService.isConnected) {
      await _walletConnectService.disconnect();
      _walletService.disconnect();
      widget.onConnectionChanged(false);
      if (widget.onBalanceUpdated != null) {
        widget.onBalanceUpdated!(0.0);
      }
      setState(() {});
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    try {
      final address = await _walletConnectService.connectWallet();

      if (address != null) {
        await _walletService.connectWallet(address);
        widget.onConnectionChanged(true);

        if (widget.onBalanceUpdated != null) {
          final balance = await _walletService.getWoopBalance();
          widget.onBalanceUpdated!(balance);
        }
      }
    } catch (e) {
      // Notificaciones deshabilitadas
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: _isConnecting ? null : _connectWallet,
          style: ElevatedButton.styleFrom(
            backgroundColor: _walletConnectService.isConnected
                ? Colors.red.withOpacity(0.8)
                : const Color(0xFF4A63E7),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isConnecting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  _walletConnectService.isConnected
                      ? 'Disconnect Wallet'
                      : 'Connect Wallet',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        if (!_walletConnectService.isConnected) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async {
              const trustWalletUrl = 'https://trustwallet.com/download';
              if (await canLaunchUrl(Uri.parse(trustWalletUrl))) {
                await launchUrl(Uri.parse(trustWalletUrl));
              }
            },
            child: const Text(
              'Don\'t have Trust Wallet? Get it here',
              style: TextStyle(color: Color(0xFF4A63E7), fontSize: 14),
            ),
          ),
        ],
      ],
    );
  }
}
