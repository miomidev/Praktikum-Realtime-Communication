import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../config/api_config.dart';
import '../widgets/log_console.dart';
import '../widgets/status_badge.dart';

class MqttScreen extends StatefulWidget {
  const MqttScreen({super.key});

  @override
  State<MqttScreen> createState() => _MqttScreenState();
}

class _MqttScreenState extends State<MqttScreen> {
  MqttServerClient? _client;
  StreamSubscription? _updateSubscription;
  Timer? _autoPublishTimer;
  bool _isAutoPublishing = false;

  ConnectionStatus _status = ConnectionStatus.disconnected;

  // Transport: 'ws' (WebSocket Port 8000 - Firewall Friendly) atau 'tcp' (TCP Port 1883)
  String _transportMode = 'ws';
  String _selectedBroker = ApiConfig.mqttBroker;

  final TextEditingController _topicController =
      TextEditingController(text: ApiConfig.mqttDefaultTopic);
  double _publishTemperature = 28.5;

  double? _receivedTemperature;
  String? _lastReceivedTime;
  int _receivedCount = 0;
  int _publishedCount = 0;

  final List<String> _logs = [];

  void _addLog(String message) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    if (mounted) {
      setState(() {
        _logs.add('[$time] $message');
      });
    }
  }

  Future<void> _connectMqtt() async {
    _disconnectMqtt();

    setState(() {
      _status = ConnectionStatus.connecting;
    });

    final clientId = 'flutter_client_${DateTime.now().millisecondsSinceEpoch}';

    if (_transportMode == 'ws') {
      final wsUrl = 'ws://$_selectedBroker/mqtt';
      _addLog(
          'Menghubungkan MQTT via WebSocket ke $wsUrl:${ApiConfig.mqttWsPort}...');
      _client = MqttServerClient.withPort(
        wsUrl,
        clientId,
        ApiConfig.mqttWsPort,
      );
      _client!.useWebSocket = true;
      _client!.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
    } else {
      _addLog(
          'Menghubungkan MQTT via TCP ke $_selectedBroker:${ApiConfig.mqttTcpPort}...');
      _client = MqttServerClient.withPort(
        _selectedBroker,
        clientId,
        ApiConfig.mqttTcpPort,
      );
      _client!.useWebSocket = false;
    }

    _client!.logging(on: false);
    _client!.keepAlivePeriod = 30;
    _client!.autoReconnect = true;

    _client!.onConnected = () {
      _addLog('MQTT Terhubung ke Broker ($_selectedBroker)!');
    };

    _client!.onDisconnected = () {
      _addLog('MQTT Terputus dari Broker');
      if (mounted) setState(() => _status = ConnectionStatus.disconnected);
    };

    _client!.onSubscribed = (topic) {
      _addLog('Topik "$topic" aktif! Siap menerima & mengirim pesan.');
    };

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    _client!.connectionMessage = connMessage;

    try {
      final status = await _client!.connect();
      if (status?.state == MqttConnectionState.connected) {
        if (mounted) {
          setState(() => _status = ConnectionStatus.connected);
        }

        // Pasang listener pesan masuk
        _updateSubscription?.cancel();
        _updateSubscription = _client!.updates
            ?.listen((List<MqttReceivedMessage<MqttMessage>> events) {
          for (final event in events) {
            final publishMessage = event.payload as MqttPublishMessage;
            final payloadString = MqttPublishPayload.bytesToStringAsString(
              publishMessage.payload.message,
            );

            _handleReceivedMessage(event.topic, payloadString);
          }
        });

        // Langsung subscribe ke topik
        _subscribeTopic();
      } else {
        _addLog('Gagal connect MQTT: ${status?.state}');
        _disconnectMqtt();
      }
    } catch (e) {
      _addLog('Exception koneksi MQTT: $e');
      if (_transportMode == 'tcp') {
        _addLog(
            '⚠️ CATATAN: Port 1883 TCP sering diblokir oleh provider internet/Wi-Fi kampus. Silakan ganti Transport ke "WebSocket (Port 8000)" lalu klik Connect lagi!');
      }
      _disconnectMqtt();
    }
  }

  void _subscribeTopic() {
    final topic = _topicController.text.trim();
    if (_client?.connectionStatus?.state != MqttConnectionState.connected ||
        topic.isEmpty) {
      return;
    }

    _client!.subscribe(topic, MqttQos.atMostOnce);
    _addLog('Mengirim request subscribe ke topik: $topic');
  }

  void _handleReceivedMessage(String topic, String payload) {
    _addLog('IN ($topic): $payload');

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map && decoded.containsKey('temperature')) {
        final temp = double.tryParse(decoded['temperature'].toString());
        final time = decoded['timestamp']?.toString() ??
            DateTime.now().toIso8601String();

        if (mounted && temp != null) {
          setState(() {
            _receivedTemperature = temp;
            _lastReceivedTime = time;
            _receivedCount++;
          });
        }
      }
    } catch (_) {
      // payload teks biasa
    }
  }

  void _publishData([double? customValue]) {
    final topic = _topicController.text.trim();
    if (_client?.connectionStatus?.state != MqttConnectionState.connected ||
        topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Harap tekan tombol "Connect & Subscribe" terlebih dahulu!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final valueToSend = customValue ?? _publishTemperature;
    final payloadMap = {
      'temperature': double.parse(valueToSend.toStringAsFixed(1)),
      'timestamp': DateTime.now().toIso8601String(),
    };

    final jsonString = jsonEncode(payloadMap);
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonString);

    _client!.publishMessage(
      topic,
      MqttQos.atMostOnce,
      builder.payload!,
    );

    setState(() {
      _publishedCount++;
    });

    _addLog('OUT ($topic): $jsonString');
  }

  void _toggleAutoPublish(bool enable) {
    setState(() {
      _isAutoPublishing = enable;
    });

    _autoPublishTimer?.cancel();
    if (enable) {
      if (_status != ConnectionStatus.connected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hubungkan broker MQTT terlebih dahulu!'),
          ),
        );
        setState(() => _isAutoPublishing = false);
        return;
      }

      _addLog('Simulasi Auto-Publish sensor aktif (setiap 3 dtk)');
      _autoPublishTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (_status != ConnectionStatus.connected) {
          timer.cancel();
          setState(() => _isAutoPublishing = false);
          return;
        }
        // Naik turunkan nilai sedikit
        final variation = (timer.tick % 5) - 2;
        final simTemp = _publishTemperature + (variation * 0.5);
        _publishData(simTemp);
      });
    } else {
      _addLog('Simulasi Auto-Publish dihentikan');
    }
  }

  void _disconnectMqtt() {
    _autoPublishTimer?.cancel();
    _isAutoPublishing = false;
    _updateSubscription?.cancel();
    _updateSubscription = null;

    if (_client != null) {
      _client!.disconnect();
      _client = null;
    }
    if (_status != ConnectionStatus.disconnected) {
      setState(() => _status = ConnectionStatus.disconnected);
    }
  }

  @override
  void dispose() {
    _disconnectMqtt();
    _topicController.dispose();
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
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.sensors,
                                color: Colors.purple),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Praktikum 5 — MQTT IoT',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Protokol Publish-Subscribe Ringan',
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Petunjuk Cepat
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cara Pengujian:\n'
                    '1. Pilih Mode: "WebSocket (Port 8000)" (disarankan jika port 1883 diblokir Wi-Fi/provider).\n'
                    '2. Tekan "Connect & Subscribe".\n'
                    '3. Geser slider & tekan "Publish Data Sensor" (atau hidupkan Auto-Publish).\n'
                    '4. Data pada Monitor Subscriber langsung diperbarui seketika!',
                    style: TextStyle(fontSize: 11.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Transport Mode & Topic Configuration
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pengaturan Transport & Broker',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),

                  // Mode Selector
                  Row(
                    children: [
                      const Text('Transport: ',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'ws',
                              label: Text('WebSocket (8000)'),
                              tooltip: 'Tembus Firewall & Semua Wi-Fi',
                            ),
                            ButtonSegment(
                              value: 'tcp',
                              label: Text('TCP (1883)'),
                              tooltip: 'Raw TCP Standard',
                            ),
                          ],
                          selected: {_transportMode},
                          onSelectionChanged: _status == ConnectionStatus.connected
                              ? null
                              : (newVal) {
                                  setState(() => _transportMode = newVal.first);
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Broker selector
                  Row(
                    children: [
                      const Text('Broker: ',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedBroker,
                        isDense: true,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: 'broker.hivemq.com',
                            child: Text('HiveMQ Public (broker.hivemq.com)'),
                          ),
                          DropdownMenuItem(
                            value: 'broker.emqx.io',
                            child: Text('EMQX Public (broker.emqx.io)'),
                          ),
                        ],
                        onChanged: _status == ConnectionStatus.connected
                            ? null
                            : (val) {
                                if (val != null) {
                                  setState(() => _selectedBroker = val);
                                }
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Topic field
                  TextField(
                    controller: _topicController,
                    enabled: _status != ConnectionStatus.connected,
                    decoration: InputDecoration(
                      labelText: 'Topik MQTT',
                      hintText: 'kampus/demo/sensor01',
                      prefixIcon: const Icon(Icons.tag, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _status == ConnectionStatus.connected ||
                                  _status == ConnectionStatus.connecting
                              ? null
                              : _connectMqtt,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.purple,
                          ),
                          icon: const Icon(Icons.cloud_sync),
                          label: const Text('Connect & Subscribe'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _status == ConnectionStatus.connected ||
                                  _status == ConnectionStatus.connecting
                              ? _disconnectMqtt
                              : null,
                          icon: const Icon(Icons.power_off),
                          label: const Text('Disconnect'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Live Subscriber Monitor (Client A)
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
                      const Row(
                        children: [
                          Icon(Icons.mark_email_read,
                              color: Colors.purple, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Monitor Subscriber (Client A)',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      Text(
                        'Total Diterima: $_receivedCount',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _getTemperatureColor().withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    _getTemperatureColor().withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.thermostat,
                                      color: _getTemperatureColor(), size: 20),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Suhu Diterima',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _receivedTemperature != null
                                    ? '${_receivedTemperature!.toStringAsFixed(1)} °C'
                                    : '--.- °C',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: _getTemperatureColor(),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _lastReceivedTime != null
                                    ? 'Update: ${_lastReceivedTime!.substring(11, 19)}'
                                    : 'Menunggu data dari broker...',
                                style: const TextStyle(
                                    fontSize: 10.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.indigo.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.cloud_done,
                                      color: Colors.indigo, size: 20),
                                  SizedBox(width: 6),
                                  Text(
                                    'Status Topik',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _status == ConnectionStatus.connected
                                    ? 'Subscribed'
                                    : 'Inactive',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _status == ConnectionStatus.connected
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'QoS: 0 (At Most Once)',
                                style: TextStyle(
                                    fontSize: 10.5, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Publisher Panel (Client B)
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.upload,
                              color: Colors.deepOrange, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Simulasi Publisher Sensor (Client B)',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      Text(
                        'Total Kirim: $_publishedCount',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.deepOrange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Suhu yang Ingin Dikirim:'),
                      Text(
                        '${_publishTemperature.toStringAsFixed(1)} °C',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange),
                      ),
                    ],
                  ),
                  Slider(
                    value: _publishTemperature,
                    min: 15.0,
                    max: 45.0,
                    divisions: 60,
                    label: '${_publishTemperature.toStringAsFixed(1)}°C',
                    onChanged: (val) {
                      setState(() => _publishTemperature = val);
                    },
                  ),
                  FilledButton.icon(
                    onPressed: _status == ConnectionStatus.connected
                        ? () => _publishData()
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                    ),
                    icon: const Icon(Icons.send),
                    label: const Text('Publish Data Sensor ke Broker'),
                  ),
                  const SizedBox(height: 8),

                  // Auto-publish simulation switch
                  SwitchListTile(
                    title: const Text('Simulasi Auto-Publish Otomatis',
                        style: TextStyle(fontSize: 12.5)),
                    subtitle: const Text('Kirim data acak setiap 3 detik',
                        style: TextStyle(fontSize: 11)),
                    value: _isAutoPublishing,
                    onChanged: _status == ConnectionStatus.connected
                        ? _toggleAutoPublish
                        : null,
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
            title: 'Log Traffic MQTT',
          ),
          const SizedBox(height: 16),

          // Analysis Card
          _buildAnalysisCard(),
        ],
      ),
    );
  }

  Color _getTemperatureColor() {
    if (_receivedTemperature == null) return Colors.grey;
    if (_receivedTemperature! < 24) return Colors.blue;
    if (_receivedTemperature! < 32) return Colors.green;
    return Colors.red;
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
          'Pertanyaan & Analisis Praktikum 5',
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
            'Mengapa MQTT sering dipilih untuk IoT dibandingkan polling REST API setiap detik?',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const Divider(height: 20),
          const Text(
            '💡 Jawaban & Analisis Lengkap:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 6),
          const Text(
            '1. Overhead Header Sangat Ringan:\n'
            '   • MQTT memiliki header minimum hanya 2 byte.\n'
            '   • Bandingkan dengan HTTP yang membawa ratusan byte header (User-Agent, Accept, Cookies, Cache-Control) setiap detik, yang sangat membebani paket data seluler IoT.\n\n'
            '2. Arsitektur Decoupled (Publish-Subscribe):\n'
            '   • Sensor (ESP32) dan Flutter tidak perlu saling mengetahui alamat IP masing-masing. Keduanya hanya perlu terhubung ke broker.\n'
            '   • Skalabilitas sangat tinggi: Satu penerbitan sensor dapat langsung diterima oleh jutaan subscriber secara bersamaan.\n\n'
            '3. Efisiensi Daya Baterai Mikrokontroler:\n'
            '   • Perangkat mikrokontroler tidak perlu melakukan proses pembukaan dan penutupan TCP/TLS handshake yang berat setiap detik. Koneksi dijaga dengan "Keep-Alive Ping" yang sangat hemat daya.\n\n'
            '4. Fitur Khusus IoT Terintegrasi:\n'
            '   • Quality of Service (QoS): Pilihan keandalan pengiriman pesan (QoS 0: At most once, QoS 1: At least once, QoS 2: Exactly once).\n'
            '   • Retained Messages: Broker menyimpan pesan status sensor terakhir sehingga client yang baru terhubung langsung mengetahui kondisi terbaru tanpa menunggu sensor mem-publish lagi.\n'
            '   • Last Will & Testament (LWT): Broker otomatis memberi tahu sistem saat suatu sensor tiba-tiba mati atau kehilangan sinyal.',
            style: TextStyle(fontSize: 12.5, height: 1.4),
          ),
        ],
      ),
    );
  }
}
