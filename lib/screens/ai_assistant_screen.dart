import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mercado_provider.dart';

class AIAssistantScreen extends StatefulWidget {
  @override
  _AIAssistantScreenState createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _questionController = TextEditingController();
  String _response = '';
  bool _isLoading = false;
  List<Map<String, dynamic>> _dadosMercado = [];

  @override
  void initState() {
    super.initState();
    _carregarDadosMercado();
  }

  Future<void> _carregarDadosMercado() async {
    setState(() => _isLoading = true);
    final mercadoProvider = Provider.of<MercadoProvider>(context, listen: false);
    try {
      _dadosMercado = await mercadoProvider.obterTodasListasFinalizadasMercado();
      print('Dados carregados: ${_dadosMercado.length} listas');
      print('Primeira lista: ${_dadosMercado.isNotEmpty ? _dadosMercado.first : "Nenhuma lista"}');
      setState(() => _isLoading = false);
    } catch (e) {
      print('Erro ao carregar dados do mercado: $e');
      setState(() {
        _isLoading = false;
        _response = "Erro ao carregar dados do mercado. Por favor, tente novamente.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mercadoProvider = Provider.of<MercadoProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Assistente IA'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _carregarDadosMercado,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                labelText: 'Faça uma pergunta sobre suas compras',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                if (_dadosMercado.isEmpty) {
                  setState(() => _response = "Não há dados de mercado disponíveis. Por favor, carregue os dados primeiro.");
                  return;
                }
                setState(() => _isLoading = true);
                final question = _questionController.text;
                try {
                  final response = await mercadoProvider.askAIAboutMercado(question);
                  setState(() {
                    _response = response;
                    _isLoading = false;
                  });
                } catch (e) {
                  setState(() {
                    _response = "Erro ao processar a pergunta: $e";
                    _isLoading = false;
                  });
                }
              },
              child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Perguntar'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue, // Mudança aqui
    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
  ),
),
            SizedBox(height: 20),
            Text('Resposta:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Expanded(
              child: SingleChildScrollView(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _response,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }
}