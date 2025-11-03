import 'package:get/get.dart';
import 'package:web3dart/web3dart.dart';
import '../services/wc_service.dart';
import '../services/woop_token_service.dart';

class WalletController extends GetxController {
  final wc = WCService();
  final woop = WoopTokenService();

  final Rx<String?> account = Rx<String?>(null);
  final isSending = false.obs;

  Future<void> connectWallet() async {
    try {
      await wc.init();
      final session = await wc.connect();

      // Extraer la dirección de la cuenta desde los namespaces
      final accounts = session.namespaces['eip155']?.accounts;
      if (accounts != null && accounts.isNotEmpty) {
        // El formato es "eip155:56:0x..." así que tomamos la parte después del último ":"
        account.value = accounts.first.split(':').last;
      }
    } catch (e) {
      print('❌ Error connecting wallet: $e');
      rethrow;
    }
  }

  Future<String?> sendWoop({
    required String to,
    required double amount, // unidades humanas
  }) async {
    if (account.value == null) return null;

    try {
      // 🔍 Validación 1: Dirección destino con regex
      final addressRegex = RegExp(r'^0x[a-fA-F0-9]{40}$');
      if (!addressRegex.hasMatch(to)) {
        throw Exception('Dirección destino inválida');
      }

      // 🔍 Validación 2: Cantidad > 0 y <= saldo
      final amountValidation = await validateAmount(amount.toString());
      if (amountValidation != null) {
        throw Exception(amountValidation);
      }

      // 🔍 Validación 3: Suficiente BNB para gas
      final gasValidation = await validateGasRequirement();
      if (gasValidation != null) {
        throw Exception(gasValidation);
      }

      // Convertir amount a wei usando el método del servicio
      final amountWei = woop.woopToWei(amount);

      final data = woop.buildTransferData(to, amountWei);

      final tx = {
        'from': account.value,
        'to': woop.contractAddress, // Usar el getter público
        'data': data,
        'value': '0x0', // No enviamos BNB, solo el token
        // Opcional: gas, gasPrice; la wallet puede estimarlos
      };

      isSending.value = true;
      final hash = await wc.sendTx(tx);
      return hash;
    } catch (e) {
      print('❌ Error sending WOOP: $e');
      rethrow;
    } finally {
      isSending.value = false;
    }
  }

  /// Obtiene el balance de WOOP del usuario conectado
  Future<double?> getWoopBalance() async {
    if (account.value == null) return null;

    try {
      final balanceWei = await woop.getBalance(account.value!);
      return woop.weiToWoop(balanceWei);
    } catch (e) {
      print('❌ Error getting WOOP balance: $e');
      return null;
    }
  }

  /// Valida que la cantidad sea válida y no exceda el balance
  Future<String?> validateAmount(String amountStr) async {
    if (amountStr.trim().isEmpty) {
      return 'Por favor ingrese una cantidad';
    }

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      return 'Cantidad inválida';
    }

    final balance = await getWoopBalance();
    if (balance == null) {
      return 'Error al obtener balance';
    }

    if (amount > balance) {
      return 'Cantidad excede el balance disponible (${balance.toStringAsFixed(4)} WOOP)';
    }

    return null; // Validación exitosa
  }

  /// Valida que haya suficiente BNB para gas (estimación básica)
  Future<String?> validateGasRequirement() async {
    if (account.value == null) return null;

    try {
      final client = woop.client;
      final balanceWei = await client.getBalance(
        EthereumAddress.fromHex(account.value!),
      );

      // Convertir Wei a BNB usando EtherAmount
      final bnbBalance = balanceWei.getValueInUnit(EtherUnit.ether);

      // Estimación básica: necesitamos al menos 0.001 BNB para gas
      final minimumBnbForGas = 0.001;

      if (bnbBalance < minimumBnbForGas) {
        return 'Balance insuficiente de BNB para gas. Necesitas al menos ${minimumBnbForGas} BNB (tienes ${bnbBalance.toStringAsFixed(6)} BNB)';
      }

      return null; // Suficiente BNB para gas
    } catch (e) {
      print('❌ Error validating gas requirement: $e');
      return 'Error al verificar balance de BNB';
    }
  }

  /// Verifica si hay una wallet conectada
  bool get isConnected => account.value != null;

  /// Desconecta la wallet
  Future<void> disconnect() async {
    try {
      await wc.disconnect();
      account.value = null;
    } catch (e) {
      print('❌ Error disconnecting wallet: $e');
    }
  }

  @override
  void onClose() {
    woop.dispose();
    super.onClose();
  }
}
