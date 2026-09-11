import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../wallet_and_tx/services/transaction_service.dart';
import '../../settings_and_profile/services/user_service.dart';
import '../../../core/services/smart_avatar.dart';
import '../../../core/helpers/ui_helper.dart';

class AdminUserComplianceDeepDiveScreen extends StatefulWidget {
  const AdminUserComplianceDeepDiveScreen({super.key});

  @override
  State<AdminUserComplianceDeepDiveScreen> createState() => _AdminUserComplianceDeepDiveScreenState();
}

class _AdminUserComplianceDeepDiveScreenState extends State<AdminUserComplianceDeepDiveScreen> {
  final TextEditingController _queryController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _targetUser;
  List<dynamic> _userTransactions = [];

  Future<void> _inspectUserByHashOrWallet() async {
    String query = _queryController.text.trim();
    if (query.isEmpty) {
      UIHelper.showCustomSnackbar("Ingresa una wallet o hash", isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _targetUser = null;
      _userTransactions = [];
    });
    FocusScope.of(context).unfocus();

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final txService = Provider.of<TransactionService>(context, listen: false);

      String targetWallet = query;
      if (query.startsWith("0x") && query.length > 42) {
        final tx = await txService.getTransactionByHash(query);
        if (tx != null && tx['senderAddress'] != null) {
          targetWallet = tx['senderAddress'];
        }
      }

      final user = await userService.getUserByWallet(targetWallet);
      final history = await txService.getTransactionHistory();
      final userTxs = history.where((t) {
        String s = (t['senderAddress'] ?? '').toString().toLowerCase();
        String r = (t['receiverAddress'] ?? '').toString().toLowerCase();
        String w = targetWallet.toLowerCase();
        return s == w || r == w;
      }).toList();

      if (mounted) {
        setState(() {
          _targetUser = user;
          _userTransactions = userTxs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UIHelper.showCustomSnackbar("No se pudo completar la auditoría", isError: true);
      }
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
        title: const Text("Auditoría de Perfil & Actividad", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Inspección de Usuario por Operación", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface)),
            const SizedBox(height: 8),
            Text("Busca por dirección de billetera o pega un hash de transacción para aislar el perfil del usuario y su historial asociado.", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13)),
            const SizedBox(height: 24),

            TextField(
              controller: _queryController,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                hintText: "Wallet (0x...) o Hash de Tx",
                hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                prefixIcon: Icon(Icons.person_search_rounded, color: colorScheme.secondary),
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.secondary)),
              ),
              onSubmitted: (_) => _inspectUserByHashOrWallet(),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: colorScheme.onSecondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _inspectUserByHashOrWallet,
                icon: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.analytics_rounded),
                label: const Text("Analizar Perfil & Actividad", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 32),

            if (_targetUser != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.secondary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    SmartAvatar(address: _targetUser!['walletAddress'] ?? '', size: 64),
                    const SizedBox(height: 16),
                    Text("@${_targetUser!['alias'] ?? 'Usuario'}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface)),
                    const SizedBox(height: 4),
                    Text(_targetUser!['email'] ?? 'Sin correo', style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Chip(label: Text("Tipo: ${_targetUser!['accountType'] ?? 'PERSONAL'}")),
                        const SizedBox(width: 8),
                        Chip(label: Text("Plan: ${_targetUser!['membershipTier'] ?? 'FREE'}")),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text("Transacciones Relacionadas (${_userTransactions.length})", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface)),
              const SizedBox(height: 12),
              ..._userTransactions.map((tx) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: theme.cardColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: onSurface.withOpacity(0.05))),
                child: ListTile(
                  title: Text("${tx['amount']} TTC", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(tx['timestamp']?.toString().substring(0, 16).replaceAll("T", " ") ?? "", style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.5))),
                  trailing: Text(tx['status'] ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tx['status'] == 'COMPLETED' ? Colors.green : Colors.orange)),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}