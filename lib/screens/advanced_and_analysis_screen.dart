import 'package:flutter/material.dart';

class AdvancedAndAnalysisScreen extends StatelessWidget {
  const AdvancedAndAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
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
                'Komunikasi Peer-to-Peer untuk Audio, Video, dan Data Channel langsung antarpengguna.',
            icon: Icons.videocam,
            color: Colors.redAccent,
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
        initiallyExpanded: true,
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
