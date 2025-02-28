// lib/screens/analise_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analise_provider.dart';
import 'comparar_produtos_screen.dart';
import '../providers/comparar_produtos_provider.dart';
import '../models/produto.dart';

class AnaliseScreen extends StatefulWidget {
  @override
  _AnaliseScreenState createState() => _AnaliseScreenState();
}

class _AnaliseScreenState extends State<AnaliseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AnaliseProvider>(context, listen: false);
      provider.carregarMercados();
      provider.carregarListasCompras();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _navegarParaFuturaTela(List<Produto> produtosParaComparar) {
    String dataFinalizacao =
        "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompararProdutosScreen(
          produtosParaComparar: produtosParaComparar,
          dataFinalizacao: dataFinalizacao,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Análise',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
          unselectedLabelStyle:
              TextStyle(fontSize: 10, fontWeight: FontWeight.w300),
          indicatorColor: Colors.teal,
          labelColor: Colors.teal,
          unselectedLabelColor: Colors.black54,
          tabs: [
            Tab(text: 'CRIAR ANÁLISE'),
            Tab(text: 'EM CONSTRUÇÃO'),
            Tab(text: 'EM CONSTRUÇÃO'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCriarAnaliseTab(),
          Center(child: Text('Em construção')),
          Center(child: Text('Em construção')),
        ],
      ),
    );
  }

  Widget _buildCriarAnaliseTab() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _toggleExpand,
                    child: Text(
                      'CRIAR UMA NOVA ANÁLISE',
                      style: TextStyle(fontSize: 11, color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.teal, width: 2),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  if (_isExpanded) _buildNovaAnaliseForm(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNovaAnaliseForm() {
  return Consumer<AnaliseProvider>(
    builder: (context, provider, child) {
      return Column(
        children: [
          _buildMercadosDropdowns(provider),
          _buildListasDeComprasDropdown(provider),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              if (provider.selectedMercados.isEmpty || provider.selectedListaCompra == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Selecione pelo menos um mercado e uma lista de compras ou todos os produtos.',
                    ),
                  ),
                );
                return;
              }

              // Pegar o provider de comparação
              final compararProdutosProvider = Provider.of<CompararProdutosProvider>(context, listen: false);

              // **Limpar todos os dados antigos antes de carregar novos produtos**
              compararProdutosProvider.limparDados();

              // Carregar os produtos apropriados
              List<Produto> produtosParaComparar;

              print('Carregando lista: ${provider.selectedListaCompra}');

              if (provider.selectedListaCompra == AnaliseProvider.CARREGAR_TODOS_PRODUTOS) {
                // Carregar todos os produtos
                print('Carregando todos os produtos');
                produtosParaComparar = await provider.carregarTodosProdutos();
              } else {
                // Carregar produtos da lista de compras específica
                print('Carregando produtos da lista específica');
                produtosParaComparar = await provider.carregarProdutosDaLista(provider.selectedListaCompra!);
              }

              print('Total de produtos carregados: ${produtosParaComparar.length}');

              // Configurar os dados no provider de comparação de produtos
              compararProdutosProvider.setProdutos(produtosParaComparar);
              
              // Filtrar e garantir que apenas os mercados selecionados sejam considerados
              List<String> mercadosFiltrados = provider.selectedMercados
                  .where((m) => m != null && m!.isNotEmpty) // Filtrar mercados válidos
                  .cast<String>() // Garante que são strings
                  .toList();
              
              if (mercadosFiltrados.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Selecione pelo menos um mercado válido.'),
                  ),
                );
                return;
              }

              print('Mercados selecionados: ${mercadosFiltrados.length}');
              compararProdutosProvider.setMercadosSelecionados(mercadosFiltrados);

              // Preparar data de finalização
              String dataFinalizacao = "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";

              // Navegar para a tela de comparação
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompararProdutosScreen(
                    produtosParaComparar: produtosParaComparar,
                    dataFinalizacao: dataFinalizacao,
                  ),
                ),
              );
            },
            child: Text('IR', style: TextStyle(fontSize: 11, color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.teal, width: 2),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      );
    },
  );
}

  Widget _buildMercadosDropdowns(AnaliseProvider provider) {
    return Card(
      margin: EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NOME DO MERCADO',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            SizedBox(height: 6),
            provider.isLoadingMercados
                ? Center(child: CircularProgressIndicator())
                : Column(
                    children: _buildDynamicDropdowns(provider),
                  ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDynamicDropdowns(AnaliseProvider provider) {
    List<Widget> dropdowns = [];
    int maxDropdowns = 4;

    for (int i = 0; i < maxDropdowns; i++) {
      if (i == 0 || (provider.selectedMercados.length > i - 1 && provider.selectedMercados[i - 1] != null)) {
        dropdowns.add(
          Column(
            children: [
              DropdownButtonFormField<String>(
                value: provider.selectedMercados.length > i
                    ? provider.selectedMercados[i]
                    : null,
                hint: Text(
                  'SELECIONE MERCADO ${i + 1}',
                  style: TextStyle(fontSize: 9, color: Colors.black54),
                ),
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                items: provider.mercados.map((String mercado) {
                  return DropdownMenuItem<String>(
                    value: mercado,
                    child: Text(mercado, style: TextStyle(fontSize: 10)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  print("Mercado ${i + 1} selecionado: $newValue");
                  provider.selecionarMercadoEmPosicao(i, newValue);
                },
              ),
              SizedBox(height: 8),
            ],
          ),
        );
      }
    }

    return dropdowns;
  }

  Widget _buildListasDeComprasDropdown(AnaliseProvider provider) {
    return Card(
      margin: EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LISTAS DE COMPRAS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            SizedBox(height: 6),
            provider.isLoadingListasCompras
                ? Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: provider.selectedListaCompra,
                    hint: Text('SELECIONE LISTA DE COMPRAS',
                        style: TextStyle(fontSize: 9, color: Colors.black54)),
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    items: provider.listasComprasComOpcaoTodos.map((String lista) {
                      return DropdownMenuItem<String>(
                        value: lista,
                        child: Text(lista, style: TextStyle(fontSize: 10)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      print("Nova lista de compras selecionada: $newValue");
                      provider.selecionarListaCompra(newValue);
                    },
                  ),
          ],
        ),
      ),
    );
  }
}