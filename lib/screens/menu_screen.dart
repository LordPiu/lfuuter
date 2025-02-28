import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'banco_de_dados_screen.dart';
import 'ai_assistant_screen.dart';
import 'compras_screen.dart';
import '../providers/gasto_semanal_provider.dart';
import 'banco_dados_mercado_screen.dart';

class MenuScreen extends StatefulWidget {
  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _atualizarGastos();
    });
  }

  Future<void> _atualizarGastos() async {
    await Provider.of<GastoSemanalProvider>(context, listen: false).calcularGastos();
    setState(() {});
  }

  void _navegarParaBancoDadosMercado(BuildContext context, bool isGastoSemanal) {
    final gastoProvider = Provider.of<GastoSemanalProvider>(context, listen: false);
    DateTime now = DateTime.now();
    DateTime inicio, fim;

    if (isGastoSemanal) {
      inicio = now.subtract(Duration(days: now.weekday - 1));
      fim = inicio.add(Duration(days: 6));
    } else {
      inicio = now.subtract(Duration(days: now.weekday + 6));
      fim = inicio.add(Duration(days: 6));
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BancoDadosMercadoScreen(dataInicio: inicio, dataFim: fim),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tela Principal', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _atualizarGastos,
          ),
        ],
      ),
      body: Consumer<GastoSemanalProvider>(
        builder: (context, gastoProvider, child) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildGastoInfo(
                    'Gasto no mercado Semanal',
                    gastoProvider.gastoSemanal,
                    gastoProvider.gastoSemanaAnterior,
                    () => _navegarParaBancoDadosMercado(context, true),
                  ),
                  SizedBox(height: 16),
                  _buildGastoInfo(
                    'Gasto no mercado Semana Anterior',
                    gastoProvider.gastoSemanaAnterior,
                    null,
                    () => _navegarParaBancoDadosMercado(context, false),
                  ),
                  SizedBox(height: 32),
                  Text(
                    'MENUS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold, 
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  _buildMenuButtons(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGastoInfo(String title, double value, double? comparacao, VoidCallback onTap) {
    bool isAboveThreshold = false;
    if (comparacao != null && comparacao > 0) {
      double aumentoPercentual = ((value - comparacao) / comparacao) * 100;
      isAboveThreshold = aumentoPercentual > 15;
    }

    return Column(
      children: [
        Text(
          title, 
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold, 
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 50,
            width: 220,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.teal, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'R\$ ${value.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold, 
                  color: isAboveThreshold ? Colors.red : Colors.teal,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        MenuButton(
          icon: Icons.shopping_bag,
          label: 'COMPRAS',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ComprasScreen()),
          ),
        ),
        MenuButton(
          icon: Icons.storage,
          label: 'Banco de DADOS',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BancoDeDadosScreen()),
          ),
        ),
        MenuButton(
          icon: Icons.chat,
          label: 'Robozinho',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AIAssistantScreen()),
          ),
        ),
      ],
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
    return SizedBox(
      width: 100,
      height: 130,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon, 
                  size: 30.0,
                  color: Colors.teal,
                ),
                SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600, 
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}