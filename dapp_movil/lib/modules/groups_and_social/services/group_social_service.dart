import 'dart:convert';
import 'dart:ui';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';

class GroupSocialService {
  final AuthCoreService authCore;

  GroupSocialService(this.authCore);

  String _extractErrorMessage(String body, int statusCode) {
    try {
      final parsed = jsonDecode(body);
      return parsed['message'] ?? parsed['error'] ?? "Error HTTP $statusCode";
    } catch (_) {
      return "Error HTTP $statusCode";
    }
  }

  // --- GESTIÓN DE GRUPOS ---

  Future<List<dynamic>> getUserGroups() async {
    if (authCore.publicAddress.isEmpty) return [];
    try {
      final url = ApiConfig.getUserGroups.replaceAll("{address}", authCore.publicAddress.toLowerCase());
      final res = await http.get(Uri.parse(url), headers: authCore.authHeaders);
      return res.statusCode == 200 ? jsonDecode(res.body) : [];
    } catch (e) {
      return [];
    }
  }

  Future<String> createGroup(String name, String myAlias, List<Map<String, dynamic>> members) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.createGroup),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "name": name,
          "creatorAddress": authCore.publicAddress.toLowerCase(),
          "creatorAlias": myAlias,
          "members": members
        })
      );
      return res.statusCode == 200 ? "SUCCESS" : _extractErrorMessage(res.body, res.statusCode);
    } catch (e) {
      return "Error de red";
    }
  }

  Future<String> acceptGroupInvite(String groupId, String signature) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.acceptGroupInvite),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "groupId": groupId,
          "userAddress": authCore.publicAddress.toLowerCase(),
          "signature": signature
        })
      );
      return res.statusCode == 200 ? "SUCCESS" : _extractErrorMessage(res.body, res.statusCode);
    } catch (e) {
      return "Error de red";
    }
  }

  // --- PAGOS MULTI-FIRMA (MULTI-SIG) ---

  Future<List<dynamic>> getGroupPayments(String groupId) async {
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.getGroupPayments.replaceAll("{groupId}", groupId)), 
        headers: authCore.authHeaders
      );
      return res.statusCode == 200 ? jsonDecode(res.body) : [];
    } catch (e) {
      return [];
    }
  }

  Future<String> requestGroupPayment(String groupId, double total, String desc, String destinationAddress, {bool useGroupFunds = false, String? sharedDebtId}) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.createGroupPayment), 
        headers: authCore.authHeaders, 
        body: jsonEncode({
          "groupId": groupId, 
          "requesterAddress": authCore.publicAddress.toLowerCase(), 
          "destinationAddress": destinationAddress, 
          "totalAmount": total, 
          "description": desc,
          "useGroupFunds": useGroupFunds,
          "sharedDebtId": sharedDebtId
        })
      );
      return res.statusCode == 200 ? "SUCCESS" : _extractErrorMessage(res.body, res.statusCode);
    } catch (e) {
      return "ERROR";
    }
  }

  Future<String> approveMultisigPayment(String requestId) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.approveMultisigTransaction.replaceAll("{requestId}", requestId)),
        headers: authCore.authHeaders,
        body: jsonEncode({"userAddress": authCore.publicAddress.toLowerCase()})
      );
      return res.statusCode == 200 ? "SUCCESS" : _extractErrorMessage(res.body, res.statusCode);
    } catch (e) {
      return "Error de conexión";
    }
  }

  // --- CONSULTAS DE BÓVEDA ---

  Future<double> getAnyWalletBalance(String walletAddress) async {
    try {
      final response = await http.get(
       Uri.parse(ApiConfig.getGroupBalance.replaceAll("{walletAddress}", walletAddress.toLowerCase())),
        headers: authCore.authHeaders,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return double.parse(data['effectiveBalance'].toString());
      }
      return 0.0;
    } catch (e) {
      return 0.0; 
    }
  }

  Future<List<dynamic>> getGroupTransactionsHistory(String groupId) async {
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.getGroupTransactionsHistory.replaceAll("{groupId}", groupId)),
        headers: authCore.authHeaders,
      );
      return res.statusCode == 200 ? jsonDecode(res.body) : [];
    } catch (e) {
      return [];
    }
  }

  Future<String> updateGroupName(String groupId, String newName) async {
    try {
      final res = await http.put(
        Uri.parse(ApiConfig.updateGroup.replaceAll("{id}", groupId)),
        headers: authCore.authHeaders,
        body: jsonEncode({"name": newName})
      );
      return res.statusCode == 200 ? "SUCCESS" : _extractErrorMessage(res.body, res.statusCode);
    } catch (e) { return "ERROR"; }
  }

  Future<String> deleteGroup(String groupId) async {
    try {
      final res = await http.delete(
        Uri.parse(ApiConfig.deleteGroup.replaceAll("{id}", groupId)),
        headers: authCore.authHeaders
      );
      return res.statusCode == 200 ? "SUCCESS" : "ERROR";
    } catch (e) { return "ERROR"; }
  }

  Future<String> rejectGroupInvite(String groupId) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.rejectGroupInvite),
        headers: authCore.authHeaders,
        body: jsonEncode({"groupId": groupId, "userAddress": authCore.publicAddress.toLowerCase()})
      );
      return res.statusCode == 200 ? "SUCCESS" : "ERROR";
    } catch (e) { return "ERROR"; }
  }

  // Future<String> addGroupMember(String groupId, String memberAddress, String memberAlias) async {
  //   try {
  //     final res = await http.post(
  //       Uri.parse(ApiConfig.addGroupMember.replaceAll("{id}", groupId)),
  //       headers: authCore.authHeaders,
  //       body: jsonEncode({"address": memberAddress, "alias": memberAlias})
  //     );
  //     return res.statusCode == 200 ? "SUCCESS" : _extractErrorMessage(res.body, res.statusCode);
  //   } catch (e) { return "ERROR"; }
  // }

