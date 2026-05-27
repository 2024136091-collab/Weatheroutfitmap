import 'package:flutter_test/flutter_test.dart';
import 'package:weather_style/main.dart';

void main() {
  testWidgets('WeatherStyleApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WeatherStyleApp());
    expect(find.text('OOTD'), findsNothing); // 로딩 중이므로 아직 표시 안 됨
  });
}
