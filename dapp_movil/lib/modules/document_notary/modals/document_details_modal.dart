import 'package:dapp_movil/core/helpers/share_helper.dart';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/core/services/smart_avatar.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/document_notary/services/notary_service.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
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
      height: MediaQuery.of(context).size.height * 0.90, // Un poco más alto para mejor vista de PDF
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor, // Fondo general oscuro
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
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
                        Text("Estado del Documento", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurfaceColor)),
                        IconButton(icon: Icon(Icons.close_rounded, color: onSurfaceColor), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- TARJETA ESTADO GENERAL DEL DOCUMENTO ---
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: onSurfaceColor.withOpacity(0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_docInfo!['title'] ?? 'Sin título', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: onSurfaceColor)),
                          const SizedBox(height: 8),
                          Text(
                            _docInfo!['fullySigned'] ? "Ejecutado e inmutable" : "Esperando firmas...",
                            style: TextStyle(color: _docInfo!['fullySigned'] ? const Color(0xFF10B981) : Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          Text("SHA-256 Hash", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurfaceColor.withOpacity(0.7))),
                          const SizedBox(height: 8),
                          // Bloque de Hash con Copiar
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: widget.docHash));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hash copiado al portapapeles")));
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.scaffoldBackgroundColor, // Fondo un poco más oscuro
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: onSurfaceColor.withOpacity(0.1)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.docHash,
                                      style: TextStyle(fontSize: 12, color: onSurfaceColor, fontFamily: 'monospace', height: 1.4),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.copy_rounded, size: 20, color: onSurfaceColor.withOpacity(0.6)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Puedes verificar la integridad de este documento utilizando este Hash en el Validador Criptográfico.",
                            style: TextStyle(fontSize: 12, color: onSurfaceColor.withOpacity(0.6), height: 1.4),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),


             
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _mostrarVistaPrevia = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: !_mostrarVistaPrevia ? onSurfaceColor.withOpacity(0.05) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text("Firmantes", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: !_mostrarVistaPrevia ? const Color(0xFFBAC3FF) : onSurfaceColor.withOpacity(0.5))),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _mostrarVistaPrevia = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: _mostrarVistaPrevia ? onSurfaceColor.withOpacity(0.05) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text("Documento PDF", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: _mostrarVistaPrevia ? const Color(0xFFBAC3FF) : onSurfaceColor.withOpacity(0.5))),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // --- ÁREA DINÁMICA: Muestra Lista o Muestra PDF ---
                   Expanded(
                      child: _mostrarVistaPrevia 
                        ? _construirVistaPreviaPDF(colorScheme)
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: (_docInfo!['requiredSigners'] as List).length,
                            itemBuilder: (ctx, i) {
                              String requiredSigner = _docInfo!['requiredSigners'][i].toString().toLowerCase();
                              List<dynamic> signedByList = _docInfo!['signedBy'] ?? [];
                              bool hasSigned = signedByList.map((e) => e.toString().toLowerCase()).contains(requiredSigner);
                              bool isMe = requiredSigner == authCore.publicAddress.toLowerCase();

                              String shortWallet = "${requiredSigner.substring(0, 6)}...${requiredSigner.substring(requiredSigner.length - 4)}";
                              String nameDisplay = isMe ? "Tú" : (hasSigned ? "Firmado" : "Pendiente"); 

                              final userService = Provider.of<UserService>(context, listen: false);

                              return FutureBuilder<Map<String, dynamic>?>(
                                future: userService.getUserByWallet(requiredSigner),
                                builder: (context, snapshot) {
                                  String realAlias = isMe ? "@tú" : "@usuario_${requiredSigner.substring(2, 5)}";
                                  String realCedula = "Oculto";
                                  String realEmail = "Oculto";

                                  if (snapshot.hasData && snapshot.data != null) {
                                    realAlias = "@${snapshot.data!['alias'] ?? 'desconocido'}";
                                    realCedula = isMe ? (snapshot.data!['cedula'] ?? "No registrada") : "Oculto";
                                    realEmail = isMe ? (snapshot.data!['email'] ?? "No registrado") : "Oculto";
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: onSurfaceColor.withOpacity(0.05)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            SmartAvatar(address: requiredSigner, size: 48),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(nameDisplay, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: onSurfaceColor)),
                                                  Text(realAlias, style: TextStyle(color: onSurfaceColor.withOpacity(0.5), fontSize: 13)),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.transparent,
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: hasSigned ? const Color(0xFF10B981).withOpacity(0.5) : onSurfaceColor.withOpacity(0.2)),
                                              ),
                                              child: Text(
                                                hasSigned ? "Firmado" : "Esperando", 
                                                style: TextStyle(color: hasSigned ? const Color(0xFF10B981) : onSurfaceColor.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold)
                                              ),
                                            )
                                          ],
                                        ),
                                        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Colors.white10)),
                                        _buildFirmanteInfoRow("Wallet", shortWallet.toUpperCase(), onSurfaceColor, isCopyable: true, fullData: requiredSigner),
                                        _buildFirmanteInfoRow("Identificación", realCedula, onSurfaceColor),
                                        _buildFirmanteInfoRow("Email", realEmail, onSurfaceColor),
                                      ],
                                    ),
                                  );
                                }
                              );
                            },
                          ),
                    ),



                    const SizedBox(height: 16),

                    // --- BOTONES INFERIORES FIJOS ---
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary, // Limpiado de Color quemado
                                  foregroundColor: colorScheme.onPrimary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: () {
                                  // Verificamos si la cadena existe y parece un enlace
                                  String url = _docInfo!['fileUrl']?.toString() ?? "";
                                  if (url.startsWith('http') || url.startsWith('ipfs')) {
                                    _abrirPDFExterno(url); // Utilizamos la app del teléfono para evitar problemas de compatibilidad del visor interno
                                  } else {
                                    UIHelper.showCustomSnackbar("El creador no ha proporcionado un enlace público para visualizar el documento original.", isError: true);
                                  }
                                },
                                icon: const Icon(Icons.open_in_browser_rounded, size: 20),
                                label: const Text("Abrir Archivo Original", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.primary, // Limpiado de Color quemado
                                  side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: () {
                                  ShareHelper.generarYCompartirCertificadoNotarial(context, _docInfo!, authCore.publicAddress);
                                },
                                icon: const Icon(Icons.qr_code_rounded, size: 20),
                                label: const Text("Descargar Certificado Blockchain", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  // WIDGET HELPER PARA LAS FILAS DEL FIRMANTE
  Widget _buildFirmanteInfoRow(String label, String value, Color onSurfaceColor, {bool isCopyable = false, String fullData = ""}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: onSurfaceColor.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Text(value, style: TextStyle(color: onSurfaceColor, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: isCopyable ? 'monospace' : null)),
              if (isCopyable) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: fullData));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copiado al portapapeles")));
                  },
                  child: Icon(Icons.copy_rounded, size: 16, color: onSurfaceColor.withOpacity(0.5)),
                )
              ]
            ],
          )
        ],
      ),
    );
  }
  
  // @override
  // Widget build(BuildContext context) {
  //  final theme = Theme.of(context);
  //   final colorScheme = theme.colorScheme;
  //   final onSurfaceColor = colorScheme.onSurface;

  //   return Container(
  //     height: MediaQuery.of(context).size.height * 0.88,
  //     decoration: BoxDecoration(
  //       color: theme.scaffoldBackgroundColor,
  //       borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
  //     ),
  //     padding: const EdgeInsets.all(24),
  //     child: _isLoading
  //         ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
  //         : _docInfo == null
  //             ? const Center(child: Text("Documento no encontrado o alterado."))
  //             : Column(
  //                 crossAxisAlignment: CrossAxisAlignment.stretch,
  //                 children: [
  //                   // --- CABECERA ---
  //                   Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       const Text("Estado del Documento", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
  //                       IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 10),

  //                   // --- ESTADO GENERAL ---
  //                   Container(
  //                     padding: const EdgeInsets.all(16),
  //                     decoration: BoxDecoration(
  //                       color: _docInfo!['fullySigned'] ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
  //                       borderRadius: BorderRadius.circular(16)
  //                     ),
  //                     child: Row(
  //                       children: [
  //                         Icon(
  //                           _docInfo!['fullySigned'] ? Icons.verified_rounded : Icons.pending_actions_rounded, 
  //                           color: _docInfo!['fullySigned'] ? Colors.green : Colors.orange,
  //                           size: 32,
  //                         ),
  //                         const SizedBox(width: 12),
  //                         Expanded(
  //                           child: Column(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                               Text(_docInfo!['title'] ?? 'Sin título', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  //                               Text(
  //                                 _docInfo!['fullySigned'] ? "Ejecutado e inmutable" : "Esperando firmas...",
  //                                 style: TextStyle(color: _docInfo!['fullySigned'] ? Colors.green : Colors.orange, fontWeight: FontWeight.bold),
  //                               ),
  //                               const SizedBox(height: 6),
  //                               InkWell(
  //                                 onTap: () {
  //                                   Clipboard.setData(ClipboardData(text: widget.docHash));
  //                                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hash copiado al portapapeles")));
  //                                 },
  //                                 child: Row(
  //                                   children: [
  //                                     Icon(Icons.copy_rounded, size: 14, color: onSurfaceColor.withOpacity(0.5)),
  //                                     const SizedBox(width: 4),
  //                                     Text(
  //                                       "Hash: ${widget.docHash.substring(0, 10)}...",
  //                                       style: TextStyle(fontSize: 12, color: onSurfaceColor.withOpacity(0.5), decoration: TextDecoration.underline),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         )
  //                       ],
  //                     ),
  //                   ),
  //                   const SizedBox(height: 20),


  //                   // 🔥 NUEVO: TOGGLE DE PESTAÑAS (Firmantes vs Vista Previa) 🔥
  //                   Container(
  //                     padding: const EdgeInsets.all(4),
  //                     decoration: BoxDecoration(
  //                       color: onSurfaceColor.withOpacity(0.05),
  //                       borderRadius: BorderRadius.circular(16),
  //                     ),
  //                     child: Row(
  //                       children: [
  //                         Expanded(
  //                           child: GestureDetector(
  //                             onTap: () => setState(() => _mostrarVistaPrevia = false),
  //                             child: AnimatedContainer(
  //                               duration: const Duration(milliseconds: 200),
  //                               padding: const EdgeInsets.symmetric(vertical: 12),
  //                               decoration: BoxDecoration(
  //                                 color: !_mostrarVistaPrevia ? theme.cardColor : Colors.transparent,
  //                                 borderRadius: BorderRadius.circular(12),
  //                                 boxShadow: !_mostrarVistaPrevia ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
  //                               ),
  //                               child: Text("Firmantes", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: !_mostrarVistaPrevia ? colorScheme.primary : onSurfaceColor.withOpacity(0.5))),
  //                             ),
  //                           ),
  //                         ),
  //                         Expanded(
  //                           child: GestureDetector(
  //                             onTap: () => setState(() => _mostrarVistaPrevia = true),
  //                             child: AnimatedContainer(
  //                               duration: const Duration(milliseconds: 200),
  //                               padding: const EdgeInsets.symmetric(vertical: 12),
  //                               decoration: BoxDecoration(
  //                                 color: _mostrarVistaPrevia ? theme.cardColor : Colors.transparent,
  //                                 borderRadius: BorderRadius.circular(12),
  //                                 boxShadow: _mostrarVistaPrevia ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
  //                               ),
  //                               child: Text("Documento PDF", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: _mostrarVistaPrevia ? colorScheme.primary : onSurfaceColor.withOpacity(0.5))),
  //                             ),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   const SizedBox(height: 16),
                    
  //                   // --- ÁREA DINÁMICA: Muestra Lista o Muestra PDF ---
  //                   Expanded(
  //                     child: _mostrarVistaPrevia 
  //                       ? _construirVistaPreviaPDF(colorScheme)
  //                       : ListView.builder(
  //                           itemCount: (_docInfo!['requiredSigners'] as List).length,
  //                           itemBuilder: (ctx, i) {
  //                             String requiredSigner = _docInfo!['requiredSigners'][i].toString().toLowerCase();
  //                             List<dynamic> signedByList = _docInfo!['signedBy'] ?? [];
                              
  //                             bool hasSigned = signedByList.map((e) => e.toString().toLowerCase()).contains(requiredSigner);

  //                             return ListTile(
  //                               contentPadding: EdgeInsets.zero,
  //                               leading: CircleAvatar(
  //                                 backgroundColor: hasSigned ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
  //                                 child: Icon(
  //                                   hasSigned ? Icons.check_circle_rounded : Icons.access_time_rounded,
  //                                   color: hasSigned ? Colors.green : Colors.orange,
  //                                 ),
  //                               ),
  //                               title: Text(
  //                                 requiredSigner == authCore.publicAddress.toLowerCase() ? "Tú" : "${requiredSigner.substring(0, 8)}...${requiredSigner.substring(requiredSigner.length - 4)}",
  //                                 style: const TextStyle(fontWeight: FontWeight.bold),
  //                               ),
  //                               subtitle: Text(hasSigned ? "Firma registrada en Blockchain" : "Pendiente de firma"),
  //                             );
  //                           },
  //                         ),
  //                   ),

  //                   const SizedBox(height: 16),


  //                   // --- BOTÓN VER DOCUMENTO ---
  //                   const SizedBox(height: 16),
  //                   ElevatedButton.icon(
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: colorScheme.primary,
  //                       foregroundColor: colorScheme.onPrimary,
  //                       padding: const EdgeInsets.symmetric(vertical: 16),
  //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //                     ),
  //                     onPressed: () {
  //                       if (_docInfo!['fileUrl'] != null && _docInfo!['fileUrl'].toString().isNotEmpty) {
  //                         _abrirPDF(_docInfo!['fileUrl']);
  //                       } else {
  //                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El archivo no está disponible')));
  //                       }
  //                     },
  //                     icon: const Icon(Icons.picture_as_pdf_rounded),
  //                     label: const Text("Ver Documento Original", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  //                   ),

  //                   const SizedBox(height: 10),

  //                   // 🔥 2. NUEVO: Generar el Certificado Notarial de Blockchain
  //                   OutlinedButton.icon(
  //                     style: OutlinedButton.styleFrom(
  //                       padding: const EdgeInsets.symmetric(vertical: 16),
  //                       foregroundColor: colorScheme.primary,
  //                       side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
  //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //                     ),
  //                     onPressed: () {
  //                       ShareHelper.generarYCompartirCertificadoNotarial(
  //                         context, 
  //                         _docInfo!, 
  //                         authCore.publicAddress
  //                       );
  //                     },
  //                     icon: const Icon(Icons.qr_code_rounded),
  //                     label: const Text("Descargar Certificado Blockchain", style: TextStyle(fontWeight: FontWeight.bold)),
  //                   )
  //                 ],
  //               ),
                
  //   );
  // }
}