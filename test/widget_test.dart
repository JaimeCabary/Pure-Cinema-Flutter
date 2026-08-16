import 'package:flutter_test/flutter_test.dart';
import 'package:pure_cinema_flutter/screens/landing_screen.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App loads cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LandingScreen(),
      ),
    );
    expect(find.text('PURE CINEMA'), findsWidgets);
  });
}