Future<String> addGroupMember(String groupId, String memberAddress, String memberAlias) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.addGroupMember.replaceAll("{id}", groupId)),
        headers: authCore.authHeaders,
        // 🔥 FIX DEFINITIVO: Enviamos las llaves exactas que busca GroupController.java
        body: jsonEncode({
          "userAddress": authCore.publicAddress.toLowerCase(), // El creador/admin
          "newMember": {                                       // El nuevo miembro
            "walletAddress": memberAddress,
            "alias": memberAlias
          }
        })
      );
      return res.statusCode == 200 ? "SUCCESS" : _extractErrorMessage(res.body, res.statusCode);
    } catch (e) { 
      return "ERROR"; 
    }
  }

  Future<String> confirmGroupPaymentInBackend(String requestId, String txHash) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.confirmGroupPayment.replaceAll("{requestId}", requestId)),
        headers: authCore.authHeaders,
        body: jsonEncode({"txHash": txHash})
      );
      return res.statusCode == 200 ? "SUCCESS" : "ERROR";
    } catch (e) { return "ERROR"; }
  }

  Future<String> proposeGroupThreshold(String groupId, double newThreshold) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.proposeGroupThreshold.replaceAll("{groupId}", groupId)),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "newThreshold": newThreshold, 
          "proposerAddress": authCore.publicAddress.toLowerCase()
        })
      );
      return res.statusCode == 200 ? "SUCCESS" : _extractErrorMessage(res.body, res.statusCode);
    } catch (e) { return "ERROR"; }
  }

  Future<String> removeGroupMember(String groupId, String memberAddress) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.removeGroupMember.replaceAll("{id}", groupId)),
        headers: authCore.authHeaders,
        body: jsonEncode({"address": memberAddress})
      );
      return res.statusCode == 200 ? "SUCCESS" : _extractErrorMessage(res.body, res.statusCode);
    } catch (e) { 
      return "ERROR"; 
    }
  }

  Future<String> proposeGroupDeFiAction(String groupId, String action, {double? amount}) async {
    try {
      // 🔥 Usamos exactamente el endpoint que YA TIENES en api_config.dart
      String url = ApiConfig.stakeGroupTokens
          .replaceAll("{groupId}", groupId)
          .replaceAll("{actionType}", action);

      final res = await http.post(
        Uri.parse(url),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "proposerAddress": authCore.publicAddress.toLowerCase(),
          if (amount != null) "amount": amount, // Enviamos el monto si es necesario
        })
      );
      return res.statusCode == 200 ? "SUCCESS" : _extractErrorMessage(res.body, res.statusCode);
    } catch (e) { 
      return "ERROR"; 
    }
  }

  // --- UI & MODALS DESACOPLADOS ---

 Future<void> openContactSearchModal(BuildContext context, String groupId, VoidCallback onRefresh, Function(bool) setLoading) async {
    setLoading(true);
    try {
      String endpoint = ApiConfig.getContacts.replaceAll("{address}", authCore.publicAddress.toLowerCase());
      final res = await http.get(Uri.parse(endpoint), headers: authCore.authHeaders);

      if (res.statusCode == 200) {
        List<dynamic> misContactos = jsonDecode(res.body);
        
        if (!context.mounted) {
          setLoading(false);
          return;
        }
        
        setLoading(false); 
        
        showModalBottomSheet(
          context: context,
          backgroundColor: Theme.of(context).cardColor,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (ctx) => Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text("Selecciona a quién invitar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: misContactos.length,
                  itemBuilder: (ctx, i) {
                    var c = misContactos[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text("@${c['alias']}"),
                      subtitle: Text(c['contactAddress'].toString().substring(0, 10) + "..."),
                      trailing: ElevatedButton(
                        child: const Text("Invitar"),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          setLoading(true);
                          
                          String r = await addGroupMember(groupId, c['contactAddress'], c['alias']);
                          
                          if (r == "SUCCESS") {
                            UIHelper.showCustomSnackbar("Invitación enviada exitosamente");
                            onRefresh(); // Dispara la recarga de datos en la pantalla
                          } else {
                            UIHelper.showCustomSnackbar(r, isError: true);
                          }
                          setLoading(false);
                        },
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        );
        return;
      }
    } catch (e) {
      UIHelper.showCustomSnackbar("Error al contactar con el servidor", isError: true);
    }
    setLoading(false);
  }

  // ==========================================================
  // 🔥 CHAT GRUPAL Y TESORERO IA
  // ==========================================================

 Future<List<dynamic>> getGroupChatHistory(String groupId) async {
    try {
      // 🔥 FIX: Forzamos la ruta absoluta
      final url = "${ApiConfig.baseUrl}/groups/$groupId/chat";
      final res = await http.get(Uri.parse(url), headers: authCore.authHeaders);
      return res.statusCode == 200 ? jsonDecode(res.body) : [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> sendGroupMessage({
    required String groupId,
    required String senderWallet,
    required String senderAlias,
    required String content,
    required String messageType,
  }) async {
    try {
      // 🔥 FIX: Forzamos la ruta absoluta
      final url = "${ApiConfig.baseUrl}/groups/$groupId/chat";
      debugPrint("📡 Enviando mensaje a: $url");
      
      final Map<String, String> headers = {
        ...authCore.authHeaders,
        "Content-Type": "application/json"
      };

      final res = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          "senderWallet": senderWallet,
          "senderAlias": senderAlias,
          "content": content,
          "messageType": messageType
        })
      );
      
      if (res.statusCode == 200) {
        return true;
      } else {
        debugPrint("❌ Error del servidor al enviar: ${res.statusCode} - ${res.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Excepción al enviar mensaje: $e");
      return false;
    }
  }
}