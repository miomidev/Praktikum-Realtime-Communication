import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/server_data.dart';
import '../widgets/log_console.dart';

class RestScreen extends StatefulWidget {
  const RestScreen({super.key});

  @override
  State<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends State<RestScreen> {
  ServerData? _serverData;
  bool _isLoadingGet = false;
  bool _isLoadingPost = false;
  String? _postResponse;
  final TextEditingController _messageController =
      TextEditingController(text: 'Halo dari Mahasiswa Flutter!');
  final List<String> _logs = [];

  void _addLog(String message) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    setState(() {
      _logs.add('[$time] $message');
    });
  }

  Future<void> _fetchData() async {
    setState(() => _isLoadingGet = true);
    final stopwatch = Stopwatch()..start();
    _addLog('GET ${ApiConfig.dataEndpoint}...');

    try {
      final response = await http.get(Uri.parse(ApiConfig.dataEndpoint));
      stopwatch.stop();

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        setState(() {
          _serverData = ServerData.fromJson(json);
        });
        _addLog(
            'GET 200 OK (${stopwatch.elapsedMilliseconds}ms): counter=${_serverData!.counter}, value=${_serverData!.value}');
      } else {
        _addLog('GET Gagal: Status ${response.statusCode}');
      }
    } catch (e) {
      _addLog('GET Error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingGet = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoadingPost = true);
    final stopwatch = Stopwatch()..start();
    _addLog('POST ${ApiConfig.messageEndpoint} (message: "$text")...');

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.messageEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': text}),
      );
      stopwatch.stop();

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        setState(() {
          _postResponse = jsonEncode(json);
        });
        _addLog(
            'POST 200 OK (${stopwatch.elapsedMilliseconds}ms): ${response.body}');
      } else {
        _addLog('POST Gagal: Status ${response.statusCode}');
      }
    } catch (e) {
      _addLog('POST Error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPost = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
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
            elevation: 2,
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
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.http, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Praktikum 1 — REST API',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Model Komunikasi: Request-Response (Stateless)',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Server Endpoint:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  SelectableText(
                    ApiConfig.baseUrl,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.blue.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section 1: GET /api/data
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '1. Pengambilan Data (GET)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _isLoadingGet ? null : _fetchData,
                        icon: _isLoadingGet
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.download, size: 16),
                        label: const Text('Ambil Data'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_serverData == null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Tekan tombol "Ambil Data" untuk meminta data dari server.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            'Counter',
                            '${_serverData!.counter}',
                            Icons.numbers,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricTile(
                            'Value (Acak)',
                            '${_serverData!.value}',
                            Icons.speed,
                            Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                  if (_serverData != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Server Timestamp: ${_serverData!.timestamp}',
                              style: const TextStyle(
                                  fontSize: 11, fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section 2: POST /api/message
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '2. Pengiriman Pesan (POST)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: 'Pesan ke Server',
                      hintText: 'Tulis pesan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      suffixIcon: IconButton(
                        icon: _isLoadingPost
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        onPressed: _isLoadingPost ? null : _sendMessage,
                      ),
                    ),
                  ),
                  if (_postResponse != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Respon Server (POST):',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.green),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            _postResponse!,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Live Activity Log
          LogConsole(
            logs: _logs,
            onClear: () => setState(() => _logs.clear()),
            title: 'Log Request HTTP',
          ),
          const SizedBox(height: 16),

          // Observasi & Jawaban Analisis
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
                    fontSize: 12, color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
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
          'Pertanyaan & Analisis Praktikum 1',
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
            'Jika nilai pada server berubah setiap dua detik, apakah tampilan Flutter otomatis berubah jika hanya menggunakan REST API? Mengapa?',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const Divider(height: 20),
          const Text(
            '💡 Jawaban & Analisis:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 6),
          const Text(
            'TIDAK, tampilan Flutter tidak akan berubah secara otomatis.\n\n'
            'Alasan:\n'
            '1. Model Request-Response: REST API bekerja di atas protokol HTTP yang bersifat request-driven dan stateless. Server hanya dapat merespons jika ada client yang berinisiatif mengirimkan request.\n'
            '2. Koneksi Ditutup/Idle: Setelah server membalas dengan status 200 OK dan mengirimkan JSON, siklus HTTP transaksi selesai. Server tidak memiliki mekanisme built-in untuk melakukan "server push" ke client.\n'
            '3. Client Tidak Sadar Perubahan: Meskipun data di server bertambah setiap 2 detik via timer internal server, Flutter tidak akan mengetahuinya sampai tombol "Ambil Data" ditekan kembali.',
            style: TextStyle(fontSize: 12.5, height: 1.4),
          ),
        ],
      ),
    );
  }
}
