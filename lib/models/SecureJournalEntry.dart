import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class SecureJournalEntry {
  static const String _prefix = '[ENCRYPTED]::';

  static Key _generateKey(String password) {
    final hash = sha256.convert(utf8.encode(password));
    return Key(Uint8List.fromList(hash.bytes));
  }

  static String encryptContent(String content, String password) {
    final key = _generateKey(password);
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key));

    final encrypted = encrypter.encrypt(content, iv: iv);
    final payload = jsonEncode({
      'iv': base64Encode(iv.bytes),
      'data': encrypted.base64,
    });

    return '$_prefix$payload';
  }

  static String? decryptContent(String encryptedContent, String password) {
    if (!isEncrypted(encryptedContent)) return encryptedContent;

    try {
      final jsonPayload = encryptedContent.replaceFirst(_prefix, '');
      final Map<String, dynamic> payload = jsonDecode(jsonPayload);

      final iv = IV.fromBase64(payload['iv']);
      final encryptedData = Encrypted.fromBase64(payload['data']);
      final key = _generateKey(password);
      final encrypter = Encrypter(AES(key));

      return encrypter.decrypt(encryptedData, iv: iv);
    } catch (_) {
      return null; // indicates decryption failure (e.g., wrong password)
    }
  }

  static bool isEncrypted(String content) {
    return content.startsWith(_prefix);
  }
}
