import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';
import '../widgets/log_console.dart';
import '../widgets/status_badge.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final int? latencyMs;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.latencyMs,
  });
}

class WebSocketScreen extends StatefulWidget {
  const WebSocketScreen({super.key});

  @override
  State<WebSocketScreen> createState() => _WebSocketScreenState();
}

class _WebSocketScreenState extends State<WebSocketScreen> {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  ConnectionStatus _status = ConnectionStatus.disconnected;

  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  Stopwatch? _pingStopwatch;

  void _addLog(String message) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    if (mounted) {
      setState(() {
        _logs.add('[$time] $message');
      });
    }
  }

  void _connectWebSocket() {
    _disconnectWebSocket();

    setState(() {
      _status = ConnectionStatus.connecting;
    });
    _addLog('Menghubungkan ke ${ApiConfig.wsUrl}...');

    try {
      _channel = WebSocketChannel.connect(Uri.parse(ApiConfig.wsUrl));

      _subscription = _channel!.stream.listen(
        (data) {
          final int? rtt = _pingStopwatch?.elapsedMilliseconds;
          _pingStopwatch?.stop();
          _pingStopwatch = null;

          _handleIncomingMessage(data.toString(), rtt);
        },
        onError: (error) {
          _addLog('WebSocket error: $error');
          if (mounted) {
            setState(() => _status = ConnectionStatus.error);
          }
        },
        onDone: () {
          _addLog('Koneksi WebSocket ditutup');
          if (mounted) {
            setState(() => _status = ConnectionStatus.disconnected);
          }
        },
      );

      setState(() {
        _status = ConnectionStatus.connected;
      });
      _addLog('WebSocket terhubung!');
    } catch (e) {
      _addLog('Gagal connect WS: $e');
      setState(() => _status = ConnectionStatus.error);
    }
  }

  void _handleIncomingMessage(String rawData, int? rtt) {
    String displayText = rawData;
    try {
      final decoded = jsonDecode(rawData);
      if (decoded is Map && decoded.containsKey('message')) {
        displayText = decoded['message'].toString();
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(
          text: displayText,
          isMe: false,
          timestamp: DateTime.now(),
          latencyMs: rtt,
        ));
      });
      _addLog('Pesan Diterima: $rawData ${rtt != null ? "(${rtt}ms)" : ""}');
      _scrollToBottom();
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty || _status != ConnectionStatus.connected) return;

    _pingStopwatch = Stopwatch()..start();

    // Kirim pesan ke WebSocket sink
    _channel?.sink.add(text);

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isMe: true,
        timestamp: DateTime.now(),
      ));
    });

    _addLog('Mengirim: "$text"');
    _textController.clear();
    _scrollToBottom();
  }

  void _disconnectWebSocket() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;

    if (_status != ConnectionStatus.disconnected) {
      setState(() {
        _status = ConnectionStatus.disconnected;
      });
      _addLog('Koneksi WebSocket diputus');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _disconnectWebSocket();
    _textController.dispose();
    _scrollController.dispose();
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
                              color: Colors.blueAccent.shade100.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.sync_alt,
                                color: Colors.blueAccent),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Praktikum 4 — WebSocket',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Komunikasi Dua Arah Penuh (Full-Duplex)',
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
                    'WebSocket URL (WSS):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  SelectableText(
                    ApiConfig.wsUrl,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.blueAccent,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Connect / Disconnect Buttons
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
                          : _connectWebSocket,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                      icon: const Icon(Icons.power),
                      label: const Text('Connect WebSocket'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _status == ConnectionStatus.connected ||
                              _status == ConnectionStatus.connecting
                          ? _disconnectWebSocket
                          : null,
                      icon: const Icon(Icons.power_off),
                      label: const Text('Disconnect'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Chat Window Area
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.chat, size: 18, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Text(
                        'Simulasi Chat Dua Arah',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Messages list
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _messages.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada pesan. Hubungkan lalu kirim pesan!',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              return Align(
                                alignment: msg.isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: msg.isMe
                                        ? Colors.blueAccent
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: msg.isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg.text,
                                        style: TextStyle(
                                          color: msg.isMe
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${msg.isMe ? "Kamu" : "Server"} • ${msg.timestamp.toIso8601String().substring(11, 19)}${msg.latencyMs != null ? " • RTT: ${msg.latencyMs}ms" : ""}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: msg.isMe
                                              ? Colors.white70
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),

                  // Input box
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          enabled: _status == ConnectionStatus.connected,
                          decoration: InputDecoration(
                            hintText: _status == ConnectionStatus.connected
                                ? 'Ketik pesan chat...'
                                : 'Hubungkan WebSocket terlebih dahulu',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _status == ConnectionStatus.connected
                            ? _sendMessage
                            : null,
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Log console
          LogConsole(
            logs: _logs,
            onClear: () => setState(() => _logs.clear()),
            title: 'Log Frame WebSocket',
          ),
          const SizedBox(height: 16),

          // Explanation Card
          _buildExplanationCard(),
        ],
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Catatan & Analisis Praktikum 4 (WebSocket)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '1. Handshake HTTP ke WS Upgrade:\n'
              '   Komunikasi berawal dari HTTP handshake dengan header `Upgrade: websocket`. Setelah server menyetujui (101 Switching Protocols), koneksi TCP tetap terbuka permanen.\n\n'
              '2. Komunikasi Full-Duplex:\n'
              '   Klien dan server dapat saling mengirim frame pesan kapan saja tanpa menunggu giliran atau membuat koneksi baru.\n\n'
              '3. Overhead Sangat Rendah:\n'
              '   Setiap frame pesan hanya memiliki header sebesar 2 hingga 10 byte (dibandingkan ratusan byte pada HTTP request/response), sehingga sangat hemat bandwidth dan memiliki latensi minimal.\n\n'
              '4. Skenario Multi-Client Broadcast:\n'
              '   Pada backend, jika server mengiterasi semua socket dalam `clients.forEach(c => c.send(...))`, maka setiap pesan yang dikirim satu user akan langsung diterima oleh semua pengguna lain secara serentak.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
