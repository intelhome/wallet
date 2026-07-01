import 'dart:io';
import 'package:dapp_movil/modules/document_notary/services/notary_service.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:crypto/crypto.dart';
import 'package:provider/provider.dart';
import '../modals/document_details_modal.dart'; // Reutilizaremos tu modal estrella

class DocumentValidatorScreen extends StatefulWidget {
  //final BlockchainService service;
  const DocumentValidatorScreen({super.key});

  @override
  State<DocumentValidatorScreen> createState() => _DocumentValidatorScreenState();
}

class _DocumentValidatorScreenState extends State<DocumentValidatorScreen> {
  bool _isProcessing = false;
  final TextEditingController _hashController = TextEditingController();

  // 🔥 AGREGAR:
  NotaryService get notaryService => Provider.of<NotaryService>(context, listen: false);

  Future<void> _validarDocumento() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );

    if (result == null || result.files.single.path == null) return;

    setState(() => _isProcessing = true);

    try {
      File file = File(result.files.single.path!);
      List<int> fileBytes = await file.readAsBytes();
      Digest docHash = sha256.convert(fileBytes);
      String hashHex = "0x${docHash.toString()}";

      final docInfo = await notaryService.getDocumentInfo(hashHex);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (docInfo != null) {
        // 🔥 MOSTRAR CERTIFICADO DE AUTENTICIDAD
        _mostrarResultadoExitoso(docInfo, hashHex);
      } else {
        // ❌ MOSTRAR ALERTA DE PRECAUCIÓN
        _mostrarAlertaDeFraude(hashHex);
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
      _mostrarError("Error al leer el archivo. Intenta de nuevo.");
    }
  }

  void _mostrarResultadoExitoso(Map<String, dynamic> docInfo, String hashHex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        final onSurface = colorScheme.onSurface;
        
        List<dynamic> signers = docInfo['requiredSigners'] ?? docInfo['signers'] ?? [];
        String fecha = docInfo['createdAt'] != null ? DateTime.parse(docInfo['createdAt']).toLocal().toString().substring(0, 16) : "Fecha desconocida";

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor, 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32))
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.verified_rounded, color: Colors.green, size: 60),
              ),
              const SizedBox(height: 16),
              const Text("¡Documento Legítimo!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.green)),
              Text("Su integridad ha sido validada en la Blockchain.", textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.6))),
              const SizedBox(height: 24),

              // DATOS DEL DOCUMENTO (M3 Tonal Card)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow("Nombre Original", docInfo['title'] ?? "Documento", Icons.description_rounded, colorScheme.primary),
                    const Divider(height: 20),
                    _buildInfoRow("Fecha de Registro", fecha, Icons.calendar_today_rounded, colorScheme.primary),
                    const Divider(height: 20),
                    _buildInfoRow("Firmantes Requeridos", "${signers.length} persona(s)", Icons.people_alt_rounded, colorScheme.primary),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Icon(Icons.tag_rounded, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 10),
                        const Text("Hash:"),
                        const SizedBox(width: 10),
                        Expanded(child: Text(hashHex, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    DocumentDetailsModal.show(context: context, docHash: hashHex);
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text("Previsualizar Documento Original", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      }
    );
  }

  void _mostrarAlertaDeFraude(String hashCalculado) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(Icons.gpp_bad_rounded, color: Colors.redAccent, size: 60),
        title: const Text("Documento No Reconocido", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "¡Precaución! El archivo que seleccionaste no coincide con ningún registro en la Blockchain.",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(
                "Hash Leído:\n$hashCalculado",
                style: const TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              "Por favor, revisa si subiste el documento original sin el más mínimo cambio. Un simple espacio, una coma añadida, o un re-guardado del PDF alterará por completo el Hash criptográfico resultando en esta alerta.",
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.8)),
              textAlign: TextAlign.center,
            )
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Entendido, verificaré el archivo", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _validarPorHash() async {
    String inputHash = _hashController.text.trim();
    if (inputHash.isEmpty) {
      _mostrarError("Ingresa un hash válido");
      return;
    }
    
    // Asegurarnos de que tenga el formato correcto 0x
    if (!inputHash.startsWith("0x")) {
      inputHash = "0x$inputHash";
    }

    setState(() => _isProcessing = true);

    try {
      final docInfo = await notaryService.getDocumentInfo(inputHash);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (docInfo != null) {
        _mostrarResultadoExitoso(docInfo, inputHash);
      } else {
        _mostrarAlertaDeFraude(inputHash);
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
      _mostrarError("Error al consultar la Blockchain. Intenta de nuevo.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Validador Criptográfico", style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true, elevation: 0, backgroundColor: Colors.transparent),
      body: Center(
child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(color: Colors.deepPurpleAccent.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.document_scanner_rounded, size: 100, color: Colors.deepPurpleAccent),
              ),
              const SizedBox(height: 30),
              const Text("Auditoría Zero-Trust", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Text(
                "Sube cualquier archivo para calcular su huella digital y comprobar matemáticamente si fue alterado o si sus firmas son auténticas.",
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 16),
              ),
              const SizedBox(height: 40),
           _isProcessing
                  ? const CircularProgressIndicator(color: Colors.deepPurpleAccent)
                  : Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurpleAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _validarDocumento,
                            icon: const Icon(Icons.upload_file_rounded),
                            label: const Text("Seleccionar Archivo a Validar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text("O verificar por código Hash", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                        ),
                        TextField(
                          controller: _hashController,
                          decoration: InputDecoration(
                            labelText: "Pega el Hash del documento (0x...)",
                            prefixIcon: const Icon(Icons.tag_rounded, color: Colors.deepPurpleAccent),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onSubmitted: (_) => _validarPorHash(),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.deepPurpleAccent,
                              side: const BorderSide(color: Colors.deepPurpleAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _validarPorHash,
                            icon: const Icon(Icons.search_rounded),
                            label: const Text("Verificar Hash en Blockchain", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}