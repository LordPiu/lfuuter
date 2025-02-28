// screens/no_mercado_screen.dart

import 'package:flutter/material.dart';

class NoMercadoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('No Mercado'),
      ),
      body: Center(
        child: Text(
          'Função em Desenvolvimento',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}