import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/core/services/smart_avatar.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/groups_and_social/services/group_social_service.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';

class GroupMembersTab extends StatelessWidget {
  final Map<String, dynamic> group;
  final String miEstado;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onActualizarGrupo;

  const GroupMembersTab({super.key, required this.group, required this.miEstado, required this.searchQuery, required this.onSearchChanged, required this.onActualizarGrupo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    final cardColor = theme.cardColor;
    List<dynamic> members = group['members'] ?? [];
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final groupService = Provider.of<GroupSocialService>(context, listen: false);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: TextField(
            style: TextStyle(color: onSurface),
            decoration: InputDecoration(
              hintText: "Buscar alias o wallet...",
              hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
              prefixIcon: Icon(Icons.search_rounded, color: onSurface.withOpacity(0.5)),
              filled: true,
              fillColor: cardColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              final filteredMembers = members.where((m) {
                final alias = m['alias'].toString().toLowerCase();
                final wallet = m['walletAddress'].toString().toLowerCase();
                final query = searchQuery.toLowerCase();
                return alias.contains(query) || wallet.contains(query);
              }).toList();

              if (filteredMembers.isEmpty) return UIHelper.emptyState(context: context, icon: Icons.group_off_rounded, title: "Sin resultados", message: "No se encontraron miembros.");
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                itemCount: filteredMembers.length,
                itemBuilder: (ctx, i) {
                  var m = filteredMembers[i];
                  bool isPending = m['status'] == "PENDING";
                  final userService = Provider.of<UserService>(context, listen: false);

                  return FutureBuilder<Map<String, dynamic>?>(
                    future: userService.getUserByWallet(m['walletAddress']),
                    builder: (context, snapshot) {
                      String cedulaReal = "No registrada";
                      String celularReal = "No registrado";
                      String aliasReal = m['alias'] ?? "Desconocido";

                      if (snapshot.hasData && snapshot.data != null) {
                        cedulaReal = snapshot.data!['cedula'] ?? "No registrada";
                        celularReal = snapshot.data!['phoneNumber'] ?? "No registrado";
                        aliasReal = snapshot.data!['alias'] ?? aliasReal;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                SmartAvatar(address: m['walletAddress'] ?? '', size: 48),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("@$aliasReal", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: isPending ? colorScheme.secondary.withOpacity(0.2) : colorScheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                        child: Text(m['status'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isPending ? colorScheme.secondary : colorScheme.primary)),
                                      ),
                                    ],
                                  ),
                                ),
                                if (miEstado == "CREATOR") ...[
                                  Icon(Icons.settings_outlined, color: onSurface.withOpacity(0.5), size: 20),
                                  const SizedBox(width: 12),
                                  if (m['walletAddress'].toString().toLowerCase() != authCore.publicAddress.toLowerCase())
                                    GestureDetector(
                                      onTap: () async {
                                        String res = await groupService.removeGroupMember(group['id'], m['walletAddress']);
                                        if (res == "SUCCESS") { await onActualizarGrupo(); } else { UIHelper.showCustomSnackbar(res, isError: true); }
                                      },
                                      child: Icon(Icons.person_remove_outlined, color: onSurface.withOpacity(0.5), size: 20),
                                    ),
                                ]
                              ],
                            ),
                            const SizedBox(height: 16),
                            Divider(color: onSurface.withOpacity(0.05), height: 1),
                            const SizedBox(height: 12),
                            _buildMemberInfoRow("Cedula:", cedulaReal, onSurface),
                            _buildMemberInfoRow("Wallet:", "${m['walletAddress'].toString().substring(0,6)}...${m['walletAddress'].toString().substring(m['walletAddress'].toString().length-3)}", onSurface),
                            _buildMemberInfoRow("Celular:", celularReal, onSurface),
                          ],
                        ),
                      );
                    }
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMemberInfoRow(String label, String value, Color onSurface) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12))),
          Expanded(child: Text(value, style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600, fontFamily: label == 'Wallet:' ? 'monospace' : null))),
        ],
      ),
    );
  }
}