import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nr_etm/app/app.dart';

void main() {
  testWidgets('App initializes with Splash Screen placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EtmApp(),
      ),
    );

    expect(find.text('Splash Screen'), findsNWidgets(2));
    expect(find.text('Spec Ref: Spec 09 §8.1'), findsOneWidget);
  });
}
