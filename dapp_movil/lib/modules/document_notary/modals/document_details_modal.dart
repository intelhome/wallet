import 'package:dapp_movil/core/helpers/share_helper.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/document_notary/services/notary_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class DocumentDetailsModal extends StatefulWidget {
  final String docHash;
  //final BlockchainService service;

  const DocumentDetailsModal({
    super.key,
    required this.docHash,
   // required this.service,
  });

  static void show({
    required BuildContext context,
    required String docHash,
    //required BlockchainService service,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DocumentDetailsModal(docHash: docHash),
    );
  }

  @override
  State<DocumentDetailsModal> createState() => _DocumentDetailsModalState();
}

class _DocumentDetailsModalState extends State<DocumentDetailsModal> {

  NotaryService get notaryService => Provider.of<NotaryService>(context, listen: false);
AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);

  bool _isLoading = true;
  Map<String, dynamic>? _docInfo;

  bool _mostrarVistaPrevia = false;

  @override
  void initState() {
    super.initState();
    _cargarInfo();
  }

  Future<void> _cargarInfo() async {
    final info = await notaryService.getDocumentInfo(widget.docHash);
    if (mounted) {
      setState(() {
        _docInfo = info;
        _isLoading = false;
      });
    }
  }

  Future<void> _abrirPDF(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el documento'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _abrirPDFExterno(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el documento'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _construirVistaPreviaPDF(ColorScheme colorScheme) {
    if (_docInfo!['fileUrl'] == null || _docInfo!['fileUrl'].toString().isEmpty) {
      return Container(
        decoration: BoxDecoration(color: colorScheme.onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text("El archivo no está disponible")),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(16)
        ),
        // 🔥 MAGIA: Renderizado de PDF directo desde la URL
        child: SfPdfViewer.network(
          _docInfo!['fileUrl'],
          canShowScrollHead: false, // Oculta barras feas de scroll extra
          canShowScrollStatus: false,
          enableDoubleTapZooming: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
   final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurfaceColor = colorScheme.onSurface;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : _docInfo == null
              ? const Center(child: Text("Documento no encontrado o alterado."))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- CABECERA ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Estado del Documento", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // --- ESTADO GENERAL ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _docInfo!['fullySigned'] ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16)
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _docInfo!['fullySigned'] ? Icons.verified_rounded : Icons.pending_actions_rounded, 
                            color: _docInfo!['fullySigned'] ? Colors.green : Colors.orange,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(_docInfo!['title'] ?? 'Sin título', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(
                                  _docInfo!['fullySigned'] ? "Ejecutado e inmutable" : "Esperando firmas...",
                                  style: TextStyle(color: _docInfo!['fullySigned'] ? Colors.green : Colors.orange, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: widget.docHash));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hash copiado al portapapeles")));
                                  },
                                  child: Row(
                                    children: [
                                      Icon(Icons.copy_rounded, size: 14, color: onSurfaceColor.withOpacity(0.5)),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Hash: ${widget.docHash.substring(0, 10)}...",
                                        style: TextStyle(fontSize: 12, color: onSurfaceColor.withOpacity(0.5), decoration: TextDecoration.underline),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),


                    // 🔥 NUEVO: TOGGLE DE PESTAÑAS (Firmantes vs Vista Previa) 🔥
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: onSurfaceColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _mostrarVistaPrevia = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_mostrarVistaPrevia ? theme.cardColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: !_mostrarVistaPrevia ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
                                ),
                                child: Text("Firmantes", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: !_mostrarVistaPrevia ? colorScheme.primary : onSurfaceColor.withOpacity(0.5))),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _mostrarVistaPrevia = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _mostrarVistaPrevia ? theme.cardColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _mostrarVistaPrevia ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
                                ),
                                child: Text("Documento PDF", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: _mostrarVistaPrevia ? colorScheme.primary : onSurfaceColor.withOpacity(0.5))),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // --- ÁREA DINÁMICA: Muestra Lista o Muestra PDF ---
                    Expanded(
                      child: _mostrarVistaPrevia 
                        ? _construirVistaPreviaPDF(colorScheme)
                        : ListView.builder(
                            itemCount: (_docInfo!['requiredSigners'] as List).length,
                            itemBuilder: (ctx, i) {
                              String requiredSigner = _docInfo!['requiredSigners'][i].toString().toLowerCase();
                              List<dynamic> signedByList = _docInfo!['signedBy'] ?? [];
                              
                              bool hasSigned = signedByList.map((e) => e.toString().toLowerCase()).contains(requiredSigner);

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: hasSigned ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                  child: Icon(
                                    hasSigned ? Icons.check_circle_rounded : Icons.access_time_rounded,
                                    color: hasSigned ? Colors.green : Colors.orange,
                                  ),
                                ),
                                title: Text(
                                  requiredSigner == authCore.publicAddress.toLowerCase() ? "Tú" : "${requiredSigner.substring(0, 8)}...${requiredSigner.substring(requiredSigner.length - 4)}",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(hasSigned ? "Firma registrada en Blockchain" : "Pendiente de firma"),
                              );
                            },
                          ),
                    ),

                    const SizedBox(height: 16),


                    // --- BOTÓN VER DOCUMENTO ---
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        if (_docInfo!['fileUrl'] != null && _docInfo!['fileUrl'].toString().isNotEmpty) {
                          _abrirPDF(_docInfo!['fileUrl']);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El archivo no está disponible')));
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text("Ver Documento Original", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),

                    const SizedBox(height: 10),

                    // 🔥 2. NUEVO: Generar el Certificado Notarial de Blockchain
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        ShareHelper.generarYCompartirCertificadoNotarial(
                          context, 
                          _docInfo!, 
                          authCore.publicAddress
                        );
                      },
                      icon: const Icon(Icons.qr_code_rounded),
                      label: const Text("Descargar Certificado Blockchain", style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                
    );
  }
}