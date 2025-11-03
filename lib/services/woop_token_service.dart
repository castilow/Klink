import 'package:web3dart/web3dart.dart';
import 'package:convert/convert.dart';
import 'package:http/http.dart';

class WoopTokenService {
  static const _rpc = 'https://bsc-dataseed.binance.org/';
  static const _addr = '0xD686E8DFECFd976D80E5641489b7A18Ac16d965D';
  static const _abi = '''
  [ 
    { "name":"transfer","type":"function","constant":false,
      "inputs":[{"name":"to","type":"address"},{"name":"value","type":"uint256"}],
      "outputs":[{"name":"","type":"bool"}] },
    { "name":"balanceOf","type":"function","constant":true,
      "inputs":[{"name":"owner","type":"address"}],
      "outputs":[{"name":"","type":"uint256"}] }
  ]
  ''';

  final Web3Client _client = Web3Client(_rpc, Client());

  /// Getter público para acceder al cliente Web3
  Web3Client get client => _client;
  late final DeployedContract _contract = DeployedContract(
    ContractAbi.fromJson(_abi, 'WOOP'),
    EthereumAddress.fromHex(_addr),
  );
  late final ContractFunction _transfer = _contract.function('transfer');

  /// Devuelve el DATA hex para transfer(to,value)
  String buildTransferData(String toHex, BigInt amountWei) {
    final data = _transfer.encodeCall([
      EthereumAddress.fromHex(toHex),
      amountWei,
    ]);
    return '0x${hex.encode(data)}';
  }

  /// Obtiene el balance de WOOP de una dirección
  Future<BigInt> getBalance(String address) async {
    final balanceFunction = _contract.function('balanceOf');
    final result = await _client.call(
      contract: _contract,
      function: balanceFunction,
      params: [EthereumAddress.fromHex(address)],
    );
    return result.first as BigInt;
  }

  /// Convierte WOOP a Wei (18 decimales)
  BigInt woopToWei(double woopAmount) {
    return BigInt.from(woopAmount * 1e18);
  }

  /// Convierte Wei a WOOP (18 decimales)
  double weiToWoop(BigInt weiAmount) {
    return weiAmount.toDouble() / 1e18;
  }

  /// Obtiene la dirección del contrato WOOP
  String get contractAddress => _addr;

  /// Cierra el cliente
  void dispose() {
    _client.dispose();
  }
}
