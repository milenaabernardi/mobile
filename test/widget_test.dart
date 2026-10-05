import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trabalho_pratico/main.dart';

void main() {
  testWidgets('Menu inferior mostra as 3 abas', (WidgetTester tester) async {
    await tester.pumpWidget(const CineDiarioApp());

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Buscar'), findsOneWidget);
    expect(find.text('Favoritos'), findsOneWidget);
  });

  testWidgets('Validação: busca vazia mostra erro', (WidgetTester tester) async {
    await tester.pumpWidget(const CineDiarioApp());

    // Vai para a aba Buscar
    await tester.tap(find.text('Buscar'));
    await tester.pump(const Duration(milliseconds: 500));

    // Toca no botão Buscar com o campo vazio
    await tester.tap(find.byKey(const Key('btn_buscar')));
    await tester.pump();

    expect(find.text('Digite o nome de um filme.'), findsOneWidget);
  });
}
