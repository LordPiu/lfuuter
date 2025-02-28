import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/estoque_provider.dart';
import '../models/estoque.dart';

class GerenciamentoEstoqueScreen extends StatefulWidget {
  @override
  _GerenciamentoEstoqueScreenState createState() => _GerenciamentoEstoqueScreenState();
}

class _GerenciamentoEstoqueScreenState extends State<GerenciamentoEstoqueScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      Provider.of<EstoqueProvider>(context, listen: false).fetchEstoques()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gerenciamento de Estoque'),
      ),
      body: Consumer<EstoqueProvider>(
        builder: (context, estoqueProvider, child) {
          if (estoqueProvider.estoques.isEmpty) {
            return Center(child: Text('Nenhum item no estoque.'));
          }
          return ListView.builder(
            itemCount: estoqueProvider.estoques.length,
            itemBuilder: (context, index) {
              Estoque estoque = estoqueProvider.estoques[index];
              return ListTile(
                title: Text('Produto ID: ${estoque.produtoId}'),
                subtitle: Text('Quantidade: ${estoque.quantidadeAtual}, Nível Mínimo: ${estoque.nivelMinimo}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Provider.of<EstoqueProvider>(context, listen: false).addTestEstoque();
        },
        child: Icon(Icons.add),
        tooltip: 'Adicionar item de teste',
      ),
    );
  }
}