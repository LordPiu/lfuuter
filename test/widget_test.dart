// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:controle_de_estoque/main.dart';

void main() {
  testWidgets('Verifica se o Menu Principal é exibido corretamente',
      (WidgetTester tester) async {
    // Construir o aplicativo e disparar um frame.
    await tester.pumpWidget(const ControleDeEstoqueApp());

    // Verificar se o título do app está presente.
    expect(find.text('Controle de Estoque'), findsOneWidget);

    // Verificar se os botões principais estão presentes.
    expect(find.text('Lista de Compras'), findsOneWidget);
    expect(find.text('No Mercado'), findsOneWidget);
    expect(find.text('Fechamento de Estoque'), findsOneWidget);
    expect(find.text('Tabela de Atualização'), findsOneWidget);
    expect(find.text('Tabela de Produtos'), findsOneWidget);
  });
}
