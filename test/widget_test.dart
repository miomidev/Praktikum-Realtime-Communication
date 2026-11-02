import 'package:flutter_test/flutter_test.dart';
import 'package:realtime_communication/main.dart';

void main() {
  testWidgets('RealtimeCommunicationApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RealtimeCommunicationApp());
    expect(find.textContaining('Praktikum 1 — REST API'), findsWidgets);
  });
}
