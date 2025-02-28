import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/produto_provider.dart';
import '../providers/categoria_provider.dart';
import '../models/produto.dart';
import '../providers/nome_de_mercado_provider.dart';
import '../models/categoria.dart';
import '../models/nome_mercado.dart';

class TabelaDeProdutosScreen extends StatefulWidget {
  @override
  _TabelaDeProdutosScreenState createState() => _TabelaDeProdutosScreenState();
}

class _TabelaDeProdutosScreenState extends State<TabelaDeProdutosScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _produtoController = TextEditingController();
  final TextEditingController _kgPorUnidadeController = TextEditingController();
  final TextEditingController _nomeDeMercadoController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();

  String _mensagemSucessoNomeDeMercado = '';
  String _unidadeMedida = 'UNIDADE';
  String _mensagemSucesso = '';
  String _searchQuery = '';
  String _mensagemSucessoCategoria = '';

  late TabController _tabController;

  String? _categoriaSelecionada;
  String? _editCategoriaSelecionada;

  Map<String, TextEditingController> _quantidadeControllers = {};
  Map<String, TextEditingController> _precoControllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProdutoProvider>(context, listen: false).fetchProdutos();
    });
  }

  @override
  void dispose() {
    _produtoController.dispose();
    _kgPorUnidadeController.dispose();
    _nomeDeMercadoController.dispose();
    _searchController.dispose();
    _categoriaController.dispose();
    _tabController.dispose();
    _quantidadeControllers.values.forEach((controller) => controller.dispose());
    _precoControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Tabela de Produtos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 40,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Pesquisar',
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          unselectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w300),
          indicatorColor: Colors.teal,
          labelColor: Colors.teal,
          unselectedLabelColor: Colors.black54,
          tabs: [
            Tab(text: 'Tabela de Produto'),
            Tab(text: 'Nome de Mercado'),
            Tab(text: 'Categoria'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabelaProdutoTab(),
          _buildNomeDeMercadoTab(),
          _buildCategoriaTab(),
        ],
      ),
    );
  }

  Widget _buildTabelaProdutoTab() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _produtoController,
                    decoration: InputDecoration(
                      labelText: 'Nome do Produto',
                      labelStyle: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    ),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _unidadeMedida,
                    decoration: InputDecoration(
                      labelText: 'Unidade de Medida',
                      labelStyle: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    ),
                    items: ['UNIDADE', 'KG', 'KGPORUNIDADE'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _unidadeMedida = newValue!;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  Consumer<CategoriaProvider>(
                    builder: (context, categoriaProvider, child) {
                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Categoria',
                          labelStyle: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        ),
                        items: categoriaProvider.categorias.map((Categoria categoria) {
                          return DropdownMenuItem<String>(
                            value: categoria.id,
                            child: Text(categoria.nome),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _categoriaSelecionada = newValue;
                          });
                        },
                        value: _categoriaSelecionada,
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  if (_unidadeMedida == 'KGPORUNIDADE')
                    TextField(
                      controller: _kgPorUnidadeController,
                      decoration: InputDecoration(
                        labelText: 'Kg por Unidade',
                        labelStyle: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  if (_unidadeMedida == 'KGPORUNIDADE')
                    SizedBox(height: 16),
                  ElevatedButton(
                    child: Text('Adicionar Produto', style: TextStyle(fontSize: 14, color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.teal, width: 2),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      if (_produtoController.text.isNotEmpty) {
                        _adicionarProduto(context);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_mensagemSucesso.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: Colors.green.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    _mensagemSucesso,
                    style: TextStyle(color: Colors.green.shade800, fontSize: 13),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text('Produtos Cadastrados', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Consumer<ProdutoProvider>(
              builder: (context, produtoProvider, child) {
                List<Produto> produtosFiltrados = produtoProvider.produtos.where((produto) {
                  return produto.nome.toLowerCase().contains(_searchController.text.toLowerCase());
                }).toList();

                if (produtosFiltrados.isEmpty) {
                  return Center(child: Text('Nenhum produto encontrado.', style: TextStyle(fontSize: 14)));
                }

                return ListView.builder(
                  itemCount: produtosFiltrados.length,
                  itemBuilder: (context, index) {
                    Produto produto = produtosFiltrados[index];
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(produto.nome, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          '${produto.unidadeMedida}${produto.kgPorUnidade != null ? ' (${produto.kgPorUnidade} kg/unidade)' : ''}',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue.shade600, size: 20),
                              onPressed: () => _showEditDialog(context, produto),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red.shade600, size: 20),
                              onPressed: () => _confirmDelete(context, produto),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNomeDeMercadoTab() {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nome de Mercado',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _nomeDeMercadoController,
              decoration: InputDecoration(
                labelText: 'Nome do Mercado',
                labelStyle: TextStyle(fontSize: 13, color: Colors.grey[700]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              child: Text(
                'Salvar Nome de Mercado',
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.teal, width: 2),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _salvarNomeDeMercado(context),
            ),
            if (_mensagemSucessoNomeDeMercado.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Card(
                  color: Colors.green.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _mensagemSucessoNomeDeMercado,
                      style: TextStyle(color: Colors.green.shade800),
                    ),
                  ),
                ),
              ),
            SizedBox(height: 24),
            Text(
              'Nomes de Mercado Cadastrados',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Expanded(
              child: Consumer<NomeDeMercadoProvider>(
                builder: (context, provider, child) {
                  if (provider.nomesDeMercado.isEmpty) {
                    return Center(
                      child: Text(
                        'Nenhum nome de mercado cadastrado.',
                        style: TextStyle(fontSize: 14),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: provider.nomesDeMercado.length,
                    itemBuilder: (context, index) {
                      final nomeDeMercado = provider.nomesDeMercado[index];
                      return ListTile(
                        title: Text(
                          nomeDeMercado['nome'] as String,
                          style: TextStyle(fontSize: 14),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue.shade600, size: 20),
                              onPressed: () => _showEditNomeDeMercadoDialog(context, nomeDeMercado),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red.shade600, size: 20),
                              onPressed: () => _confirmDeleteNomeDeMercado(context, nomeDeMercado),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriaTab() {
    return Consumer<CategoriaProvider>(
      builder: (context, categoriaProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gerenciar Categorias', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              SizedBox(height: 16),
              TextField(
                controller: _categoriaController,
                decoration: InputDecoration(
                  labelText: 'Nome da Categoria',
                  labelStyle: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                child: Text('Adicionar Categoria', style: TextStyle(fontSize: 14, color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.teal, width: 2),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final nome = _categoriaController.text.trim();
                  if (nome.isEmpty) {
                    setState(() {
                      _mensagemSucessoCategoria = 'O nome da categoria não pode ser vazio.';
                    });
                    return;
                  }
                  await categoriaProvider.addCategoria(nome);
                  _categoriaController.clear();
                  setState(() {
                    _mensagemSucessoCategoria = 'Categoria adicionada com sucesso!';
                  });
                  Future.delayed(Duration(seconds: 3), () {
                    if (mounted) {
                      setState(() {
                        _mensagemSucessoCategoria = '';
                      });
                    }
                  });
                },
              ),
              if (_mensagemSucessoCategoria.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _mensagemSucessoCategoria,
                    style: TextStyle(color: Colors.green.shade800),
                  ),
                ),
              SizedBox(height: 24),
              Text('Categorias Cadastradas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Expanded(
                child: ListView.builder(
                  itemCount: categoriaProvider.categorias.length,
                  itemBuilder: (context, index) {
                    final categoria = categoriaProvider.categorias[index];
                    return ListTile(
                      leading: Icon(Icons.label, color: Colors.teal),
                      title: Text(categoria.nome, style: TextStyle(fontSize: 14)),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red.shade600, size: 20),
                        onPressed: () => _confirmDeleteCategoria(context, categoria.id!, categoria.nome, categoriaProvider),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteCategoria(BuildContext context, String id, String nome, CategoriaProvider categoriaProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir a categoria "$nome"?'),
        actions: [
          TextButton(
            child: Text('Cancelar', style: TextStyle(fontSize: 13)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Excluir', style: TextStyle(fontSize: 13)),
            onPressed: () async {
              await categoriaProvider.deleteCategoria(id);
              Navigator.of(context).pop();
              setState(() {
                _mensagemSucessoCategoria = 'Categoria excluída com sucesso!';
              });
              Future.delayed(Duration(seconds: 3), () {
                if (mounted) {
                  setState(() {
                    _mensagemSucessoCategoria = '';
                  });
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _salvarNomeDeMercado(BuildContext context) async {
    String nome = _nomeDeMercadoController.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, insira um nome de mercado.')),
      );
      return;
    }

    try {
      await Provider.of<NomeDeMercadoProvider>(context, listen: false).addNomeDeMercado(nome);
      setState(() {
        _mensagemSucessoNomeDeMercado = 'Nome de mercado salvo com sucesso!';
        _nomeDeMercadoController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _adicionarProduto(BuildContext context) async {
    final nome = _produtoController.text.trim();
    final produtoProvider = Provider.of<ProdutoProvider>(context, listen: false);

    if (produtoProvider.produtos.any((produto) => produto.nome.toLowerCase() == nome.toLowerCase())) {
      setState(() {
        _mensagemSucesso = 'Este produto já foi adicionado';
      });
      return;
    }

    try {
      double? kgPorUnidade;
      if (_unidadeMedida == 'KGPORUNIDADE' && _kgPorUnidadeController.text.isNotEmpty) {
        kgPorUnidade = double.tryParse(_kgPorUnidadeController.text);
        if (kgPorUnidade == null) {
          setState(() {
            _mensagemSucesso = 'Por favor, insira um valor válido para Kg por Unidade';
          });
          return;
        }
      }
      await produtoProvider.addProduto(
        nome,
        _unidadeMedida,
        categoriaId: _categoriaSelecionada,
        kgPorUnidade: kgPorUnidade,
      );
      _produtoController.clear();
      _kgPorUnidadeController.clear();
      setState(() {
        _mensagemSucesso = 'Produto adicionado com sucesso';
        _unidadeMedida = 'UNIDADE';
        _categoriaSelecionada = null;
      });
    } catch (e) {
      setState(() {
        _mensagemSucesso = 'Erro ao adicionar produto: $e';
      });
    }

    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _mensagemSucesso = '';
        });
      }
    });
  }

  void _confirmDeleteNomeDeMercado(BuildContext context, Map<String, dynamic> nomeDeMercado) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Deletar Nome de Mercado'),
        content: Text('Tem certeza que deseja deletar "${nomeDeMercado['nome']}"?'),
        actions: [
          TextButton(
            child: Text('Cancelar', style: TextStyle(fontSize: 13)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Deletar', style: TextStyle(fontSize: 13)),
            onPressed: () async {
              try {
                await Provider.of<NomeDeMercadoProvider>(context, listen: false)
                    .deleteNomeDeMercado(nomeDeMercado['id']);
                Navigator.of(context).pop();
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao deletar: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditNomeDeMercadoDialog(BuildContext context, Map<String, dynamic> nomeDeMercado) {
    final TextEditingController _editController = TextEditingController(text: nomeDeMercado['nome']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Nome de Mercado'),
        content: TextField(
          controller: _editController,
          decoration: InputDecoration(labelText: 'Nome do Mercado'),
        ),
        actions: [
          TextButton(
            child: Text('Cancelar', style: TextStyle(fontSize: 13)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Salvar', style: TextStyle(fontSize: 13)),
            onPressed: () async {
              String novoNome = _editController.text.trim();
              if (novoNome.isNotEmpty) {
                try {
                  await Provider.of<NomeDeMercadoProvider>(context, listen: false)
                      .updateNomeDeMercado(nomeDeMercado['id'], novoNome);
                  Navigator.of(context).pop();
                  setState(() {
                    _mensagemSucessoNomeDeMercado = 'Nome de mercado atualizado com sucesso';
                  });
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao atualizar: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Produto produto) {
  final TextEditingController _editController = TextEditingController(text: produto.nome);
  final TextEditingController _editKgPorUnidadeController = TextEditingController(
    text: produto.kgPorUnidade?.toString() ?? '',
  );
  String _editUnidadeMedida = produto.unidadeMedida;
  String? _editCategoriaSelecionada = produto.categoriaId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Editar Produto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _editController,
                  decoration: InputDecoration(
                    labelText: 'Nome do Produto',
                    labelStyle: TextStyle(fontSize: 13),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                SizedBox(height: 16),
                DropdownButton<String>(
                  value: _editUnidadeMedida,
                  items: ['UNIDADE', 'KG', 'KGPORUNIDADE'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setStateDialog(() {
                      _editUnidadeMedida = newValue!;
                    });
                  },
                ),
                SizedBox(height: 16),
                Consumer<CategoriaProvider>(
                  builder: (context, categoriaProvider, child) {
                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Categoria',
                        labelStyle: TextStyle(fontSize: 13),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      items: categoriaProvider.categorias.map((Categoria categoria) {
                        return DropdownMenuItem<String>(
                          value: categoria.id,
                          child: Text(categoria.nome),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setStateDialog(() {
                          _editCategoriaSelecionada = newValue;
                        });
                      },
                      value: _editCategoriaSelecionada,
                    );
                  },
                ),
                if (_editUnidadeMedida == 'KGPORUNIDADE')
                  SizedBox(height: 16),
                if (_editUnidadeMedida == 'KGPORUNIDADE')
                  TextField(
                    controller: _editKgPorUnidadeController,
                    decoration: InputDecoration(
                      labelText: 'Kg por Unidade',
                      labelStyle: TextStyle(fontSize: 13),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    keyboardType: TextInputType.number,
                  ),
              ],
            ),
          ),
          actions: [
          TextButton(
            child: Text('Cancelar', style: TextStyle(fontSize: 13)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Salvar', style: TextStyle(fontSize: 13)),
            onPressed: () async {
              if (_editController.text.isNotEmpty) {
                final produtoProvider = Provider.of<ProdutoProvider>(context, listen: false);
                double? kgPorUnidade;
                if (_editUnidadeMedida == 'KGPORUNIDADE' && _editKgPorUnidadeController.text.isNotEmpty) {
                  kgPorUnidade = double.tryParse(_editKgPorUnidadeController.text);
                }
                await produtoProvider.updateProduto(
                  produto.id!,
                  _editController.text,
                  _editUnidadeMedida,
                  novaCategoriaId: _editCategoriaSelecionada,
                  novoKgPorUnidade: kgPorUnidade,
                );
                Navigator.of(context).pop();
                setState(() {
                  _mensagemSucesso = 'Produto atualizado com sucesso';
                });
                Future.delayed(Duration(seconds: 3), () {
                  if (mounted) {
                    setState(() {
                      _mensagemSucesso = '';
                      });
                    }
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Produto produto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirmar Exclusão', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        content: Text('Tem certeza que deseja excluir o produto "${produto.nome}"?', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            child: Text('Cancelar', style: TextStyle(fontSize: 13)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Excluir', style: TextStyle(fontSize: 13)),
            onPressed: () async {
              final produtoProvider = Provider.of<ProdutoProvider>(context, listen: false);
              await produtoProvider.deleteProduto(produto.id!);
              Navigator.of(context).pop();
              setState(() {
                _mensagemSucesso = 'Produto excluído com sucesso';
              });
              Future.delayed(Duration(seconds: 3), () {
                if (mounted) {
                  setState(() {
                    _mensagemSucesso = '';
                  });
                }
              });
            },
          ),
        ],
      ),
    );
  }
}