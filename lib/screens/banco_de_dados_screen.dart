import 'package:flutter/material.dart';
import 'lista_de_compras_screen.dart';
import 'banco_dados_mercado_screen.dart'; // Nova importação

class BancoDeDadosScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Banco de Dados', style: TextStyle(fontSize: 20)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMenuOption(
              context,
              title: 'Banco de Dados - Mercado',
              icon: Icons.shopping_cart,
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BancoDadosMercadoScreen()),
              ),
            ),
            SizedBox(height: 16),
            _buildMenuOption(
              context,
              title: 'Lista de Compras',
              icon: Icons.list,
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ListaDeComprasScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 48, color: color),
              SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}