import 'dart:convert';
import 'dart:io';
import 'package:dapp_movil/config/api_config.dart';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/document_notary/modals/create_document_modal.dart';
import 'package:dapp_movil/modules/document_notary/modals/document_details_modal.dart';
import 'package:dapp_movil/core/notifications/push_notification_service.dart';
import 'package:dapp_movil/modules/document_notary/services/notary_service.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:crypto/crypto.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/transaction_skeleton.dart';

class DocumentNotaryScreen extends StatefulWidget {
 // final BlockchainService service;
  const DocumentNotaryScreen({super.key});

  @override
  State<DocumentNotaryScreen> createState() => _DocumentNotaryScreenState();
}

class _DocumentNotaryScreenState extends State<DocumentNotaryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _pendingDocs = [];

  List<dynamic> _historyDocs = [];
  String _filtroHistorial = "Todos"; 
  bool _isHistoryLoading = true;

  IOWebSocketChannel? _wsChannel;

  final ScrollController _scrollController = ScrollController();
  bool _isFetchingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 0;

  //  AGREGAR:
  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);
  NotaryService get notaryService => Provider.of<NotaryService>(context, listen: false);

@override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarDatos();
    _conectarWebSocket();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revisarNotificacionesPendientes();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _cargarMasHistorial();
      }
    });
  }

