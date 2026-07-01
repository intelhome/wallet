import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class CryptoChatHelper {
  static const String _secretSalt = "TTC_E2EE_SECURE_SALT_2026";

  /// Genera una llave AES-256 única y determinista para dos wallets específicas.
  /// No importa quién envíe el mensaje, la llave siempre será la misma para esa sala.
  static encrypt.Key _getRoomKey(String myWallet, String peerWallet) {
    List<String> wallets = [myWallet.toLowerCase(), peerWallet.toLowerCase()];
    wallets.sort(); // Ordenamos alfabéticamente para que siempre sea el mismo orden
    
    final bytes = utf8.encode(wallets[0] + wallets[1] + _secretSalt);
    final digest = sha256.convert(bytes);
    
    return encrypt.Key.fromBase16(digest.toString().substring(0, 64));
  }

  /// Encripta el JSON (Texto, Transferencia, Memes) antes de enviarlo a Spring Boot
  static String encryptPayload(String myWallet, String peerWallet, String rawJson) {
    final key = _getRoomKey(myWallet, peerWallet);
    final iv = encrypt.IV.fromSecureRandom(16); // IV aleatorio por seguridad
    
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    final encrypted = encrypter.encrypt(rawJson, iv: iv);
    
    // Devolvemos el IV junto con el texto cifrado para poder desencriptarlo después
    return "${iv.base64}:${encrypted.base64}";
  }

  /// Desencripta el texto incomprensible que llega desde Spring Boot
  static String decryptPayload(String myWallet, String peerWallet, String encryptedPayload) {
    try {
      final parts = encryptedPayload.split(':');
      if (parts.length != 2) return '{"type":"TEXT", "content":"[Error de formato cifrado]"}';

      final iv = encrypt.IV.fromBase64(parts[0]);
      final cipherText = parts[1];
      
      final key = _getRoomKey(myWallet, peerWallet);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      
      return encrypter.decrypt64(cipherText, iv: iv);
    } catch (e) {
      return '{"type":"TEXT", "content":"[Mensaje ilegible o llave incorrecta]"}';
    }
  }
}