import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/produto_provider.dart';
import '../providers/compra_provider.dart';
import '../models/compra.dart';
import '../models/produto.dart';
import '../providers/categoria_provider.dart'; // Importado
import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ListaDeComprasScreen extends StatefulWidget {
  const ListaDeComprasScreen({Key? key}) : super(key: key);

  @override
  _ListaDeComprasScreenState createState() => _ListaDeComprasScreenState();
}

class _ListaDeComprasScreenState extends State<ListaDeComprasScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedProduto;
  String? _categoriaSelecionada;
  double? _quantidade;
  String? _nomeLista;
  String? _listaSelecionadaId;
  String _mensagemSucesso = '';
  static const Duration _duracaoMensagem = Duration(seconds: 2);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final TextEditingController _editQuantidadeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProdutoProvider>(context, listen: false).fetchProdutos();
      Provider.of<CategoriaProvider>(context, listen: false).fetchCategorias();
      Provider.of<CompraProvider>(context, listen: false).carregarListasCompras();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _editQuantidadeController.dispose();
    super.dispose();
  }

  void _limparMensagem() {
    Future.delayed(_duracaoMensagem, () {
      if (mounted) {
        setState(() => _mensagemSucesso = '');
      }
    });
  }

  @override
Widget build(BuildContext context) {
  final produtoProvider = Provider.of<ProdutoProvider>(context);
  final compraProvider = Provider.of<CompraProvider>(context);

  return GestureDetector(
    onTap: () {
      FocusScope.of(context).unfocus();
    },
    child: Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'Lista de Compras',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.teal,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: _buildSearchBar(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: 12.0,
          right: 12.0,
          top: 12.0,
          bottom: 12.0 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNomeECarregarListaSection(compraProvider),
            const SizedBox(height: 12),
            _buildAdicionarProdutoSection(produtoProvider, compraProvider),
            if (_mensagemSucesso.isNotEmpty) _buildMensagemSucesso(),
            const SizedBox(height: 12),
            _buildListaCompras(produtoProvider, compraProvider),
            const SizedBox(height: 20),
            Consumer<CompraProvider>(
              builder: (context, compraProvider, child) {
                return compraProvider.compras.isNotEmpty
                    ? _buildBotaoSalvar(compraProvider)
                    : SizedBox.shrink(); // Não mostra nada se a lista estiver vazia
              },
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildNomeECarregarListaSection(CompraProvider compraProvider) {
    return ExpansionTile(
      leading: Icon(Icons.settings, color: Colors.teal, size: 20),
      title: Text(
        'Configurações da Lista',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      children: [
        Column(
          children: [
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Nome da Lista',
                labelStyle: TextStyle(fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
              style: TextStyle(fontSize: 12),
              onChanged: (value) {
                setState(() {
                  _nomeLista = value.trim().isEmpty ? null : value.trim();
                });
              },
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('listas_compras').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }
                List<DropdownMenuItem<String>> listaItems = snapshot.data!.docs.map((doc) {
                  return DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text(doc['nome'], style: TextStyle(fontSize: 12)),
                  );
                }).toList();

                listaItems.insert(0, DropdownMenuItem<String>(
                  value: null,
                  child: Text('Selecionar uma lista', style: TextStyle(fontSize: 12)),
                ));

                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Carregar Lista',
                    labelStyle: TextStyle(fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                  value: _listaSelecionadaId,
                  items: listaItems,
                  onChanged: (value) async {
                    if (value != null) {
                      try {
                        await compraProvider.carregarComprasPorLista(value);
                        setState(() {
                          _listaSelecionadaId = value;
                          _nomeLista = snapshot.data!.docs.firstWhere((doc) => doc.id == value)['nome'];
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Lista "$_nomeLista" carregada!',
                              style: TextStyle(fontSize: 12),
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Erro ao carregar a lista: $e',
                              style: TextStyle(fontSize: 12),
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdicionarProdutoSection(ProdutoProvider produtoProvider, CompraProvider compraProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ExpansionTile(
          leading: Icon(Icons.add_shopping_cart, color: Colors.teal, size: 20),
          title: Text(
            'Adicionar Produto',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          initiallyExpanded: true,
          children: [
            _buildForm(produtoProvider, compraProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(ProdutoProvider produtoProvider, CompraProvider compraProvider) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Produto',
                    labelStyle: TextStyle(fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                  value: _selectedProduto,
                  items: _getProdutosFiltrados(produtoProvider, compraProvider)
                      .map((produto) => DropdownMenuItem<String>(
                            value: produto.id,
                            child: Text(
                              produto.nome,
                              style: TextStyle(fontSize: 12, color: Colors.black),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedProduto = value),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Selecione' : null,
                  style: TextStyle(fontSize: 12, color: Colors.black),
                  icon: Icon(Icons.arrow_drop_down, color: Colors.teal),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: Consumer<CategoriaProvider>(
                  builder: (context, categoriaProvider, child) {
                    return DropdownButtonFormField<String?>(
                      decoration: InputDecoration(
                        labelText: 'Categoria',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      ),
                      value: _categoriaSelecionada,
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos', style: TextStyle(fontSize: 12)),
                        ),
                        ...categoriaProvider.categorias.map((categoria) {
                          return DropdownMenuItem<String?>(
                            value: categoria.id,
                            child: Text(
                              categoria.nome,
                              style: TextStyle(fontSize: 12, color: Colors.black),
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _categoriaSelecionada = value;
                          _selectedProduto = null;
                        });
                      },
                      style: TextStyle(fontSize: 12, color: Colors.black),
                      icon: Icon(Icons.arrow_drop_down, color: Colors.teal),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Quantidade',
              labelStyle: TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontSize: 12),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Insira';
              }
              if (double.tryParse(value) == null) {
                return 'Num';
              }
              return null;
            },
            onSaved: (value) => _quantidade = double.tryParse(value!),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  _adicionarProduto(context, produtoProvider, compraProvider);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: Icon(Icons.add, size: 16),
              label: Text(
                'Adicionar',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaCompras(ProdutoProvider produtoProvider, CompraProvider compraProvider) {
    final listaFiltrada = compraProvider.compras.where((compra) {
      final produto = produtoProvider.produtos.firstWhereOrNull(
        (p) => p.id == compra.produtoId,
      ) ?? Produto(id: '0', nome: 'Produto Não Encontrado', unidadeMedida: 'unidade');
      return produto.nome.toLowerCase().contains(_searchQuery);
    }).toList();

    return listaFiltrada.isEmpty
        ? Center(
            child: Text(
              'Nenhum produto na lista.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          )
        : ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: listaFiltrada.length,
            itemBuilder: (context, index) {
              final compra = listaFiltrada[index];
              final produto = produtoProvider.produtos.firstWhereOrNull(
                (produto) => produto.id == compra.produtoId,
              ) ?? Produto(id: '0', nome: 'Produto Não Encontrado', unidadeMedida: 'unidade');
              return Card(
                elevation: 1,
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  title: Text(
                    produto.nome,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatarQuantidadeDetalhada(compra.quantidade, produto),
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                      if (produto.unidadeMedida == 'kg' && produto.kgPorUnidade != null)
                        Text(
                          'Este produto tem ${produto.kgPorUnidade} kg por unidade',
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue.shade600, size: 16),
                        onPressed: () => _editarQuantidade(context, compraProvider, compra, produto),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red.shade600, size: 16),
                        onPressed: () => _removerProduto(context, compraProvider, compra),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildBotaoSalvar(CompraProvider compraProvider) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: () async {
        try {
          await compraProvider.salvarOuAtualizarLista(
            compraProvider.compras,
            nome: _nomeLista,
          );
          setState(() {
            _mensagemSucesso = 'Lista salva com sucesso!';
            _nomeLista = null;
            _listaSelecionadaId = null;
            _searchController.clear();
            _searchQuery = '';
          });
          compraProvider.limparListaCompras();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lista salva com sucesso!',
                style: TextStyle(fontSize: 12),
              ),
              duration: Duration(seconds: 2),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erro ao salvar a lista: $e',
                style: TextStyle(fontSize: 12),
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
        _limparMensagem();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        'Salvar Lista',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

  void _adicionarProduto(BuildContext context, ProdutoProvider produtoProvider, CompraProvider compraProvider) {
    final produtoSelecionado = produtoProvider.produtos.firstWhere(
      (produto) => produto.id == _selectedProduto,
      orElse: () => Produto(id: '0', nome: '', unidadeMedida: 'unidade'),
    );

    if (produtoSelecionado.id != '0') {
      final produtoExistente = compraProvider.compras.firstWhereOrNull(
        (compra) => compra.produtoId == produtoSelecionado.id,
      );

      if (produtoExistente != null) {
        final novaQuantidade = produtoExistente.quantidade + _quantidade!;
        final compraAtualizada = produtoExistente.copyWith(quantidade: novaQuantidade);
        compraProvider.atualizarCompra(compraAtualizada);
        setState(() => _mensagemSucesso = 'Quantidade do produto atualizada');
      } else {
        final novaCompra = Compra(
          produtoId: produtoSelecionado.id ?? '',
          nome: produtoSelecionado.nome,
          quantidade: _quantidade!,
          data: DateTime.now(),
          unidadeMedida: produtoSelecionado.unidadeMedida,
          kgPorUnidade: produtoSelecionado.kgPorUnidade,
        );
        compraProvider.addCompraTemporaria(novaCompra);
        setState(() => _mensagemSucesso = 'Produto adicionado com sucesso');
      }

      _formKey.currentState!.reset();
      setState(() => _selectedProduto = null);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mensagemSucesso,
            style: TextStyle(fontSize: 12),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
    _limparMensagem();
  }

  void _editarQuantidade(BuildContext context, CompraProvider compraProvider, Compra compra, Produto produto) async {
    _editQuantidadeController.text = compra.quantidade % 1 == 0
        ? compra.quantidade.toStringAsFixed(0)
        : compra.quantidade.toString();

    final novaQuantidade = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Editar Quantidade',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _editQuantidadeController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: "Nova quantidade",
                  suffixText: produto.unidadeMedida == 'kg' ? 'kg' : 'unidades',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: TextStyle(fontSize: 12),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              if (produto.unidadeMedida == 'unidade' && produto.kgPorUnidade != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Equivalente a ${_calcularEquivalenteKg(_editQuantidadeController.text, produto)} kg',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 12),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'Salvar',
                style: TextStyle(fontSize: 12, color: Colors.teal),
              ),
              onPressed: () => Navigator.of(context).pop(_editQuantidadeController.text),
            ),
          ],
        );
      },
    );

    if (novaQuantidade != null && novaQuantidade.isNotEmpty) {
      final novaQuantidadeDouble = double.tryParse(novaQuantidade);
      if (novaQuantidadeDouble != null) {
        try {
          final novaCompra = compra.copyWith(quantidade: novaQuantidadeDouble);
          await compraProvider.atualizarCompra(novaCompra);

          setState(() {
            final index = compraProvider.compras.indexWhere((c) => c.id == compra.id);
            if (index != -1) {
              compraProvider.compras[index] = novaCompra;
            }
            _mensagemSucesso = 'Quantidade atualizada';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Quantidade atualizada',
                style: TextStyle(fontSize: 12),
              ),
              duration: Duration(seconds: 2),
            ),
          );
        } catch (e) {
          setState(() => _mensagemSucesso = 'Erro ao atualizar');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erro ao atualizar: $e',
                style: TextStyle(fontSize: 12),
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() => _mensagemSucesso = 'Quantidade inválida');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Quantidade inválida',
              style: TextStyle(fontSize: 12),
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
    _limparMensagem();
  }

  String _calcularEquivalenteKg(String quantidade, Produto produto) {
    if (produto.kgPorUnidade == null) return '0';
    double quantidadeDouble = double.tryParse(quantidade) ?? 0;
    return (quantidadeDouble * produto.kgPorUnidade!).toStringAsFixed(2);
  }

  void _removerProduto(BuildContext context, CompraProvider compraProvider, Compra compra) async {
    try {
      await compraProvider.removerCompra(compra);
      setState(() {
        _mensagemSucesso = 'Produto removido';
        _selectedProduto = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Produto removido',
            style: TextStyle(fontSize: 12),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() => _mensagemSucesso = 'Erro ao remover');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao remover: $e',
            style: TextStyle(fontSize: 12),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
    _limparMensagem();
  }

  String _formatarQuantidadeDetalhada(double quantidade, Produto produto) {
    if (produto.unidadeMedida == 'kg') {
      return '${quantidade.toStringAsFixed(0)} kg';
    } else if (produto.unidadeMedida == 'unidade') {
      String quantidadeFormatada = quantidade.toStringAsFixed(0);
      if (produto.kgPorUnidade != null && produto.kgPorUnidade! > 0) {
        double kgTotal = quantidade * produto.kgPorUnidade!;
        return '$quantidadeFormatada un (${kgTotal.toStringAsFixed(2)} kg)';
      } else {
        return '$quantidadeFormatada un';
      }
    } else {
      return quantidade.toStringAsFixed(0);
    }
  }

  Widget _buildMensagemSucesso() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Text(
        _mensagemSucesso,
        style: TextStyle(color: Colors.green.shade800, fontSize: 12),
      ),
    );
  }

  List<Produto> _getProdutosFiltrados(ProdutoProvider produtoProvider, CompraProvider compraProvider) {
    Set<String> produtosAdicionadosIds = compraProvider.compras.map((compra) => compra.produtoId).toSet();

    return produtoProvider.produtos.where((produto) {
      bool produtoJaAdicionado = produtosAdicionadosIds.contains(produto.id);

      final categoriaMatch = _categoriaSelecionada == null || produto.categoriaId == _categoriaSelecionada;
      final pesquisaMatch = _searchQuery.isEmpty || produto.nome.toLowerCase().contains(_searchQuery.toLowerCase());

      return !produtoJaAdicionado && categoriaMatch && pesquisaMatch;
    }).toList();
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Pesquisar Produto',
        prefixIcon: Icon(Icons.search, size: 16),
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
      style: TextStyle(fontSize: 12),
      onChanged: (value) {
        setState(() {
          _searchQuery = value.trim().toLowerCase();
        });
      },
    );
  }
}