import 'package:flutter/material.dart';
import '../../../../hooks/use_token_price.dart';

class WoopPrice extends StatefulWidget {
  const WoopPrice({super.key});

  @override
  State<WoopPrice> createState() => _WoopPriceState();
}

class _WoopPriceState extends State<WoopPrice> {
  // WOOP contract address on BSC
  static const CONTRACT = '0xD686E8DFECFd976D80E5641489b7A18Ac16d965D';
  late final TokenPrice _tokenPrice;

  @override
  void initState() {
    super.initState();
    _tokenPrice = UseTokenPrice.use(CONTRACT, vsCurrency: 'usd');
    _tokenPrice.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tokenPrice.dispose();
    super.dispose();
  }

  Widget _buildPriceChange() {
    if (_tokenPrice.priceChange24h == null) return const SizedBox.shrink();

    final change = _tokenPrice.priceChange24h!;
    final isPositive = change >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final sign = isPositive ? '+' : '';

    return Text(
      '$sign${change.toStringAsFixed(2)}%',
      style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tokenPrice.error != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Error: ${_tokenPrice.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_tokenPrice.price == null) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1e1e1e),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'WOOP: \$${_tokenPrice.price!.toStringAsFixed(4)}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 4),
          _buildPriceChange(),
        ],
      ),
    );
  }
}
