import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:flutter/foundation.dart' hide Key;

class EncryptHelper {
  // Usar claves fijas en lugar de claves aleatorias para mantener consistencia
  static final _key = encrypt_lib.Key.fromBase64(
    'MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTIzNDU2Nzg5MDA=',
  ); // Clave fija de 32 bytes
  static final _iv = encrypt_lib.IV.fromBase64(
    'MDEyMzQ1Njc4OTAxMjM0NQ==',
  ); // IV fijo de 16 bytes
  static final _encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(_key));

  static String encrypt(String text, String msgId) {
    try {
      if (text.isEmpty) {
        debugPrint('encrypt() -> Empty text for message $msgId');
        return text;
      }

      debugPrint(
        'encrypt() -> Encrypting message $msgId with length: ${text.length}',
      );
      final encrypted = _encrypter.encrypt(text, iv: _iv);
      final result = encrypted.base64;
      debugPrint(
        'encrypt() -> Success for message $msgId, encrypted length: ${result.length}',
      );
      return result;
    } catch (e) {
      debugPrint('encrypt() -> Error encrypting message $msgId: $e');
      debugPrint('encrypt() -> Original text: "$text"');
      // Return original text if encryption fails to avoid losing the message
      return text;
    }
  }

  static String decrypt(String text, String msgId) {
    try {
      if (text.isEmpty) {
        debugPrint('decrypt() -> Empty text for message $msgId');
        return text;
      }

      // Check if text is likely already decrypted (not base64)
      if (!_isBase64(text)) {
        debugPrint(
          'decrypt() -> Text appears to be plain text for message $msgId',
        );
        return text;
      }

      debugPrint(
        'decrypt() -> Decrypting message $msgId with length: ${text.length}',
      );

      // Try multiple decryption strategies
      String result = _attemptDecryption(text, msgId);

      debugPrint(
        'decrypt() -> Success for message $msgId, decrypted length: ${result.length}',
      );
      return result;
    } catch (e) {
      debugPrint('decrypt() -> Final error decrypting message $msgId: $e');
      debugPrint('decrypt() -> Returning original text as fallback');
      // Return a placeholder message instead of encrypted text
      return '[Mensaje no pudo ser desencriptado]';
    }
  }

  // Helper method to attempt decryption with different strategies
  static String _attemptDecryption(String text, String msgId) {
    try {
      // Strategy 1: Normal decryption
      final encrypted = encrypt_lib.Encrypted.fromBase64(text);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e1) {
      debugPrint('decrypt() -> Strategy 1 failed for $msgId: $e1');

      try {
        // Strategy 2: Try with different padding
        String paddedText = text;
        while (paddedText.length % 4 != 0) {
          paddedText += '=';
        }
        final encrypted = encrypt_lib.Encrypted.fromBase64(paddedText);
        return _encrypter.decrypt(encrypted, iv: _iv);
      } catch (e2) {
        debugPrint('decrypt() -> Strategy 2 failed for $msgId: $e2');

        try {
          // Strategy 3: Remove padding and try
          String cleanText = text.replaceAll('=', '');
          while (cleanText.length % 4 != 0) {
            cleanText += '=';
          }
          final encrypted = encrypt_lib.Encrypted.fromBase64(cleanText);
          return _encrypter.decrypt(encrypted, iv: _iv);
        } catch (e3) {
          debugPrint('decrypt() -> Strategy 3 failed for $msgId: $e3');

          // Strategy 4: Check if it's actually plain text
          if (_isProbablyPlainText(text)) {
            debugPrint(
              'decrypt() -> Text appears to be plain text, returning as-is',
            );
            return text;
          }

          // Final fallback
          throw Exception('All decryption strategies failed');
        }
      }
    }
  }

  // Helper method to check if a string is likely base64 encoded
  static bool _isBase64(String str) {
    try {
      // Check if it matches base64 pattern
      if (!RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(str)) {
        return false;
      }
      base64.decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Helper method to check if text is probably plain text
  static bool _isProbablyPlainText(String str) {
    // Check if it contains mostly printable ASCII characters
    if (str.length < 4) return true;

    int printableCount = 0;
    for (int i = 0; i < str.length; i++) {
      int charCode = str.codeUnitAt(i);
      if ((charCode >= 32 && charCode <= 126) ||
          charCode == 10 ||
          charCode == 13) {
        printableCount++;
      }
    }

    // If more than 80% of characters are printable, it's likely plain text
    return (printableCount / str.length) > 0.8;
  }
}
