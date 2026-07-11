import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/helpers/ui_helper.dart';

class AiVoiceHandler extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  bool isListening = false;
  String transcripcionTemporal = "";
  
  bool _isInitialized = false;

  Future<void> initSpeech() async {
    if (!_isInitialized) {
      _isInitialized = await _speechToText.initialize(
        onError: (val) => print('Error STT: $val'),
        onStatus: (val) => print('Status STT: $val'),
      );
    }
  }

  Future<void> startListening() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      await initSpeech();
      if (_isInitialized) {
        isListening = true;
        transcripcionTemporal = "Escuchando...";
        notifyListeners();
        
        await _speechToText.listen(
          onResult: (result) {
            transcripcionTemporal = result.recognizedWords;
            notifyListeners();
          },
          localeId: "es_ES", // Fuerza reconocimiento en español
        );
      } else {
        UIHelper.showCustomSnackbar("El motor de voz no está disponible en este dispositivo.", isError: true);
      }
    } else {
      UIHelper.showCustomSnackbar("Permiso de micrófono denegado", isError: true);
    }
  }

  Future<String> stopListeningAndGetText() async {
    if (isListening) {
      await _speechToText.stop();
      isListening = false;
      notifyListeners();
    }
    String resultadoFinal = transcripcionTemporal;
    transcripcionTemporal = "";
    return resultadoFinal == "Escuchando..." ? "" : resultadoFinal;
  }
}