import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../config/api_config.dart';
import '../../../core/helpers/route_helper.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/smart_avatar.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../../chat_and_social/screens/chat_room_screen.dart';
import '../../groups_and_social/services/group_social_service.dart';

class UserMoreDetailsScreen extends StatefulWidget {
  final String wallet;
  final String alias;

  const UserMoreDetailsScreen({
    super.key,
    required this.wallet,
    required this.alias,
  });

  @override
  State<UserMoreDetailsScreen> createState() => _UserMoreDetailsScreenState();
}

class _UserMoreDetailsScreenState extends State<UserMoreDetailsScreen> {
  bool _isLoading = true;
  List<dynamic> _employers = [];
  List<dynamic> _mutualGroups = [];
  List<dynamic> _familyMembers = [];
  final Map<String, double> _groupBalances = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final myWallet = authCore.publicAddress.toLowerCase();
    final targetWallet = widget.wallet.toLowerCase();

    try {
      // 1. Obtener Empresa/Empleador del usuario destino
      final resEmp = await http.get(
        Uri.parse(ApiConfig.getMyEmployers.replaceAll("{address}", targetWallet)),
        headers: authCore.authHeaders
      );
      if (resEmp.statusCode == 200) {
        _employers = jsonDecode(resEmp.body);
      }

      // 2. Obtener Grupos Mutuos (Intersectando los míos con los suyos)
      final resMyGroups = await http.get(
        Uri.parse(ApiConfig.getUserGroups.replaceAll("{address}", myWallet)),
        headers: authCore.authHeaders
      );
      final resTargetGroups = await http.get(
        Uri.parse(ApiConfig.getUserGroups.replaceAll("{address}", targetWallet)),
        headers: authCore.authHeaders
      );

      if (resMyGroups.statusCode == 200 && resTargetGroups.statusCode == 200) {
        List<dynamic> myG = jsonDecode(resMyGroups.body);
        List<dynamic> tarG = jsonDecode(resTargetGroups.body);
        
        final myGroupIds = myG.map((g) => g['id']).toSet();
        _mutualGroups = tarG.where((g) => myGroupIds.contains(g['id'])).toList();

        // Cargar los balances de las bóvedas de los grupos mutuos
        final groupService = Provider.of<GroupSocialService>(context, listen: false);
        for(var g in _mutualGroups) {
           if (g['walletAddress'] != null) {
             _groupBalances[g['id']] = await groupService.getAnyWalletBalance(g['walletAddress']);
           }
        }
      }

      // 3. Obtener Familiares del usuario
      final resFam = await http.get(
        Uri.parse(ApiConfig.getFamilyMembers.replaceAll("{address}", targetWallet)),
        headers: authCore.authHeaders
      );
      if (resFam.statusCode == 200) {
        _familyMembers = jsonDecode(resFam.body);
      }

    } catch (e) {
      debugPrint("Error cargando detalles del usuario: $e");
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Más Detalles", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==========================================
                  // 1. CABECERA: PERFIL DEL USUARIO
                  // ==========================================
                  Row(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          SmartAvatar(address: widget.wallet, size: 70),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: const Color(0xFF4361EE), shape: BoxShape.circle, border: Border.all(color: theme.scaffoldBackgroundColor, width: 2)),
                            child: const Icon(Icons.verified_rounded, color: Colors.white, size: 12),
                          )
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("@${widget.alias}", style: TextStyle(color: onSurface, fontSize: 24, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  "${widget.wallet.substring(0, 6)}...${widget.wallet.substring(widget.wallet.length - 4)}",
                                  style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13, fontFamily: 'monospace'),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: widget.wallet));
                                    UIHelper.showCustomSnackbar("Billetera copiada al portapapeles");
                                  },
                                  child: Icon(Icons.copy_rounded, size: 16, color: onSurface.withOpacity(0.6)),
                                )
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ==========================================
                  // 2. EMPRESA
                  // ==========================================
                  if (_employers.isNotEmpty) ...[
                    _buildSectionTitle(Icons.domain_rounded, "Empresa", onSurface),
                    const SizedBox(height: 12),
                    ..._employers.map((emp) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: onSurface.withOpacity(0.05)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(emp['businessAlias'] ?? "Empresa S.A.", style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text("RUC: ${emp['businessWallet']?.toString().substring(0,10) ?? 'N/A'}", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: const Color(0xFF7209B7), borderRadius: BorderRadius.circular(12)),
                              child: Text(emp['role'] ?? "Empleado", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // ==========================================
                  // 3. GRUPOS MUTUOS
                  // ==========================================
                  if (_mutualGroups.isNotEmpty) ...[
                    _buildSectionTitle(Icons.people_alt_outlined, "Grupos", onSurface),
                    const SizedBox(height: 12),
                    ..._mutualGroups.map((g) {
                      double balance = _groupBalances[g['id']] ?? 0.0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: onSurface.withOpacity(0.05))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                                child: Icon(Icons.folder_shared_rounded, color: onSurface.withOpacity(0.6), size: 20),
                              ),
                              title: Text(g['name'], style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                              trailing: Icon(Icons.chevron_right_rounded, color: onSurface.withOpacity(0.5)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Divider(color: onSurface.withOpacity(0.05), height: 1),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("VAULT BALANCE", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                  const SizedBox(height: 4),
                                  Text("${balance.toStringAsFixed(2)} TTC", style: TextStyle(color: onSurface, fontSize: 24, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // ==========================================
                  // 4. FAMILIARES
                  // ==========================================
                  if (_familyMembers.isNotEmpty) ...[
                    _buildSectionTitle(Icons.family_restroom_rounded, "Familia", onSurface),
                    const SizedBox(height: 12),
                    ..._familyMembers.map((fam) {
                      String w = fam['walletAddress'] ?? fam['wallet'] ?? '';
                      String a = fam['alias'] ?? 'Familiar';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: onSurface.withOpacity(0.05))),
                        child: Row(
                          children: [
                            SmartAvatar(address: w, size: 48),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("@$a", style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.favorite_border_rounded, size: 12, color: onSurface.withOpacity(0.6)),
                                      const SizedBox(width: 4),
                                      Text(fam['type'] ?? fam['status'] ?? "Familiar", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chat_rounded),
                                  color: onSurface.withOpacity(0.6),
                                  style: IconButton.styleFrom(backgroundColor: onSurface.withOpacity(0.05)),
                                  onPressed: () => Navigator.push(context, RouteHelper.slideUpRoute(ChatRoomScreen(alias: a, address: w))),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.info_outline_rounded),
                                  color: onSurface.withOpacity(0.6),
                                  style: IconButton.styleFrom(backgroundColor: onSurface.withOpacity(0.05)),
                                  onPressed: () {}, // Acción futura para más info
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title, Color onSurface) {
    return Row(
      children: [
        Icon(icon, color: onSurface.withOpacity(0.7), size: 20),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}