import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dapp_movil/modules/chat_and_social/services/chat_media_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../../wallet_and_tx/screens/receipt_preview_screen.dart';

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final String peerAddress; // 🔥 Recibimos la dirección del amigo para el comprobante

  const MessageBubble({
    super.key, 
    required this.message, 
    required this.isMe,
    required this.peerAddress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    String type = message['type'] ?? 'TEXT';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: _getBubbleColor(type, isMe, colorScheme, theme),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
          border: type == 'TRANSFER' ? Border.all(color: Colors.green.withOpacity(0.3)) : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
          ]
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _buildContent(type, context, colorScheme),
        ),
      ),
    );
  }

  Color _getBubbleColor(String type, bool isMe, ColorScheme colorScheme, ThemeData theme) {
    if (type == 'TRANSFER') return isMe ? Colors.green.shade700 : theme.cardColor;
    return isMe ? colorScheme.primary : theme.cardColor;
  }

  Widget _buildContent(String type, BuildContext context, ColorScheme colorScheme) {
    final textColor = isMe ? Colors.white : colorScheme.onSurface;

    if (type == 'TRANSFER') {
      final fecha = message['date'] ?? "Reciente";
      final txHash = message['txHash'] ?? "0x...";
      final monto = message['amount'] ?? 0.0;
      
      final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
      final transferTextColor = isMe ? Colors.white : (isDarkTheme ? Colors.white : Colors.green.shade800);

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isMe ? Icons.call_made_rounded : Icons.call_received_rounded, color: transferTextColor.withOpacity(0.8), size: 18),
                const SizedBox(width: 8),
                Text(
                  isMe ? "Transferencia Enviada" : "Transferencia Recibida",
                  style: TextStyle(color: transferTextColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "$monto TTC",
              style: TextStyle(color: transferTextColor, fontSize: 28, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              "Fecha: $fecha",
              style: TextStyle(color: transferTextColor.withOpacity(0.6), fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isMe ? Colors.white.withOpacity(0.2) : Colors.green.withOpacity(0.1),
                foregroundColor: transferTextColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.receipt_long_rounded, size: 16),
              label: const Text("Ver Comprobante", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () {
                // 🔥 Inyectamos AuthCoreService para saber quiénes somos
                final authCore = Provider.of<AuthCoreService>(context, listen: false);
                final myAddress = authCore.publicAddress;

                dynamic mockTx = {
                  'txType': 'SEND',
                  'amount': double.tryParse(monto.toString()) ?? 0.0,
                  'txHash': txHash,
                  'senderAddress': isMe ? myAddress : peerAddress,
                  'receiverAddress': isMe ? peerAddress : myAddress,
                  'status': 'COMPLETED',
                  'timestamp': DateTime.now().toIso8601String()
                };
                
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ReceiptPreviewScreen(tx: mockTx, myAddress: myAddress)
                ));
              },
            ),
          ],
        ),
      );
    }
    
    if (type == 'IMAGE') {
      final localPath = message['localPath'];
      final remoteUrl = message['remoteUrl'];
      final mediaKey = message['mediaKey'];
      final mediaIv = message['mediaIv'];

      // CASO 1: Si ya la tengo descargada localmente (o soy el que la envió)
      if (localPath != null && File(localPath).existsSync()) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(File(localPath), fit: BoxFit.cover),
            ),
            if (message['caption'] != null && message['caption'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(message['caption'], style: TextStyle(color: textColor)),
              )
          ],
        );
      } 
      
      // CASO 2: Soy el que recibe y no la tengo descargada
      return FutureBuilder<String?>(
        future: ChatMediaService.downloadAndDecrypt(remoteUrl, mediaKey, mediaIv),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: 200, width: 200,
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(16)),
              child: const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            // Actualizamos el mapa en memoria para que no la vuelva a descargar
            message['localPath'] = snapshot.data; 
            
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(File(snapshot.data!), fit: BoxFit.cover),
            );
          }

          return Container(
            height: 200, width: 200,
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.red)),
          );
        },
      );
    }

    if (type == 'AUDIO') {
      final localPath = message['localPath'];
      final remoteUrl = message['remoteUrl'];
      final mediaKey = message['mediaKey'];
      final mediaIv = message['mediaIv'];

      // CASO 1: Si ya la tengo descargada
      if (localPath != null && File(localPath).existsSync()) {
        return AudioPlayerWidget(filePath: localPath, isMe: isMe, iconColor: textColor);
      }

      // CASO 2: Soy el que recibe y no la tengo descargada
      return FutureBuilder<String?>(
        future: ChatMediaService.downloadAndDecrypt(remoteUrl, mediaKey, mediaIv),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            message['localPath'] = snapshot.data; // Cacheamos la ruta
            return AudioPlayerWidget(filePath: snapshot.data!, isMe: isMe, iconColor: textColor);
          }

          return const Padding(
            padding: EdgeInsets.all(16),
            child: Icon(Icons.error_outline, color: Colors.red),
          );
        },
      );
    }

    // Por defecto: TEXT
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(message['content'].toString(), style: TextStyle(color: textColor, fontSize: 15)),
    );
  }
}

// ==========================================
// WIDGET REPRODUCTOR DE AUDIO
// ==========================================
class AudioPlayerWidget extends StatefulWidget {
  final String filePath;
  final bool isMe;
  final Color iconColor;

  const AudioPlayerWidget({super.key, required this.filePath, required this.isMe, required this.iconColor});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setSource(DeviceFileSource(widget.filePath));
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if(mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onDurationChanged.listen((d) {
      if(mounted) setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if(mounted) setState(() => _position = p);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      width: MediaQuery.of(context).size.width * 0.60,
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: widget.iconColor, size: 36),
            onPressed: () {
              if (_isPlaying) {
                _audioPlayer.pause();
              } else {
                _audioPlayer.play(DeviceFileSource(widget.filePath));
              }
            },
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 3,
                activeTrackColor: widget.iconColor,
                inactiveTrackColor: widget.iconColor.withOpacity(0.3),
                thumbColor: widget.iconColor,
              ),
              child: Slider(
                value: _position.inSeconds.toDouble(),
                max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
                onChanged: (val) {
                  _audioPlayer.seek(Duration(seconds: val.toInt()));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}