import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/app.dart';

void main() {
  testWidgets('App renders trip search screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BusTicketApp());
    await tester.pumpAndSettle();

    expect(find.text('Search Trips'), findsOneWidget);
    expect(find.text('Plan your ride'), findsOneWidget);
    expect(find.text('Search trips'), findsOneWidget);
  });
}
