class ApiConfig {
  /// Base URL remote server praktikum
  static const String baseUrl = 'https://praktikum.mqtt.my.id';

  /// REST API endpoint data (GET)
  static const String dataEndpoint = '$baseUrl/api/data';

  /// REST API endpoint pesan (POST)
  static const String messageEndpoint = '$baseUrl/api/message';

  /// Server-Sent Events endpoint
  static const String sseEndpoint = '$baseUrl/api/events';

  /// WebSocket URL
  static const String wsUrl = 'wss://praktikum.mqtt.my.id';

  /// MQTT Public Broker
  static const String mqttBroker = 'broker.hivemq.com';
  static const int mqttTcpPort = 1883;
  static const int mqttWsPort = 8000;
  static const String mqttWsUrl = 'ws://broker.hivemq.com/mqtt';
  static const String mqttDefaultTopic = 'kampus/demo/sensor01';
}
