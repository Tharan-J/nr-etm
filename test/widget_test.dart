import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nr_etm/app/app.dart';

void main() {
  testWidgets('App initializes with Splash Screen branding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: EtmApp()));

    expect(find.text('NAMMAROUTE ETM'), findsOneWidget);
    expect(find.text('Electronic Ticket Machine System'), findsOneWidget);
  });
}
