import 'package:flutter_test/flutter_test.dart';

import 'package:little_bloom/app/app.dart';

void main() {
  testWidgets('App starts and shows the app name', (tester) async {
    await tester.pumpWidget(const LittleBloomApp());
    expect(find.text('Little Bloom'), findsOneWidget);
  });
}
