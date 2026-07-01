import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:encrypt/encrypt.dart' as enc;

import '../../../config/api_config.dart'; // 🔥 Importación correcta

class ChatMediaService {
  
  // 1. SELECCIONAR Y COMPRIMIR IMAGEN
  static Future<File?> pickAndCompressImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final targetPath = "${dir.path}/media_sent_${DateTime.now().millisecondsSinceEpoch}.jpg";
    
    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      pickedFile.path, 
      targetPath,
      quality: 70, 
    );

    return compressedFile != null ? File(compressedFile.path) : null;
  }

  // 2. CIFRAR EL ARCHIVO Y SUBIRLO
  static Future<Map<String, String>?> encryptAndUpload(File file, String jwtToken) async {
    try {
      final key = enc.Key.fromSecureRandom(32);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

      final fileBytes = await file.readAsBytes();
      final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

      final dir = await getTemporaryDirectory();
      final encFile = File("${dir.path}/temp_upload.enc");
      await encFile.writeAsBytes(encrypted.bytes);

      // 🔥 USO CORRECTO DE API CONFIG
      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.uploadChatMedia));
      request.headers['Authorization'] = "Bearer $jwtToken";
      request.files.add(await http.MultipartFile.fromPath('file', encFile.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "remoteUrl": data['url'], 
          "mediaKey": key.base64,   
          "mediaIv": iv.base64      
        };
      }
    } catch (e) {
      print("Error subiendo media: $e");
    }
    return null;
  }

  // 3. DESCARGAR Y DESCIFRAR
  static Future<String?> downloadAndDecrypt(String remoteUrl, String base64Key, String base64Iv) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = "${dir.path}/media_recv_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final tempEncPath = "${dir.path}/temp_recv.enc";

      await Dio().download(remoteUrl, tempEncPath);

      final encFile = File(tempEncPath);
      final encryptedBytes = await encFile.readAsBytes();

      final key = enc.Key.fromBase64(base64Key);
      final iv = enc.IV.fromBase64(base64Iv);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

      final decryptedBytes = encrypter.decryptBytes(enc.Encrypted(encryptedBytes), iv: iv);

      final realFile = File(savePath);
      await realFile.writeAsBytes(decryptedBytes);

      encFile.delete();

      return savePath;
    } catch (e) {
      print("Error descargando media: $e");
      return null;
    }
  }
}