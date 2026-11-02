import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LogConsole extends StatelessWidget {
  final List<String> logs;
  final VoidCallback onClear;
  final String title;

  const LogConsole({
    super.key,
    required this.logs,
    required this.onClear,
    this.title = 'Aktivitas / Log',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '${logs.length} entri',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: logs.join('\n')));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Log disalin ke clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.copy, size: 15, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: onClear,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.delete_outline, size: 15, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 160,
            padding: const EdgeInsets.all(10),
            child: logs.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada log aktivitas...',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final item = logs[logs.length - 1 - index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            color: Colors.lightGreenAccent,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

