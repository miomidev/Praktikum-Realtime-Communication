import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdvancedAndAnalysisScreen extends StatefulWidget {
  const AdvancedAndAnalysisScreen({super.key});

  @override
  State<AdvancedAndAnalysisScreen> createState() =>
      _AdvancedAndAnalysisScreenState();
}

class _AdvancedAndAnalysisScreenState extends State<AdvancedAndAnalysisScreen> {
  // ==================== WEBRTC STATE ====================
  bool _isLocalCameraActive = false;
  bool _isPeerConnected = false;
  bool _isSignaling = false;
  String _signalingStatus = 'Siap (Belum terkoneksi)';
  final TextEditingController _dataChannelController =
      TextEditingController(text: 'Halo via WebRTC DataChannel!');
  final List<String> _dataChannelMessages = [];

  // ==================== GRPC STATE ====================
  String _selectedGrpcPattern = 'unary'; // unary, server, client, bidi
  bool _isGrpcStreaming = false;
  Timer? _grpcStreamTimer;
  int _grpcPacketCount = 0;
  final List<String> _grpcLogs = [];

  // ==================== FCM STATE ====================
  final String _fcmToken =
      'cK8p9_v4q7LaM3z0xP2yQ:APA91bF8d_w3R9t1m5X2yZ8k7j0h4g6f5d4s3a2q1w0';
  final TextEditingController _fcmTitleController =
      TextEditingController(text: 'Peringatan Sensor Suhu!');
  final TextEditingController _fcmBodyController =
      TextEditingController(text: 'Sensor ruangan 302 mendeteksi suhu 38.5°C');
  bool _showForegroundBanner = false;
  String _bannerTitle = '';
  String _bannerBody = '';
  final List<Map<String, String>> _fcmHistory = [];

  @override
  void dispose() {
    _dataChannelController.dispose();
    _grpcStreamTimer?.cancel();
    _fcmTitleController.dispose();
    _fcmBodyController.dispose();
    super.dispose();
  }

  // ==================== WEBRTC METHODS ====================
  void _toggleLocalCamera() {
    setState(() {
      _isLocalCameraActive = !_isLocalCameraActive;
      if (!_isLocalCameraActive && _isPeerConnected) {
        _isPeerConnected = false;
        _signalingStatus = 'Kamera dimatikan';
      }
    });
  }

