// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:queueless_app/main.dart';
import 'package:queueless_app/services/impl/dummy_auth_service.dart';
import 'package:queueless_app/services/impl/dummy_queue_service.dart';

void main() {
  testWidgets('QueueLess app boots (smoke test)', (WidgetTester tester) async {
    final app = QueueLessApp(
      authService: DummyAuthService(),
      queueService: DummyQueueService(),
    );

    await tester.pumpWidget(app);
    await tester.pump();

    expect(find.text('QueueLess'), findsWidgets);
  });
}
