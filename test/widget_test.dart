// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app_traducctorpantallas/main.dart';

void main() {
  testWidgets('App inicializa correctamente', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TraductorFlotanteApp());

    // Verifica que la pantalla principal se carga
    expect(find.text('🌐 Traductor Flotante'), findsOneWidget);
    
    // Verifica que los botones principales existen
    expect(find.text('Funciones Principales'), findsOneWidget);
  });
}
