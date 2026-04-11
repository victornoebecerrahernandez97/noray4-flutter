import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noray4/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: Noray4App()));
    // MaterialApp.router es un MaterialApp — verificar que la app monta
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
