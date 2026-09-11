import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../wallet_and_tx/services/transaction_service.dart';
import '../../settings_and_profile/services/user_service.dart';
import '../../../core/services/smart_avatar.dart';
import '../../../core/helpers/ui_helper.dart';

class AdminTransactionAuditScreen extends StatefulWidget {
  const AdminTransactionAuditScreen({super.key});

  @override
  State<AdminTransactionAuditScreen> createState() => _AdminTransactionAuditScreenState();
}

class _AdminTransactionAuditScreenState extends State<AdminTransactionAuditScreen> {
  final TextEditingController _hashController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _txData;
  Map<String, dynamic>? _senderProfile;
  Map<String, dynamic>? _receiverProfile;

  Future<void> _auditTransaction() async {
    String hash = _hashController.text.trim();
    if (hash.isEmpty) {
      UIHelper.showCustomSnackbar("Ingresa un Hash válido", isError: true);
      return;
    }
    if (!hash.startsWith("0x")) hash = "0x$hash";

    setState(() {
      _isLoading = true;
      _txData = null;
      _senderProfile = null;
      _receiverProfile = null;
    });
    FocusScope.of(context).unfocus();

    try {
      final txService = Provider.of<TransactionService>(context, listen: false);
      final userService = Provider.of<UserService>(context, listen: false);

      final tx = await txService.getTransactionByHash(hash);
      if (tx != null) {
        String sender = tx['senderAddress'] ?? '';
        String receiver = tx['receiverAddress'] ?? '';

        Map<String, dynamic>? senderRes;
        Map<String, dynamic>? receiverRes;

        if (sender.isNotEmpty && sender.startsWith('0x')) {
          senderRes = await userService.getUserByWallet(sender);
        }
        if (receiver.isNotEmpty && receiver.startsWith('0x')) {
          receiverRes = await userService.getUserByWallet(receiver);
        }

        if (mounted) {
          setState(() {
            _txData = tx;
            _senderProfile = senderRes;
            _receiverProfile = receiverRes;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          UIHelper.showCustomSnackbar("Transacción no encontrada en la red", isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UIHelper.showCustomSnackbar("Error al auditar la transacción", isError: true);
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
        title: const Text("Auditoría de Transacción & Perfiles", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Inspección Forense de Hash", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface)),
            const SizedBox(height: 8),
            Text("Introduce el Hash criptográfico para verificar la transferencia y consultar los perfiles asociados de los usuarios.", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13)),
            const SizedBox(height: 24),

            TextField(
              controller: _hashController,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                hintText: "Hash de Transacción (0x...)",
                hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                prefixIcon: Icon(Icons.numbers_rounded, color: colorScheme.primary),
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary)),
              ),
              onSubmitted: (_) => _auditTransaction(),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _auditTransaction,
                icon: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.search_rounded),
                label: const Text("Inspeccionar Transacción & Usuarios", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 32),

            if (_txData != null) ...[
              _buildTransactionCard(theme, colorScheme, onSurface),
              const SizedBox(height: 24),
              Text("Perfiles Involucrados", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface)),
              const SizedBox(height: 16),
              _buildUserProfileCard("Remitente (Sender)", _txData!['senderAddress'], _senderProfile, theme, colorScheme, onSurface),
              const SizedBox(height: 12),
              _buildUserProfileCard("Destinatario (Receiver)", _txData!['receiverAddress'], _receiverProfile, theme, colorScheme, onSurface),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(ThemeData theme, ColorScheme colorScheme, Color onSurface) {
    double amount = double.tryParse(_txData!['amount']?.toString() ?? '0') ?? 0.0;
    String status = _txData!['status'] ?? 'UNKNOWN';
    String date = _txData!['timestamp']?.toString().substring(0, 16).replaceAll("T", " ") ?? "";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Resultado del Blockchain", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: (status == 'COMPLETED' ? Colors.green : colorScheme.error).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: TextStyle(color: status == 'COMPLETED' ? Colors.green : colorScheme.error, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text("${amount.toStringAsFixed(2)} TTC", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: onSurface)),
          const SizedBox(height: 8),
          Text("Fecha: $date", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildUserProfileCard(String roleTitle, String address, Map<String, dynamic>? profile, ThemeData theme, ColorScheme colorScheme, Color onSurface) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: onSurface.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(roleTitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.secondary)),
          const SizedBox(height: 12),
          Row(
            children: [
              SmartAvatar(address: address, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile != null ? "@${profile['alias'] ?? 'Sin alias'}" : "Perfil no localizado", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: onSurface)),
                    const SizedBox(height: 2),
                    Text(profile != null ? (profile['email'] ?? 'Sin correo') : address, style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ],
          ),
          if (profile != null) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Colors.white10)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Tipo: ${profile['accountType'] ?? 'PERSONAL'}", style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.7))),
                Text("Plan: ${profile['membershipTier'] ?? 'FREE'}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.primary)),
              ],
            )
          ]
        ],
      ),
    );
  }
}