Future<void> _cargarDatos() async {
    final cacheService = LocalCacheService();
    final wallet = authCore.publicAddress.toLowerCase();

    // Caché Inicial Inmediata
    final cachedPending = cacheService.getCachedPendingDocuments(wallet);
    final cachedHistory = cacheService.getCachedDocumentHistory(wallet);

    if (cachedPending.isNotEmpty || cachedHistory.isNotEmpty) {
      if (mounted) setState(() { _pendingDocs = cachedPending; _historyDocs = cachedHistory; _isLoading = false; });
    } else {
      if (mounted) setState(() => _isLoading = true);
    }

    _currentPage = 0;
    _hasMoreData = true;

    // Red
 var results = await Future.wait([
      notaryService.getPendingDocuments(),
      notaryService.getDocumentHistoryPaged(page: 0) // 🔥 Nueva llamada
    ]);

    if (mounted) {
      setState(() { 
       
        _pendingDocs = results[0] as List<dynamic>; 
        
        _historyDocs = (results[1] as Map)['content'] ?? []; 
        _hasMoreData = !((results[1] as Map)['last'] ?? true);
        _isLoading = false; 
      });
    }
  }

  Future<void> _cargarMasHistorial() async {
    if (_isFetchingMore || !_hasMoreData || _isLoading) return;
    setState(() => _isFetchingMore = true);
    _currentPage++;

    final data = await notaryService.getDocumentHistoryPaged(page: _currentPage);
    
    if (mounted) {
      setState(() {
        _historyDocs.addAll(data['content'] ?? []);
        _hasMoreData = !(data['last'] ?? true);
        _isFetchingMore = false;
      });
    }
  }

  // 🔥 NUEVA FUNCIÓN PARA ABRIR EL DOCUMENTO AUTOMÁTICAMENTE
  void _revisarNotificacionesPendientes() {
    final route = PushNotificationService.pendingRoute; // Leemos la variable global

    // Verificamos si hay una ruta y si el backend indicó que es de la Notaría
    if (route != null && route['type'] == 'NOTARY') {
      String docHash = route['id']; // El backend mandó el docHash aquí
      
      // Limpiamos la variable para que el modal no se vuelva a abrir si recarga la pantalla
      PushNotificationService.pendingRoute = null; 

      // Abrimos el modal que ya tienes construido, sin inventar nada nuevo
      DocumentDetailsModal.show(
        context: context, 
        docHash: docHash, 
      );
    }
  }

  Future<void> _cargarHistorial() async {
    setState(() => _isHistoryLoading = true);
    final docs = await notaryService.getDocumentHistory();
    if (mounted) {
      setState(() {
        _historyDocs = docs;
        _isHistoryLoading = false;
      });
    }
  }

  // --- WIDGET DE FILTROS ---
  Widget _buildFiltrosHistorial() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: ['Todos', 'Completados', 'En curso'].map((filtro) {
          bool isSelected = _filtroHistorial == filtro;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              showCheckmark: isSelected,
              checkmarkColor: const Color(0xFF4A64F6), // Azul vibrante
              label: Text(
                filtro,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF4A64F6) : Colors.grey[400],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (val) { if(val) setState(() => _filtroHistorial = filtro); },
              backgroundColor: const Color(0xFF1E2336), // Fondo oscuro inactivo
              selectedColor: const Color(0xFFBCC6FF), // Fondo azul claro activo
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.transparent),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _cargarPendientes() async {
    setState(() => _isLoading = true);
    final docs = await notaryService.getPendingDocuments();
    if (mounted) {
      setState(() {
        _pendingDocs = docs;
        _isLoading = false;
      });
    }
  }

  //  4. MÉTODO DE CONEXIÓN
 void _conectarWebSocket() {
    try {
      // Reemplazamos http por ws y usamos la ruta correcta
      String baseWsUrl = ApiConfig.baseUrl.replaceFirst('http', 'ws');
      String wsUrl = "$baseWsUrl/ws/documents/${authCore.publicAddress.toLowerCase()}";
      
      _wsChannel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: authCore.authHeaders, // 🔥 FIX: Agregamos Auth Headers para que el servidor lo acepte
      );

      _wsChannel!.stream.listen((message) {
        print("[WS-DOCS] Evento recibido: $message");
        try {
          final parsed = jsonDecode(message);
          if (parsed['type'] == "DOCUMENT_UPDATED") {
            print("[WS-DOCS] Refrescando listas de notaría silenciosamente...");
            _cargarDatos();
          }
        } catch (_) {
          // Fallback por si el backend mandara texto simple
          if (message.toString().contains("DOCUMENT_UPDATED")) {
             _cargarDatos();
          }
        }
      }, onError: (err) {
        print("Error WS Notaría: $err");
      });
    } catch (e) {
      print("Error conectando WS Notaría: $e");
    }
  }

  
 @override
  void dispose() {
    _scrollController.dispose();
    _wsChannel?.sink.close();
    _tabController.dispose();
    super.dispose();
  }

  // Extraer el Hash SHA-256 del archivo
  Future<String?> _generarHashDeArchivo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      // Puedes añadir más extensiones si lo deseas
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'], 
    );

    // Si el usuario seleccionó un archivo correctamente:
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      List<int> fileBytes = await file.readAsBytes();
      Digest docHash = sha256.convert(fileBytes);
      
      // 🔥 Retornamos el hash con el "0x" directamente desde AQUÍ adentro
      return "0x${docHash.toString()}"; 
    }
    
    // Si el usuario canceló el selector de archivos, retornamos null
    return null;
  }

  // ✍️ FLUJO: Firmar un documento pendiente
  Future<void> _firmarDocumento(dynamic doc) async {
    // 1. Validar identidad con Huella Dactilar
    bool auth = await authCore.authenticateUser();
    if (!auth) return;

    showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Firmando Contrato", message: "Escribiendo firma inmutable en la blockchain..."));

    // 2. Llamada delegada (El backend hace el trabajo pesado)
    String res = await notaryService.signDocumentDelegated(doc['docHash']);

    if (mounted) Navigator.pop(context); // Cierra skeleton

    if (res.startsWith("Exito")) {
      UIHelper.showCustomSnackbar("Documento firmado inmutablemente");
      _cargarPendientes(); // Recargar lista
    } else {
      UIHelper.showCustomSnackbar("Error: $res", isError: true);
    }
  }
  // 📤 FLUJO: Crear y subir un nuevo documento
  Future<void> _crearNuevoDocumento() async {
    String? hash = await _generarHashDeArchivo();
    if (hash == null) return; // El usuario canceló

    if (!mounted) return;

    // 🔥 ABRIMOS EL MODAL DE CONFIGURACIÓN
    CreateDocumentModal.show(
      context: context, 
      fileHash: hash,  
      onConfirm: (String titulo, List<String> firmantes) async {
        
        // Simulación de URL (en el futuro subirías el archivo a Firebase/AWS aquí)
        String fileUrlMock = "https://tu-servidor.com/pdf/documento_guardado.pdf"; 
        
        showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Registrando Contrato", message: "Inscribiendo huella digital en la blockchain..."));

        // 1. Llamada delegada (El backend escribe en Solidity y MongoDB a la vez)
        String res = await notaryService.createDocumentDelegated(hash, titulo, fileUrlMock, firmantes);
        
        if (mounted) Navigator.pop(context); // Quitar skeleton

        if (res.startsWith("Exito")) {
          UIHelper.showCustomSnackbar("Documento registrado con éxito");
          _cargarPendientes();
          _tabController.animateTo(0); // Regresar a la pestaña de pendientes
        } else {
          UIHelper.showCustomSnackbar("Error: $res", isError: true);
        }
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    List<dynamic> docsFiltrados = _historyDocs.where((doc) {
      if (_filtroHistorial == "Completados") return doc['fullySigned'] == true;
      if (_filtroHistorial == "En curso") return doc['fullySigned'] == false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Contratos Inteligentes"),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.description_rounded), text: "Por Firmar"),
            Tab(icon: Icon(Icons.difference_rounded), text: "Crear Nuevo"),
            Tab(icon: Icon(Icons.history_rounded), text: "Historial"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // --- TAB 1: POR FIRMAR ---
          _isLoading 
            ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
            : _pendingDocs.isEmpty
              ? UIHelper.emptyState(
                  context: context, 
                  icon: Icons.verified_user_rounded, 
                  title: "Todo al día", 
                  message: "No tienes acuerdos pendientes por firmar."
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingDocs.length,
                  itemBuilder: (ctx, i) {
                    var doc = _pendingDocs[i];
                    
                    //  CARGAR USUARIOS DINÁMICAMENTE
                    List<dynamic> signers = doc['requiredSigners'] ?? doc['signers'] ?? [];
                    String signersText = signers.isNotEmpty ? signers.join(' / ') : 'Sin firmantes asignados';

                    return GestureDetector(
                      onTap: () {
                        DocumentDetailsModal.show(context: context, docHash: doc['docHash']);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor, // 🔥 Color dinámico del tema
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.description_rounded, color: colorScheme.primary),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc['title'] ?? 'Documento sin título', 
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.people_alt_outlined, size: 14, color: colorScheme.onSurface.withOpacity(0.6)),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              signersText, // 🔥 Usuarios reales cargados aquí
                                              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary, 
                                    foregroundColor: colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    elevation: 0,
                                  ),
                                  onPressed: () => _firmarDocumento(doc),
                                  child: const Text("Firmar", style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.scaffoldBackgroundColor, // 🔥 Fondo de contraste del tema
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Hash:  ${doc['docHash']}",
                                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 12, fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

          // --- TAB 2: CREAR NUEVO ---
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
                  ),
                  child: Icon(Icons.fingerprint_rounded, size: 60, color: colorScheme.primary.withOpacity(0.5)),
                ),
                const SizedBox(height: 30),
                Text(
                  "Sube un PDF para generar su huella\ndigital criptográfica (SHA-256) e\ninscribirlo en la Blockchain.", 
                  textAlign: TextAlign.center, 
                  style: TextStyle(fontSize: 16, color: colorScheme.onSurface, height: 1.5)
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text("Gasless Network", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    onPressed: _crearNuevoDocumento,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text("Seleccionar PDF y Registrar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),

          // --- TAB 3: HISTORIAL ---
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: TextField(
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: "Buscar documentos, hashes...",
                    hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.4)),
                    filled: true,
                    fillColor: theme.cardColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              _buildFiltrosHistorial(),
             Expanded(
                child: RefreshIndicator(
                  onRefresh: _cargarDatos,
                  child: _isLoading && docsFiltrados.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : docsFiltrados.isEmpty
                      ? UIHelper.emptyState(context: context, icon: Icons.folder_open_rounded, title: "Sin documentos", message: "No se encontraron registros.")
                      : ListView.builder(
                          controller: _scrollController, // 🔥 Agregado
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: docsFiltrados.length + (_isFetchingMore ? 1 : 0),
                          itemBuilder: (ctx, i) {
                            if (i == docsFiltrados.length) return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()));
                            
                            var doc = docsFiltrados[i];
                            bool isDone = doc['fullySigned'] ?? false;
                            String fullHash = doc['docHash'].toString();
                            
                            // 🔥 Nuevos campos optimizados del DTO
                            int totalFirmas = doc['totalSigned'] ?? 0;
                            int metaFirmas = doc['totalRequiredSigners'] ?? 1;

                            return GestureDetector(
                              onTap: () {
                                DocumentDetailsModal.show(context: context, docHash: fullHash);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isDone ? Colors.teal.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isDone ? Icons.check_circle_rounded : Icons.pending_actions_rounded, 
                                        color: isDone ? Colors.teal : Colors.orange
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(doc['title'] ?? 'Documento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface)),
                                          const SizedBox(height: 4),
                                          Text(
                                            isDone ? "Firmado inmutablemente" : "Firmas: $totalFirmas/$metaFirmas", // 🔥 Modificado para mostrar progreso 
                                            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 13)
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: theme.scaffoldBackgroundColor,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              fullHash, 
                                              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 11, fontFamily: 'monospace'),
                                              overflow: TextOverflow.ellipsis, 
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded, color: colorScheme.onSurface, size: 24),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}