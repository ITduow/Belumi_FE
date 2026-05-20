import 'package:belumi_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Belumi app configures material shell', (
    WidgetTester tester,
  ) async {
    const app = BelumiApp();
    expect(app, isA<BelumiApp>());
  });
}
