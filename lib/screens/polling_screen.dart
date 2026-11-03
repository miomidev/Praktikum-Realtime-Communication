import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/server_data.dart';
import '../widgets/log_console.dart';
import '../widgets/status_badge.dart';

class PollingScreen extends StatefulWidget {
  const PollingScreen({super.key});

  @override
  State<PollingScreen> createState() => _PollingScreenState();
}

class _PollingScreenState extends State<PollingScreen> {
  Timer? _pollingTimer;
  bool _isPolling = false;
  int _intervalSeconds = 2;
  int _totalRequests = 0;
  int _latestLatencyMs = 0;
  ServerData? _currentData;
  final List<String> _logs = [];

  void _addLog(String message) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    setState(() {
      _logs.add('[$time] $message');
    });
  }

  void _startPolling() {
    _stopPolling();
    setState(() {
      _isPolling = true;
    });
    _addLog('Polling dimulai (interval: $_intervalSeconds detik)');

    // Langsung lakukan poll pertama
    _pollOnce();

    _pollingTimer = Timer.periodic(
      Duration(seconds: _intervalSeconds),
      (_) => _pollOnce(),
    );
  }

  Future<void> _pollOnce() async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http.get(Uri.parse(ApiConfig.dataEndpoint));
      stopwatch.stop();

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final data = ServerData.fromJson(json);

        if (mounted) {
          setState(() {
            _currentData = data;
            _totalRequests++;
            _latestLatencyMs = stopwatch.elapsedMilliseconds;
          });
        }

        _addLog(
            'Poll #$_totalRequests (latensi ${_latestLatencyMs}ms): counter=${data.counter}, value=${data.value}');
      } else {
        _addLog('Poll error: Status ${response.statusCode}');
      }
    } catch (e) {
      _addLog('Poll network error: $e');
    }
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    if (_isPolling) {
      setState(() {
        _isPolling = false;
      });
      _addLog('Polling dihentikan');
    }
  }

  @override
  void dispose() {
    _stopPolling();
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.timer, color: Colors.orange),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Praktikum 2 — Polling',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Periodic Request vs Long Polling',
                              style:
                                  TextStyle(fontSize: 11.5, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(
                        status: _isPolling
                            ? ConnectionStatus.connected
                            : ConnectionStatus.disconnected,
                        customLabel: _isPolling ? 'Aktif' : 'Nonaktif',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Control & Interval Selection
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pengaturan Polling',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Interval: ',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 1, label: Text('1 dtk')),
                            ButtonSegment(value: 2, label: Text('2 dtk')),
                            ButtonSegment(value: 5, label: Text('5 dtk')),
                          ],
                          selected: {_intervalSeconds},
                          onSelectionChanged: _isPolling
                              ? null
                              : (newSelection) {
                                  setState(() {
                                    _intervalSeconds = newSelection.first;
                                  });
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isPolling ? null : _startPolling,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Mulai Polling'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isPolling ? _stopPolling : null,
                          icon: const Icon(Icons.stop),
                          label: const Text('Hentikan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Realtime Metrics
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Counter Server',
                  _currentData != null ? '${_currentData!.counter}' : '-',
                  Icons.numbers,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Nilai Sensor',
                  _currentData != null ? '${_currentData!.value}' : '-',
                  Icons.speed,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Request',
                  '$_totalRequests',
                  Icons.sync_alt,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Latensi Terakhir',
                  '${_latestLatencyMs}ms',
                  Icons.network_ping,
                  Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Log Activity
          LogConsole(
            logs: _logs,
            onClear: () => setState(() => _logs.clear()),
            title: 'Log Polling Berkala',
          ),
          const SizedBox(height: 16),

          // Long Polling Comparison Table
          _buildComparisonCard(),
          const SizedBox(height: 16),

          // Analysis Question
          _buildAnalysisCard(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500),
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
      ),
    );
  }

  Widget _buildComparisonCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.compare_arrows, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Perbandingan Polling vs Long Polling',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300, width: 1),
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(1.4),
                2: FlexColumnWidth(1.4),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Aspek',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Short Polling',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Long Polling',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Pola Request',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                          'Berulang sesuai interval waktu tanpa peduli ada data baru/tidak',
                          style: TextStyle(fontSize: 11)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                          'Client request, server menahan sampai data baru tiba / timeout',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Latensi',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                          'Tergantung interval (bisa delay hingga durasi interval)',
                          style: TextStyle(fontSize: 11)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                          'Sangat rendah saat ada data baru (langsung dikirim balik)',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Beban Server',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                          'Banyak request kosong (overhead HTTP header berulang)',
                          style: TextStyle(fontSize: 11)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                          'Banyak koneksi HTTP yang menggantung (held connection)',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
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
          'Pertanyaan & Analisis Praktikum 2',
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
            'Apa yang terjadi jika interval polling diturunkan dari lima detik menjadi 200 milidetik? Pertimbangkan latensi, penggunaan jaringan, dan beban server.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const Divider(height: 20),
          const Text(
            '💡 Jawaban & Analisis Mendalam:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 6),
          const Text(
            '1. Latensi:\n'
            '   • Latensi pembaruan data berkurang signifikan menjadi maksimal 200ms.\n'
            '   • Pengguna merasakan data sangat responsif dan mendekati real-time.\n\n'
            '2. Penggunaan Jaringan (Network Usage):\n'
            '   • Frekuensi request melonjak 25x lipat (dari 12 req/menit menjadi 300 req/menit per client).\n'
            '   • Sebagian besar request menghasilkan data yang sama (redundant).\n'
            '   • Konsumsi bandwidth boros karena overhead TCP handshake dan HTTP headers (biasanya ratusan byte) dikirim berulang 5 kali setiap detik.\n\n'
            '3. Beban Server & Perangkat:\n'
            '   • Server: CPU dan memori server akan mengalami lonjakan tajam. Jika ada 1.000 pengguna aktif, server harus melayani 5.000 request per detik (RPS).\n'
            '   • Mobile Client: Menyebabkan battery drain cepat pada smartphone dan membuat radio seluler terus berada di state aktif berdaya tinggi (DCH state).',
            style: TextStyle(fontSize: 12.5, height: 1.4),
          ),
        ],
      ),
    );
  }
}

