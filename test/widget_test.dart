// Basic widget test for GeoFieldMate app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geo_field_mate/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app launches (splash screen or login screen appears)
    // We just check that the app doesn't crash on startup
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
