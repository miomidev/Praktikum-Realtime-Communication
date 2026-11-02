import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_http_sse/client/sse_client.dart';
import 'package:flutter_http_sse/model/sse_request.dart';
import 'package:flutter_http_sse/model/sse_response.dart';
import '../config/api_config.dart';
import '../models/server_data.dart';
import '../widgets/log_console.dart';
import '../widgets/status_badge.dart';

class SseScreen extends StatefulWidget {
  const SseScreen({super.key});

  @override
  State<SseScreen> createState() => _SseScreenState();
}

class _SseScreenState extends State<SseScreen> {
  final SSEClient _sseClient = SSEClient();
  StreamSubscription<SSEResponse>? _subscription;
  ConnectionStatus _status = ConnectionStatus.disconnected;

  ServerData? _currentData;
  int _eventCount = 0;
  final List<String> _logs = [];
  final String _connectionId = 'sse_praktikum_conn';

  void _addLog(String message) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    if (mounted) {
      setState(() {
        _logs.add('[$time] $message');
      });
    }
  }

  void _connectSse() {
    _disconnectSse();

    setState(() {
      _status = ConnectionStatus.connecting;
    });
    _addLog('Menghubungkan ke SSE: ${ApiConfig.sseEndpoint}...');

    try {
      final request = SSERequest(
        url: ApiConfig.sseEndpoint,
        onData: (response) {
          _handleSseResponse(response);
        },
        onError: (error) {
          _addLog('SSE Error: $error');
          if (mounted) {
            setState(() {
              _status = ConnectionStatus.error;
            });
          }
        },
        onDone: () {
          _addLog('SSE Koneksi ditutup oleh server');
          if (mounted) {
            setState(() {
              _status = ConnectionStatus.disconnected;
            });
          }
        },
        retry: true,
      );

      final stream = _sseClient.connect(_connectionId, request);

      _subscription = stream.listen(
        (response) {
          _handleSseResponse(response);
        },
        onError: (err) {
          _addLog('Stream Error: $err');
          if (mounted) {
            setState(() => _status = ConnectionStatus.error);
          }
        },
        onDone: () {
          _addLog('Stream selesai');
          if (mounted) {
            setState(() => _status = ConnectionStatus.disconnected);
          }
        },
      );

      setState(() {
        _status = ConnectionStatus.connected;
      });
    } catch (e) {
      _addLog('Gagal inisialisasi SSE: $e');
      setState(() {
        _status = ConnectionStatus.error;
      });
    }
  }

  void _handleSseResponse(SSEResponse response) {
    if (!mounted) return;

    setState(() {
      _status = ConnectionStatus.connected;
      _eventCount++;

      // Jika data berupa JSON Map
      if (response.data is Map<String, dynamic>) {
        _currentData =
            ServerData.fromJson(response.data as Map<String, dynamic>);
      } else if (response.data is Map) {
        _currentData = ServerData.fromJson(
            Map<String, dynamic>.from(response.data as Map));
      }
    });

    final eventType =
        response.event.isNotEmpty ? '[${response.event}] ' : '';
    _addLog('SSE Event #$_eventCount: $eventType${response.data ?? response.rawResponse}');
  }

  void _disconnectSse() {
    _subscription?.cancel();
    _subscription = null;
    _sseClient.close(connectionId: _connectionId);

    if (_status != ConnectionStatus.disconnected) {
      setState(() {
        _status = ConnectionStatus.disconnected;
      });
      _addLog('Koneksi SSE diputus pengguna');
    }
  }

  @override
  void dispose() {
    _disconnectSse();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:
                                const Icon(Icons.stream, color: Colors.teal),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Praktikum 3 — SSE',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Server-Sent Events (Satu Arah: Server ➔ Client)',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      StatusBadge(status: _status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'SSE Stream URL:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  SelectableText(
                    ApiConfig.sseEndpoint,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.teal.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _status == ConnectionStatus.connected ||
                              _status == ConnectionStatus.connecting
                          ? null
                          : _connectSse,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      icon: const Icon(Icons.link),
                      label: const Text('Buka Koneksi SSE'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _status == ConnectionStatus.connected ||
                              _status == ConnectionStatus.connecting
                          ? _disconnectSse
                          : null,
                      icon: const Icon(Icons.link_off),
                      label: const Text('Putuskan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Live Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Counter Otomatis',
                  _currentData != null ? '${_currentData!.counter}' : '-',
                  Icons.numbers,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Sensor Value',
                  _currentData != null ? '${_currentData!.value}' : '-',
                  Icons.sensors,
                  Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Total Event Masuk',
                  '$_eventCount',
                  Icons.inbox,
                  Colors.indigo,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Protokol',
                  'HTTP Streaming',
                  Icons.cloud_sync,
                  Colors.deepPurple,
                ),
              ),
            ],
          ),
          if (_currentData != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pembaruan Terakhir: ${_currentData!.timestamp}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Log
          LogConsole(
            logs: _logs,
            onClear: () => setState(() => _logs.clear()),
            title: 'Aliran Event SSE Real-time',
          ),
          const SizedBox(height: 16),

          // Analysis Question
          _buildAnalysisCard(),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard() {
    return Card(
      elevation: 0,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade200),
      ),
      child: ExpansionTile(
        leading: Icon(Icons.psychology, color: Colors.amber.shade900),
        title: Text(
          'Pertanyaan & Analisis Praktikum 3',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.amber.shade900,
          ),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          const Text(
            '❓ Pertanyaan:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mengapa SSE menarik untuk dashboard monitoring, tetapi bukan pilihan utama untuk komunikasi audio/video dua arah?',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const Divider(height: 20),
          const Text(
            '💡 Jawaban & Analisis:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 6),
          const Text(
            '1. Mengapa SSE Sempurna untuk Dashboard Monitoring:\n'
            '   • Arsitektur Sederhana: Berjalan di atas HTTP standar (port 80/443), tanpa butuh konfigurasi port khusus atau proxy tambahan.\n'
            '   • Efisien Satu Arah (Server-to-Client): Dashboard hanya membutuhkan penerimaan metrik/log secara pasif. SSE menjaga 1 koneksi HTTP tetap terbuka dan server dapat mem-push data kapan pun tersedia.\n'
            '   • Auto-Reconnection Bawaan: Spesifikasi SSE mendukung reconnect otomatis jika koneksi terputus dan dapat melanjutkan event dengan ID terakhir.\n\n'
            '2. Mengapa SSE BUKAN Pilihan untuk Audio/Video Dua Arah:\n'
            '   • Unidirectional Only: SSE hanya mengalir dari server ke client. Komunikasi audio/video memerlukan pengiriman media dua arah secara simultaneous.\n'
            '   • Berbasis Teks & TCP: SSE mengirim payload teks (UTF-8) dengan format "data: ...\\n\\n". Mengirim ribuan frame binary video/audio terkompresi lewat teks akan menimbulkan overhead besar.\n'
            '   • Head-of-Line Blocking pada TCP: TCP menjamin paket urut dan retransmisi paket hilang. Pada video/audio real-time, jika ada paket drop, kita tidak ingin seluruh video terhenti (freeze). Dibutuhkan protokol berbasis UDP seperti RTP/WebRTC.',
            style: TextStyle(fontSize: 12.5, height: 1.4),
          ),
        ],
      ),
    );
  }
}
