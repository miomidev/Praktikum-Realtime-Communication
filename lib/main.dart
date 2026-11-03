import 'package:flutter/material.dart';
import 'screens/rest_screen.dart';
import 'screens/polling_screen.dart';
import 'screens/sse_screen.dart';
import 'screens/websocket_screen.dart';
import 'screens/mqtt_screen.dart';
import 'screens/advanced_and_analysis_screen.dart';
import 'config/api_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RealtimeCommunicationApp());
}

class RealtimeCommunicationApp extends StatelessWidget {
  const RealtimeCommunicationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Praktikum Realtime Communication',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 1,
        ),
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    RestScreen(),
    PollingScreen(),
    SseScreen(),
    WebSocketScreen(),
    MqttScreen(),
    AdvancedAndAnalysisScreen(),
  ];

  final List<String> _titles = const [
    'Praktikum 1 — REST API',
    'Praktikum 2 — Polling',
    'Praktikum 3 — Server-Sent Events',
    'Praktikum 4 — WebSocket',
    'Praktikum 5 — MQTT Broker',
    'WebRTC, gRPC & FCM Explorer',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _titles[_currentIndex],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Server: ${ApiConfig.baseUrl}',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Tentang Praktikum',
            onPressed: () => _showAboutDialog(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.http_outlined),
            selectedIcon: Icon(Icons.http),
            label: 'REST API',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Polling',
          ),
          NavigationDestination(
            icon: Icon(Icons.stream_outlined),
            selectedIcon: Icon(Icons.stream),
            label: 'SSE',
          ),
          NavigationDestination(
            icon: Icon(Icons.sync_alt_outlined),
            selectedIcon: Icon(Icons.sync_alt),
            label: 'WebSocket',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: Icon(Icons.sensors),
            label: 'MQTT',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Teori & QnA',
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.school, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Praktikum Mobile 2', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Topik: Realtime Communication',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Backend Remote: https://praktikum.mqtt.my.id'),
            Text('• SSE: flutter_http_sse (^1.0.5)'),
            Text('• WebSocket: web_socket_channel (wss://)'),
            Text('• MQTT: broker.hivemq.com (port 1883)'),
            Text('• Termasuk jawaban lengkap analisis praktikum 1 s/d 8.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
