import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mercado_provider.dart';
import '../providers/compra_provider.dart';
import '../providers/produto_provider.dart';
import '../models/mercado.dart';

class MercadoScreen extends StatefulWidget {
  @override
  _MercadoScreenState createState() => _MercadoScreenState();
}

class _MercadoScreenState extends State<MercadoScreen> {
  int? _selectedListaId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<CompraProvider>(context, listen: false).carregarListasCompras();
    });
  }

  @override
  Widget build(BuildContext context) {
    final compraProvider = Provider.of<CompraProvider>(context);
    final mercadoProvider = Provider.of<MercadoProvider>(context);
    final produtoProvider = Provider.of<ProdutoProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mercado', style: TextStyle(fontSize: 20)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Selecione uma lista',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedListaId,
                  items: compraProvider.listasCompras.map((lista) {
                    return DropdownMenuItem<int>(
                      value: lista['id'] as int,
                      child: Text(lista['nome'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedListaId = value;
                    });
                  },
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _selectedListaId == null || _isLoading
                      ? null
                      : () async {
                          setState(() {
                            _isLoading = true;
                          });
                          await mercadoProvider.carregarMercadoPorLista(_selectedListaId!);
                          setState(() {
                            _isLoading = false;
                          });
                        },
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Text('Carregar Lista'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _selectedListaId == null
                    ? Center(child: Text('Selecione uma lista e clique em Carregar Lista'))
                    : Consumer<MercadoProvider>(
                        builder: (context, mercadoProvider, child) {
                          if (mercadoProvider.mercados.isEmpty) {
                            return Center(child: Text('Nenhum produto disponível nesta lista.'));
                          }
                          double valorTotal = mercadoProvider.calcularValorTotal();
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Valor Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text('R\$ ${valorTotal.toStringAsFixed(2)}', style: TextStyle( fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: mercadoProvider.mercados.length,
                                    itemBuilder: (context, index) {
                                      final mercado = mercadoProvider.mercados[index];

                                      // Certificando que o valor total do produto seja calculado corretamente
                                      double valorTotalProduto = mercado.quantidade * mercado.valorUnidade;

                                      // Atualizando o valor total do produto no provider
                                      mercadoProvider.atualizarValorTotalProduto(mercado.id!, valorTotalProduto);

                                      return Card(
                                        elevation: 2,
                                        margin: EdgeInsets.only(bottom: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        child: Padding(
                                          padding: EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                mercado.nome,
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                              SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text('${mercado.quantidade} ${mercado.unidade}', style: TextStyle(fontSize: 14)),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Expanded(
                                                    child: TextField(
                                                      decoration: InputDecoration(
                                                        labelText: 'Quantidade comprada',
                                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                      ),
                                                      keyboardType: TextInputType.number,
                                                      style: TextStyle(fontSize: 14),
                                                      onChanged: (value) {
                                                        mercadoProvider.atualizarQuantidade(mercado.id!, double.tryParse(value) ?? 0);
                                                        // Atualizando o valor total do produto no provider
                                                        mercadoProvider.atualizarValorTotalProduto(mercado.id!, mercado.quantidade * mercado.valorUnidade);
                                                      },
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Expanded(
                                                    child: TextField(
                                                      decoration: InputDecoration(
                                                        labelText: 'Preço',
                                                        prefixText: 'R\$ ',
                                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                      ),
                                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                      style: TextStyle(fontSize: 14),
                                                      onChanged: (value) {
                                                        mercadoProvider.atualizarPreco(mercado.id!, double.tryParse(value) ?? 0);
                                                        // Atualizando o valor total do produto no provider
                                                        mercadoProvider.atualizarValorTotalProduto(mercado.id!, mercado.quantidade * mercado.valorUnidade);
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8),
                                              Align(
                                                alignment: Alignment.centerRight,
                                                child: Text(
                                                  'R\$ ${valorTotalProduto.toStringAsFixed(2)}', // Exibindo valor total do produto calculado
                                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () async {
                                    await mercadoProvider.salvarAlteracoes();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Alterações salvas com sucesso!')),
                                    );
                                  },
                                  child: Text('Salvar Alterações'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size(double.infinity, 50),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}