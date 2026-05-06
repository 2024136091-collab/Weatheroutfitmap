import 'package:flutter_test/flutter_test.dart';
import 'package:weather_codi/main.dart';
import 'package:weather_codi/providers/auth_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final authProvider = AuthProvider();
    await tester.pumpWidget(MyApp(authProvider: authProvider));
    await tester.pump();
  });
}