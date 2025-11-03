import 'package:get/get.dart';
import '../services/token_service.dart';

class TokenController extends GetxController {
  final TokenService _tokenService = TokenService();
  final Rx<BigInt?> _woopBalance = Rx<BigInt?>(null);
  final Rx<BigInt?> _bnbBalance = Rx<BigInt?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _error = RxString('');

  BigInt? get woopBalance => _woopBalance.value;
  BigInt? get bnbBalance => _bnbBalance.value;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;

  @override
  void onInit() {
    super.onInit();
    const userAddress = '0x0000...DEMO';
    updateBalances(userAddress);
  }

  /// Actualiza los balances de WOOP y BNB para una dirección
  Future<void> updateBalances(String address) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      final woopBalance = await _tokenService.getWoopBalance(address);
      final bnbBalance = await _tokenService.getBnbBalance(address);

      _woopBalance.value = woopBalance;
      _bnbBalance.value = bnbBalance;
    } catch (e) {
      _error.value = 'Error al obtener los balances: $e';
      print(_error.value);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Envía WOOP tokens a una dirección
  Future<String?> sendWoopTokens({
    required String fromPk,
    required String to,
    required BigInt amount,
  }) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      final txHash = await _tokenService.sendWoop(
        fromPk: fromPk,
        to: to,
        amount: amount,
      );

      await updateBalances(to);
      return txHash;
    } catch (e) {
      _error.value = 'Error al enviar WOOP: $e';
      print(_error.value);
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Limpia los estados del controlador
  void reset() {
    _woopBalance.value = null;
    _bnbBalance.value = null;
    _isLoading.value = false;
    _error.value = '';
  }
}
