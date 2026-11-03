import 'package:flutter/material.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class StatusBadge extends StatelessWidget {
  final ConnectionStatus status;
  final String? customLabel;

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case ConnectionStatus.connected:
        color = Colors.green;
        icon = Icons.check_circle;
        label = customLabel ?? 'Terhubung';
        break;
      case ConnectionStatus.connecting:
        color = Colors.orange;
        icon = Icons.sync;
        label = customLabel ?? 'Menghubungkan...';
        break;
      case ConnectionStatus.error:
        color = Colors.red;
        icon = Icons.error;
        label = customLabel ?? 'Error';
        break;
      case ConnectionStatus.disconnected:
        color = Colors.grey;
        icon = Icons.cloud_off;
        label = customLabel ?? 'Terputus';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
