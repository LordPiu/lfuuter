import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class NotificacoesPersonalizadasScreen extends StatefulWidget {
  @override
  _NotificacoesPersonalizadasScreenState createState() => _NotificacoesPersonalizadasScreenState();
}

class _NotificacoesPersonalizadasScreenState extends State<NotificacoesPersonalizadasScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;  // Use .instance aqui
  List<Map<String, dynamic>> _notificacoes = [];
  
  @override
  void initState() {
    super.initState();
    _carregarNotificacoes();
  }

  Future<void> _carregarNotificacoes() async {
    final notificacoes = await _databaseHelper.obterNotificacoesPersonalizadas();
    setState(() {
      _notificacoes = notificacoes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notificações Personalizadas'),
      ),
      body: ListView.builder(
        itemCount: _notificacoes.length,
        itemBuilder: (context, index) {
          final notificacao = _notificacoes[index];
          return ListTile(
            title: Text('Produto ID: ${notificacao['produto_id']}'),
            subtitle: Text('Preço Referência: R\$${notificacao['preco_referencia']} - Preço Alvo: R\$${notificacao['preco_alvo']}'),
            trailing: Switch(
              value: notificacao['ativa'] == 1,
              onChanged: (bool value) {
                // Atualizar o status da notificação no banco de dados
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarDialogoCriarNotificacao(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _mostrarDialogoCriarNotificacao(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int? produtoId;
        double? precoReferencia;
        double? precoAlvo;

        return AlertDialog(
          title: Text('Criar Notificação Personalizada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'ID do Produto'),
                keyboardType: TextInputType.number,
                onChanged: (value) => produtoId = int.tryParse(value),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Preço de Referência'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) => precoReferencia = double.tryParse(value),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Preço Alvo'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) => precoAlvo = double.tryParse(value),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Salvar'),
              onPressed: () async {
                if (produtoId != null && precoReferencia != null && precoAlvo != null) {
                  await _databaseHelper.inserirNotificacaoPersonalizada({
                    'produto_id': produtoId,
                    'preco_referencia': precoReferencia,
                    'preco_alvo': precoAlvo,
                    'ativa': 1,
                  });
                  Navigator.of(context).pop();
                  _carregarNotificacoes();
                }
              },
            ),
          ],
        );
      },
    );
  }
}

