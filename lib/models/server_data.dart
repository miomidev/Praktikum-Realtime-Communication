class ServerData {
  final int counter;
  final int value;
  final String timestamp;

  ServerData({
    required this.counter,
    required this.value,
    required this.timestamp,
  });

  factory ServerData.fromJson(Map<String, dynamic> json) {
    return ServerData(
      counter: json['counter'] is int
          ? json['counter'] as int
          : int.tryParse(json['counter']?.toString() ?? '0') ?? 0,
      value: json['value'] is int
          ? json['value'] as int
          : int.tryParse(json['value']?.toString() ?? '0') ?? 0,
      timestamp: json['timestamp']?.toString() ?? '-',
    );
  }

  Map<String, dynamic> toJson() => {
        'counter': counter,
        'value': value,
        'timestamp': timestamp,
      };

  @override
  String toString() {
    return 'Counter: $counter | Value: $value | Time: $timestamp';
  }
}

