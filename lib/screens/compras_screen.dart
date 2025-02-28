import 'package:flutter/material.dart';

class ComprasScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compras'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: <Widget>[
            MenuButton(
              icon: Icons.shopping_cart,
              label: 'Lista de Compras',
              onPressed: () => Navigator.pushNamed(context, '/lista_compras'),
            ),
            MenuButton(
              icon: Icons.store,
              label: 'Mercado',
              onPressed: () => Navigator.pushNamed(context, '/selecionar_lista_mercado'),
            ),
            MenuButton(
              icon: Icons.refresh,
              label: 'Atualizar Produto',
              onPressed: () => Navigator.pushNamed(context, '/tabela_produtos'),
            ),  // Botão de navegação para MarcaScreen
            MenuButton(
              icon: Icons.branding_watermark,
              label: 'Gerenciar Marcas',
              onPressed: () => Navigator.pushNamed(context, '/marca'),
            ),
            MenuButton(
              icon: Icons.branding_watermark,
              label: 'ANALISE',
              onPressed: () => Navigator.pushNamed(context, '/analise'),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  MenuButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48.0, color: Colors.black),
              SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}