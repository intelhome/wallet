import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/helpers/ui_helper.dart';

class ViewBusinessResourceModal {
  static void show(BuildContext context, dynamic resource) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        final onSurface = colorScheme.onSurface;

        bool isLink = resource['type'] == 'LINK';
        String urlOrHash = resource['urlOrHash'] ?? '';

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: (isLink ? Colors.blue : Colors.deepPurple).withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(isLink ? Icons.link_rounded : Icons.description_rounded, size: 48, color: isLink ? Colors.blue : Colors.deepPurple),
              ),
              const SizedBox(height: 16),
              Text(resource['title'] ?? 'Recurso', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface)),
              const SizedBox(height: 8),
              Text(isLink ? "Enlace Externo" : "Documento Notarizado", textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.6))),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: onSurface.withOpacity(0.05))),
                child: Text(urlOrHash, style: TextStyle(color: colorScheme.primary, fontFamily: 'monospace'), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                 onPressed: () async {
                    if (isLink && urlOrHash.isNotEmpty) {
                      String finalUrl = urlOrHash.trim();
                      if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
                        finalUrl = 'https://$finalUrl';
                      }
                      
                      try {
                        final uri = Uri.parse(finalUrl);
                        await launchUrl(uri, mode: LaunchMode.platformDefault);
                        Navigator.pop(ctx);
                      } catch (e) {
                        UIHelper.showCustomSnackbar("Error al abrir el recurso", isError: true);
                      }
                    }
                  },
                  icon: const Icon(Icons.open_in_browser_rounded),
                  label: const Text("Abrir Recurso", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }
    );
  }
}