  Future<void> _startWebRtcSignaling() async {
    if (!_isLocalCameraActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aktifkan kamera lokal terlebih dahulu!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSignaling = true;
      _signalingStatus = '1. Membuat SDP Offer...';
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _signalingStatus = '2. Menghubungi STUN Server untuk ICE Candidates...';
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _signalingStatus = '3. Menukar SDP Offer/Answer via Signaling Server...';
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _isSignaling = false;
      _isPeerConnected = true;
      _signalingStatus = 'P2P Terhubung Langsung (UDP/SRTP) • Latensi: 34ms';
      _dataChannelMessages.add(
          '[System] Koneksi WebRTC Peer-to-Peer & DataChannel berhasil dibentuk!');
    });
  }

  void _sendDataChannelMessage() {
    final text = _dataChannelController.text.trim();
    if (text.isEmpty || !_isPeerConnected) return;

    final time = DateTime.now().toIso8601String().substring(11, 19);
    setState(() {
      _dataChannelMessages.add('[$time] Anda (P2P): $text');
      _dataChannelMessages.add(
          '[$time] Peer B (Echo via DataChannel): "$text" (Diterima dalam 18ms)');
    });
    _dataChannelController.clear();
  }

  void _disconnectWebRtc() {
    setState(() {
      _isPeerConnected = false;
      _signalingStatus = 'Koneksi P2P ditutup';
    });
  }

  // ==================== GRPC METHODS ====================
  void _executeGrpcCall() {
    final time = DateTime.now().toIso8601String().substring(11, 19);

    if (_selectedGrpcPattern == 'unary') {
      setState(() {
        _grpcPacketCount++;
        _grpcLogs.insert(
          0,
          '[$time] Unary RPC: GetLatest(device_id="esp32-01")\n'
          '➔ SensorReading(value=28.7°C, timestamp=1710000$_grpcPacketCount)\n'
          'ℹ️ Ukuran Paket: Protobuf 24 bytes vs JSON 118 bytes (Hemat 79.6% Bandwidth!)',
        );
      });
    } else if (_selectedGrpcPattern == 'server') {
      if (_isGrpcStreaming) {
        _grpcStreamTimer?.cancel();
        setState(() {
          _isGrpcStreaming = false;
          _grpcLogs.insert(0, '[$time] Server Streaming: WatchSensor() dihentikan');
        });
      } else {
        setState(() {
          _isGrpcStreaming = true;
          _grpcLogs.insert(
            0,
            '[$time] Server Streaming: WatchSensor(device_id="esp32-01") dimulai (HTTP/2 stream aktif)',
          );
        });

        _grpcStreamTimer =
            Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          final tickTime =
              DateTime.now().toIso8601String().substring(11, 19);
          final simVal = 27.0 + (timer.tick % 8) * 0.4;
          setState(() {
            _grpcPacketCount++;
            _grpcLogs.insert(
              0,
              '[$tickTime] Stream Packet #$_grpcPacketCount: SensorReading(val=${simVal.toStringAsFixed(1)}°C) [Binary HTTP/2 Frame]',
            );
          });
        });
      }
    } else if (_selectedGrpcPattern == 'client') {
      setState(() {
        _grpcPacketCount += 5;
        _grpcLogs.insert(
          0,
          '[$time] Client Streaming: UploadBatch(5 sensor frames terkirim)\n'
          '➔ BatchSummaryResponse(uploaded=5, avg_temp=28.2°C, status=OK)',
        );
      });
    } else if (_selectedGrpcPattern == 'bidi') {
      setState(() {
        _grpcPacketCount += 2;
        _grpcLogs.insert(
          0,
          '[$time] Bi-directional Stream: Client frame terkirim 🔁 Server ack diterima serentak',
        );
      });
    }
  }

  // ==================== FCM METHODS ====================
  void _triggerFcmNotification({required bool isForeground}) {
    final title = _fcmTitleController.text.trim().isEmpty
        ? 'Notifikasi Uji Praktikum'
        : _fcmTitleController.text.trim();
    final body = _fcmBodyController.text.trim().isEmpty
        ? 'Ini adalah simulasi push notification FCM.'
        : _fcmBodyController.text.trim();
    final time = DateTime.now().toIso8601String().substring(11, 19);

    setState(() {
      _fcmHistory.insert(0, {
        'title': title,
        'body': body,
        'time': time,
        'type': isForeground ? 'Foreground (onMessage)' : 'Background (System Tray)',
      });

      if (isForeground) {
        _bannerTitle = title;
        _bannerBody = body;
        _showForegroundBanner = true;
      }
    });

    if (isForeground) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _showForegroundBanner = false;
          });
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notifikasi Background terkirim ke baki sistem: "$title"'),
          backgroundColor: Colors.deepPurple,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          // Banner notifikasi foreground animasi
          if (_showForegroundBanner) _buildForegroundBanner(),

          Container(
            color: Theme.of(context).colorScheme.surface,
            child: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.deepPurple,
              tabs: [
                Tab(icon: Icon(Icons.videocam), text: 'WebRTC (P2P)'),
                Tab(icon: Icon(Icons.cable), text: 'gRPC Streaming'),
                Tab(icon: Icon(Icons.notifications_active), text: 'FCM Push'),
                Tab(icon: Icon(Icons.table_chart), text: 'Matriks & Analisis'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildWebRtcTab(context),
                _buildGrpcTab(context),
                _buildFcmTab(context),
                _buildMatrixAndAnalysisTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForegroundBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _bannerTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Text(
                      'baru saja',
                      style: TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _bannerBody,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white60, size: 16),
            onPressed: () => setState(() => _showForegroundBanner = false),
          ),
        ],
      ),
    );
  }

  // ===================== WEBRTC TAB =====================
  Widget _buildWebRtcTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoBanner(
            title: 'Praktikum 6 — WebRTC (Web Real-Time Communication)',
            subtitle:
                'Media Audio/Video & DataChannel langsung Peer-to-Peer antarpengguna tanpa membebani server.',
            icon: Icons.videocam,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 16),

          // Live P2P Simulator Window
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
                      const Text(
                        'Simulasi P2P Video Call & DataChannel',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _isPeerConnected
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _isPeerConnected ? 'P2P Connected' : 'Disconnected',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: _isPeerConnected
                                ? Colors.green
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Dua Jendela Video (Local & Remote)
                  Row(
                    children: [
                      // Video Lokal
                      Expanded(
                        child: Container(
                          height: 140,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isLocalCameraActive
                                  ? Colors.greenAccent
                                  : Colors.grey.shade800,
                              width: _isLocalCameraActive ? 1.5 : 1,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isLocalCameraActive
                                        ? Icons.videocam
                                        : Icons.videocam_off,
                                    size: 36,
                                    color: _isLocalCameraActive
                                        ? Colors.greenAccent
                                        : Colors.white30,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _isLocalCameraActive
                                        ? 'Local Stream (Kamera Aktif)\n1280x720 @ 30fps'
                                        : 'Kamera Lokal Nonaktif',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _isLocalCameraActive
                                          ? Colors.white
                                          : Colors.white38,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('Kamera Anda',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 9)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Video Remote
                      Expanded(
                        child: Container(
                          height: 140,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isPeerConnected
                                  ? Colors.blueAccent
                                  : Colors.grey.shade800,
                              width: _isPeerConnected ? 1.5 : 1,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isPeerConnected
                                        ? Icons.person
                                        : Icons.person_outline,
                                    size: 36,
                                    color: _isPeerConnected
                                        ? Colors.blueAccent
                                        : Colors.white30,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _isPeerConnected
                                        ? 'Peer B Terhubung\nSRTP/UDP • Latensi: 34ms'
                                        : 'Menunggu Peer B...',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _isPeerConnected
                                          ? Colors.white
                                          : Colors.white38,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('Remote Peer',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 9)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Status bar signaling
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isSignaling
                              ? Icons.sync
                              : (_isPeerConnected
                                  ? Icons.check_circle
                                  : Icons.info_outline),
                          size: 14,
                          color: _isPeerConnected ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Status Signaling: $_signalingStatus',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tombol Aksi Kontrol
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _toggleLocalCamera,
                          icon: Icon(_isLocalCameraActive
                              ? Icons.videocam_off
                              : Icons.videocam),
                          label: Text(_isLocalCameraActive
                              ? 'Tutup Kamera'
                              : '1. Buka Kamera'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isSignaling
                              ? null
                              : (_isPeerConnected
                                  ? _disconnectWebRtc
                                  : _startWebRtcSignaling),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                _isPeerConnected ? Colors.red : Colors.redAccent,
                          ),
                          icon: Icon(_isPeerConnected
                              ? Icons.call_end
                              : Icons.connect_without_contact),
                          label: Text(_isPeerConnected
                              ? 'Putus P2P'
                              : '2. Connect P2P'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // DataChannel Chat Test
                  const Text(
                    'Uji WebRTC DataChannel (Kirim Data Langsung Tanpa Server):',
                    style:
                        TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _dataChannelController,
                          enabled: _isPeerConnected,
                          decoration: InputDecoration(
                            hintText: _isPeerConnected
                                ? 'Pesan DataChannel...'
                                : 'Hubungkan P2P terlebih dahulu',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed:
                            _isPeerConnected ? _sendDataChannelMessage : null,
                        icon: const Icon(Icons.send, size: 18),
                      ),
                    ],
                  ),

                  // DataChannel log box
                  if (_dataChannelMessages.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      height: 85,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ListView.builder(
                        itemCount: _dataChannelMessages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              _dataChannelMessages[index],
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                color: Colors.lightGreenAccent,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Penjelasan Step & Kode
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tahapan Koneksi WebRTC (Signaling Flow)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _buildStepTile(
                    '1',
                    'Media Capture & PeerConnection',
                    'Aplikasi mengakses kamera/mikrofon via getUserMedia() dan menginisialisasi RTCPeerConnection.',
                  ),
                  _buildStepTile(
                    '2',
                    'SDP Offer (Client A)',
                    'Client A membuat session description (codec, resolusi, format) dalam bentuk SDP Offer.',
                  ),
                  _buildStepTile(
                    '3',
                    'Signaling Server',
                    'Offer dikirim ke Client B melalui perantara (Signaling Server, via WebSocket/HTTP).',
                  ),
                  _buildStepTile(
                    '4',
                    'SDP Answer (Client B)',
                    'Client B menyetujui parameter koneksi dan membalas dengan SDP Answer.',
                  ),
                  _buildStepTile(
                    '5',
                    'ICE Candidates (STUN / TURN)',
                    'Kedua pihak bertukar kandidat alamat IP & Port publik via STUN untuk menembus NAT/Firewall. Jika gagal P2P langsung, TURN digunakan sebagai relay.',
                  ),
                  _buildStepTile(
                    '6',
                    'Direct P2P Stream',
                    'Koneksi P2P terbentuk! Media audio/video mengalir langsung antardua perangkat dengan latency ultra-rendah (<100ms) menggunakan SRTP/UDP.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Analysis Question
          _buildQnACard(
            question:
                'Mengapa WebRTC lebih tepat untuk video call dibandingkan mengirim gambar kamera berulang kali melalui REST API?',
            answer:
                '1. Arsitektur Peer-to-Peer (P2P):\n'
                '   Stream video mengalir langsung antar perangkat pengguna tanpa harus membebani server dengan lalu lintas media bergigabyte.\n\n'
                '2. Menggunakan UDP (SRTP):\n'
                '   REST API memakai TCP yang memaksa retransmisi paket hilang (menyebabkan video freeze/buffer). WebRTC memakai UDP/SRTP di mana bila 1 frame hilang, sistem langsung menampilkan frame berikutnya tanpa lag.\n\n'
                '3. Hardware Codec & Adaptive Bitrate:\n'
                '   WebRTC mengintegrasikan kompresi video modern (VP8/VP9/H.264/AV1) dengan adaptasi bitrate dinamis sesuai fluktuasi sinyal pengguna.',
          ),
        ],
      ),
    );
  }

  // ===================== GRPC TAB =====================
  Widget _buildGrpcTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoBanner(
            title: 'Praktikum 7 — gRPC Streaming',
            subtitle:
                'High-performance RPC berbasis HTTP/2 dan Protocol Buffers (Protobuf).',
            icon: Icons.cable,
            color: Colors.cyan.shade800,
          ),
          const SizedBox(height: 16),

          // Interactive gRPC Simulator Card
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Simulasi Eksekusi gRPC Client',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  const SizedBox(height: 10),

                  // Pattern Selector
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'unary', label: Text('Unary')),
                      ButtonSegment(value: 'server', label: Text('Server Stream')),
                      ButtonSegment(value: 'client', label: Text('Client Stream')),
                      ButtonSegment(value: 'bidi', label: Text('Bi-di')),
                    ],
                    selected: {_selectedGrpcPattern},
                    onSelectionChanged: (val) {
                      setState(() {
                        _selectedGrpcPattern = val.first;
                        _grpcStreamTimer?.cancel();
                        _isGrpcStreaming = false;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Action Trigger
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _executeGrpcCall,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.cyan.shade800,
                          ),
                          icon: Icon(_isGrpcStreaming
                              ? Icons.stop
                              : Icons.play_arrow),
                          label: Text(_selectedGrpcPattern == 'unary'
                              ? 'Panggil Unary RPC (GetLatest)'
                              : (_selectedGrpcPattern == 'server'
                                  ? (_isGrpcStreaming
                                      ? 'Hentikan Server Stream'
                                      : 'Mulai Server Stream (WatchSensor)')
                                  : (_selectedGrpcPattern == 'client'
                                      ? 'Kirim Client Batch Stream'
                                      : 'Panggil Bidirectional Stream'))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Live gRPC Frame Log Box
                  Container(
                    height: 130,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _grpcLogs.isEmpty
                        ? const Center(
                            child: Text(
                              'Pilih pola gRPC di atas lalu klik tombol untuk mengeksekusi request.',
                              style:
                                  TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _grpcLogs.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  _grpcLogs[index],
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10.5,
                                    color: Colors.cyanAccent,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4 Pattern Cards
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '4 Pola Komunikasi gRPC',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _buildRpcPatternTile(
                    'Unary RPC',
                    '1 Req ➔ 1 Res',
                    'Sama seperti REST API biasa, namun diproses dengan binary payload Protobuf yang jauh lebih cepat.',
                    Icons.arrow_forward,
                    Colors.blue,
                  ),
                  _buildRpcPatternTile(
                    'Server Streaming',
                    '1 Req ➔ Stream Res',
                    'Client meminta pemantauan sensor, server terus mengalirkan data pembacaan secara live.',
                    Icons.trending_down,
                    Colors.green,
                  ),
                  _buildRpcPatternTile(
                    'Client Streaming',
                    'Stream Req ➔ 1 Res',
                    'Client mengunggah file besar atau log batch secara streaming sebelum server membalas dengan rangkuman.',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                  _buildRpcPatternTile(
                    'Bidirectional Streaming',
                    'Stream Req 🔁 Stream Res',
                    'Kedua pihak saling streaming pesan independen secara bersamaan melalui satu koneksi HTTP/2 multiplexing.',
                    Icons.sync_alt,
                    Colors.purple,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Proto file preview
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Definisi Schema: sensor.proto',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'syntax = "proto3";\n'
                      'package monitoring;\n\n'
                      'service SensorService {\n'
                      '  rpc GetLatest (SensorRequest) returns (SensorReading);\n'
                      '  rpc WatchSensor (SensorRequest) returns (stream SensorReading);\n'
                      '}\n\n'
                      'message SensorRequest {\n'
                      '  string device_id = 1;\n'
                      '}\n\n'
                      'message SensorReading {\n'
                      '  string device_id = 1;\n'
                      '  double value = 2;\n'
                      '  int64 timestamp = 3;\n'
                      '}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Analysis Question
          _buildQnACard(
            question:
                'Dalam sistem monitoring yang mengirim ribuan pembaruan terstruktur, kapan gRPC streaming dapat lebih sesuai dibandingkan REST API?',
            answer:
                'gRPC Streaming jauh lebih unggul ketika:\n'
                '1. Volume Data & Frekuensi Tinggi:\n'
                '   Serialisasi Protobuf menghasilkan ukuran paket 60-80% lebih kecil dibanding JSON dan parsing binary CPU jauh lebih cepat.\n\n'
                '2. Arsitektur Microservices Backend-to-Backend:\n'
                '   gRPC berjalan di atas HTTP/2 yang mendukung multiplexing sejati (banyak stream dalam 1 koneksi TCP) dan kompresi header HPACK.\n\n'
                '3. Kebutuhan Aliran Data Berkelanjutan:\n'
                '   Menghilangkan latensi TCP handshake berulang kali yang biasanya terjadi pada REST polling.',
          ),
        ],
      ),
    );
  }

  // ===================== FCM TAB =====================
  Widget _buildFcmTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoBanner(
            title: 'Praktikum 8 — Push Notification (FCM)',
            subtitle:
                'Mengirimkan notifikasi dan pesan data saat aplikasi foreground, background, atau ditutup.',
            icon: Icons.notifications_active,
            color: Colors.amber.shade900,
          ),
          const SizedBox(height: 16),

          // Interactive FCM Tester Card
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Simulasi Pengujian Notifikasi FCM',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  const SizedBox(height: 10),

                  // Token Display
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'FCM Registration Token (Perangkat):',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: _fcmToken));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Token FCM disalin!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: const Row(
                                children: [
                                  Icon(Icons.copy, size: 14, color: Colors.blue),
                                  SizedBox(width: 4),
                                  Text('Salin',
                                      style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          _fcmToken,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Inputs
                  TextField(
                    controller: _fcmTitleController,
                    decoration: InputDecoration(
                      labelText: 'Judul Notifikasi',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _fcmBodyController,
                    decoration: InputDecoration(
                      labelText: 'Isi Pesan Notifikasi',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Trigger Buttons
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () =>
                              _triggerFcmNotification(isForeground: true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.amber.shade900,
                          ),
                          icon: const Icon(Icons.arrow_downward, size: 16),
                          label: const Text('1. Uji Foreground',
                              style: TextStyle(fontSize: 11.5)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _triggerFcmNotification(isForeground: false),
                          icon: const Icon(Icons.schedule, size: 16),
                          label: const Text('2. Uji Background',
                              style: TextStyle(fontSize: 11.5)),
                        ),
                      ),
                    ],
                  ),

                  // History box
                  if (_fcmHistory.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Riwayat Notifikasi Masuk:',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      height: 100,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ListView.builder(
                        itemCount: _fcmHistory.length,
                        itemBuilder: (context, index) {
                          final item = _fcmHistory[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.notifications,
                                    size: 14, color: Colors.amber),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '[${item["time"]}] ${item["title"]} — ${item["body"]} (${item["type"]})',
                                    style: const TextStyle(fontSize: 10.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Arsitektur FCM
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Arsitektur Pengiriman Pesan FCM',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _buildStepTile(
                    '1',
                    'Registrasi Perangkat',
                    'Aplikasi Flutter meminta FCM Registration Token ke Firebase Cloud Messaging SDK.',
                  ),
                  _buildStepTile(
                    '2',
                    'Penyimpanan Token',
                    'Token unik perangkat dikirim dan disimpan di database backend aplikasi.',
                  ),
                  _buildStepTile(
                    '3',
                    'Pengiriman Pesan oleh Backend',
                    'Ketika ada event baru, backend mengirim pesan ke FCM API menggunakan Firebase Admin SDK tepercaya.',
                  ),
                  _buildStepTile(
                    '4',
                    'Penerusan ke Perangkat',
                    'Server FCM meneruskan pesan ke perangkat melalui koneksi sistem terpusat (Google Play Services di Android / APNs di Apple).',
                  ),
                  _buildStepTile(
                    '5',
                    'Penanganan Pesan',
                    'Jika aplikasi di layar (Foreground), pesan ditangani via FirebaseMessaging.onMessage. Jika tertutup (Background/Killed), ditangani via onBackgroundMessage dan ditampilkan di baki notifikasi sistem.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Analysis Question
          _buildQnACard(
            question:
                'Mengapa push notification tidak menjamin pembaruan data seketika seperti aliran WebSocket yang aktif?',
            answer:
                '1. Mekanisme Store-and-Forward Asinkron:\n'
                '   FCM adalah antrean pesan terkelola. Jika perangkat kehilangan koneksi, berada dalam mode hemat baterai (Android Doze Mode), atau jaringan seluler lambat, pesan akan ditahan di server Google sampai perangkat siap menerimanya.\n\n'
                '2. Prioritas & OS Power Throttling:\n'
                '   Sistem operasi mobile modern membatasi aktivitas background untuk menghemat baterai. Notifikasi normal dapat ditunda oleh OS.\n\n'
                '3. Bukan Dedicated Persistent Socket:\n'
                '   WebSocket mempertahankan koneksi TCP point-to-point langsung antara Flutter dan backend aplikasi Anda. FCM memanfaatkan koneksi bersama Google Play Services yang tidak menjamin latency sub-detik.',
          ),
        ],
      ),
    );
  }

  // ===================== MATRIX & ANALYSIS TAB =====================
  Widget _buildMatrixAndAnalysisTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoBanner(
            title: 'Panduan Pemilihan Teknologi Real-time',
            subtitle:
                'Matriks komparasi untuk menentukan teknologi terbaik berdasarkan use case aplikasi.',
            icon: Icons.table_chart,
            color: Colors.deepPurple,
          ),
          const SizedBox(height: 16),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Matriks Perbandingan Komprehensif',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor:
                          WidgetStateProperty.all(Colors.grey.shade100),
                      columns: const [
                        DataColumn(
                            label: Text('Teknologi',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Arah Komunikasi',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Transport',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Latensi',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Use Case Ideal',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: const [
                        DataRow(cells: [
                          DataCell(Text('REST API',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text('1 arah (Client Req)')),
                          DataCell(Text('HTTP/1.1 or 2')),
                          DataCell(Text('Tinggi (manual)')),
                          DataCell(Text('CRUD, Auth, Profil')),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('Polling',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text('1 arah (Interval)')),
                          DataCell(Text('HTTP Request')),
                          DataCell(Text('Sedang (sesuai jeda)')),
                          DataCell(Text('Data jarang berubah')),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('SSE',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text('1 arah (Server ➔ Client)')),
                          DataCell(Text('HTTP Streaming')),
                          DataCell(Text('Rendah (<1s)')),
                          DataCell(Text('Live score, News, Log')),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('WebSocket',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text('2 arah (Full Duplex)')),
                          DataCell(Text('TCP Socket (WS/WSS)')),
                          DataCell(Text('Sangat Rendah (ms)')),
                          DataCell(Text('Chat, Game, Kolaborasi')),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('MQTT',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text('Pub / Sub')),
                          DataCell(Text('TCP / WS Light')),
                          DataCell(Text('Sangat Rendah (ms)')),
                          DataCell(Text('IoT, Sensor ESP32, Smart Home')),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('WebRTC',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text('2 arah (P2P)')),
                          DataCell(Text('UDP (SRTP / SCTP)')),
                          DataCell(Text('Ultra Rendah (<100ms)')),
                          DataCell(Text('Video Call, Voice Chat, P2P')),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('gRPC Streaming',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text('1 / 2 arah Stream')),
                          DataCell(Text('HTTP/2 (Protobuf)')),
                          DataCell(Text('Sangat Rendah (ms)')),
                          DataCell(Text('Microservices, Telemetri')),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('FCM Push',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text('Server ➔ Perangkat')),
                          DataCell(Text('Cloud Gateway')),
                          DataCell(Text('Bervariasi (dtk - mnt)')),
                          DataCell(Text('Promo, Alert saat App mati')),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aturan Praktis (Rule of Thumb) Pemilihan:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  _buildRuleItem('Hanya butuh data saat user membuka layar?',
                      'Gunakan REST API standar.'),
                  _buildRuleItem(
                      'Server perlu mengalirkan update teks/angka satu arah?',
                      'Gunakan SSE (Server-Sent Events).'),
                  _buildRuleItem(
                      'Aplikasi chat interaktif, trading, atau game multiplayer?',
                      'Gunakan WebSocket.'),
                  _buildRuleItem('Perangkat IoT baterai terbatas & sensor?',
                      'Gunakan MQTT (Publish-Subscribe).'),
                  _buildRuleItem('Panggilan suara atau video call langsung?',
                      'Gunakan WebRTC (Peer-to-Peer).'),
                  _buildRuleItem(
                      'Komunikasi data bervolume tinggi antar server/microservice?',
                      'Gunakan gRPC Streaming.'),
                  _buildRuleItem(
                      'Memberitahu pengguna saat aplikasi tidak sedang dibuka?',
                      'Gunakan FCM Push Notification.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== HELPER WIDGETS =====================
  Widget _buildInfoBanner({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTile(String step, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.deepPurple,
            child: Text(
              step,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(description,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRpcPatternTile(String title, String flow, String description,
      IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    flow,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(description,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade800)),
        ],
      ),
    );
  }

  Widget _buildQnACard({required String question, required String answer}) {
    return Card(
      elevation: 0,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade200),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(Icons.psychology, color: Colors.amber.shade900),
        title: const Text(
          'Pertanyaan & Analisis Praktikum',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('❓ ', style: TextStyle(fontSize: 14)),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡 ', style: TextStyle(fontSize: 14)),
              Expanded(
                child: Text(
                  answer,
                  style: const TextStyle(fontSize: 12.5, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 12),
                children: [
                  TextSpan(
                      text: '$question ',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(
                      text: '➔ $answer',
                      style: const TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
