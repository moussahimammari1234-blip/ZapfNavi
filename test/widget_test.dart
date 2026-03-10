import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zapfnavi/main.dart';
import 'package:zapfnavi/providers/app_providers.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
          ChangeNotifierProvider(create: (_) => FuelProvider()),
          ChangeNotifierProvider(create: (_) => PremiumProvider()),
        ],
        child: const SpritzpreisApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
