import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/comparar_produtos_provider.dart';
import '../models/produto.dart';
import '../models/analise.dart';
import '../providers/analise_provider.dart';

class AdicionarProdutosDialog extends StatefulWidget {
  final List<Produto> produtosAtuais;
  final String mercadoSelecionado;

  AdicionarProdutosDialog({
    required this.produtosAtuais,
    required this.mercadoSelecionado,
  });

  @override
  _AdicionarProdutosDialogState createState() => _AdicionarProdutosDialogState();
}

class _AdicionarProdutosDialogState extends State<AdicionarProdutosDialog> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Produto> todosProdutos = [];
  List<Produto> produtosDisponiveis = [];
  List<Produto> produtosSelecionados = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    print('\nIniciando AdicionarProdutosDialog');
    print('- Produtos atuais: ${widget.produtosAtuais.length}');
    _carregarTodosProdutos();
  }

  Future<void> _carregarTodosProdutos() async {
    try {
      setState(() => isLoading = true);
      
      // Carregar todos os produtos do Firestore
      QuerySnapshot snapshot = await _firestore.collection('produtos').get();
      todosProdutos = snapshot.docs.map((doc) => Produto.fromFirestore(doc)).toList();

      // Filtrar os produtos que **ainda não foram adicionados** à lista atual (produtosAtuais)
      produtosDisponiveis = todosProdutos.where((produto) {
        return !widget.produtosAtuais.any((p) => p.id == produto.id);
      }).toList();

      print('_carregarTodosProdutos - Produtos disponíveis para adicionar: ${produtosDisponiveis.length}');
      
      setState(() => isLoading = false);
    } catch (e) {
      print('Erro ao carregar produtos disponíveis: $e');
      setState(() {
        isLoading = false;
        produtosDisponiveis = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar produtos. Tente novamente.')),
      );
    }
  }

  void _toggleProdutoSelecionado(Produto produto) {
    setState(() {
      if (produtosSelecionados.contains(produto)) {
        produtosSelecionados.remove(produto);
      } else {
        produtosSelecionados.add(produto);
      }
    });
  }

  List<Produto> _filtrarProdutos() {
    if (searchQuery.isEmpty) return produtosDisponiveis;
    return produtosDisponiveis.where((produto) =>
      produto.nome.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final produtosFiltrados = _filtrarProdutos();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        width: MediaQuery.of(context).size.width * 0.9,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Adicionar Produtos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Pesquisar produtos...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) => setState(() => searchQuery = value),
              ),
              SizedBox(height: 16),
              Expanded(
                child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : produtosFiltrados.isEmpty
                    ? Center(child: Text('Nenhum produto disponível'))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: produtosFiltrados.length,
                        itemBuilder: (context, index) {
                          final produto = produtosFiltrados[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Checkbox(
                                value: produtosSelecionados.contains(produto),
                                onChanged: (bool? value) {
                                  if (value != null) {
                                    _toggleProdutoSelecionado(produto);
                                  }
                                },
                                activeColor: Colors.teal,
                              ),
                              title: Text(
                                produto.nome,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Unidade: ${produto.unidadeMedida}',
                                    style: TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (produto.kgPorUnidade != null)
                                    Text(
                                      'KG por unidade: ${produto.kgPorUnidade}',
                                      style: TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(height: 8),
              Divider(),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          '${produtosSelecionados.length} produtos selecionados',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancelar'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (produtosSelecionados.isEmpty) {
                            Navigator.of(context).pop();
                            return;
                          }

                          Navigator.of(context).pop(produtosSelecionados);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Produtos adicionados com sucesso!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'ADICIONAR',
                          style: TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class CompararProdutosScreen extends StatefulWidget {
  final List<Produto> produtosParaComparar;
  final String dataFinalizacao;

  CompararProdutosScreen({
    required this.produtosParaComparar,
    required this.dataFinalizacao,
  }) {
    print('CompararProdutosScreen construtor - Produtos recebidos: ${produtosParaComparar.length}');
  }

  @override
  _CompararProdutosScreenState createState() => _CompararProdutosScreenState();
}
class _CompararProdutosScreenState extends State<CompararProdutosScreen> {
  late List<Produto> produtos;
  late CompararProdutosProvider provider;
  String? selectedMarket;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isListaFinalizada = false;
  Map<String, Map<String, Map<String, dynamic>>> dadosTemporarios = {};

  @override
  void initState() {
    super.initState();
    print('\nIniciando CompararProdutosScreen');
    print('- Produtos recebidos: ${widget.produtosParaComparar.length}');
    
    produtos = widget.produtosParaComparar;
    provider = Provider.of<CompararProdutosProvider>(context, listen: false);

    _inicializarDadosTemporarios();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _inicializarDadosTemporarios() {
    for (var produto in produtos) {
      if (produto.mercados != null) {
        produto.mercados!.forEach((mercado, dados) {
          dadosTemporarios[mercado] ??= {};
          dadosTemporarios[mercado]![produto.id ?? 'temp_${produto.hashCode}'] = {
            'preco': dados['preco'],
            'marca': dados['marca'],
          };
        });
      }
    }
  }

  Future<void> _initializeData() async {
  final analiseProvider = Provider.of<AnaliseProvider>(context, listen: false);
  final compararProvider = Provider.of<CompararProdutosProvider>(context, listen: false);
  
  print('Iniciando carregamento de dados');
  
  try {
    // Carrega os mercados mantendo os existentes
    await analiseProvider.carregarMercados();
    
    print('Mercados carregados: ${analiseProvider.mercados.length}');
    
    // Se não houver mercado selecionado, seleciona o primeiro
    if (analiseProvider.selectedMercado == null && analiseProvider.mercados.isNotEmpty) {
      String mercadoInicial = analiseProvider.mercados.first;
      
      await analiseProvider.selecionarMercadoEmPosicao(
        0, 
        mercadoInicial, 
        unicaSelecao: true
      );
      
      setState(() {
        selectedMarket = mercadoInicial;
      });
      
      print('Mercado inicial selecionado: $mercadoInicial');
    } else {
      // Usa o mercado já selecionado
      setState(() {
        selectedMarket = analiseProvider.selectedMercado;
      });
    }

    // Carrega os produtos apropriados
    if (selectedMarket != null) {
      final selectedListaCompra = analiseProvider.selectedListaCompra;
      List<Produto> produtosParaComparar;
      
      if (selectedListaCompra != null && selectedListaCompra != AnaliseProvider.CARREGAR_TODOS_PRODUTOS) {
        produtosParaComparar = await analiseProvider.carregarProdutosDaLista(selectedListaCompra);
      } else {
        produtosParaComparar = await analiseProvider.carregarTodosProdutos();
      }
      
      provider.setProdutos(produtosParaComparar);
      await _loadProductsForMarket(selectedMarket!);
    }

    await _verificarListaFinalizada();
    
  } catch (e) {
    print('Erro ao inicializar dados: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados. Tente novamente.')),
      );
    }
  }
}


  Future<void> _loadProductsForMarket(String market) async {
  // Não carregar produtos novamente, apenas usar os produtos já carregados no provider
  setState(() {
    produtos = provider.produtos; // Produtos já carregados via AnaliseProvider
    
    for (var produto in produtos) {
      // Verifica se existem dados temporários para esse mercado
      var dadoTemp = dadosTemporarios[market]?[produto.id ?? 'temp_${produto.hashCode}'];
      
      // Assegura que o mapa 'mercados' está inicializado
      produto.mercados ??= {};
      
      // Atualiza as informações de preço e marca apenas para o mercado selecionado
      produto.mercados![market] = {
        'preco': dadoTemp?['preco'] ?? 0.0,  // Preço do mercado selecionado
        'marca': dadoTemp?['marca'] ?? '',   // Marca do mercado selecionado
      };
    }
  });
}

  void _atualizarDadosTemporarios() {
    if (selectedMarket == null) return;

    dadosTemporarios[selectedMarket!] ??= {};
    for (var produto in produtos) {
      String produtoId = produto.id ?? 'temp_${produto.hashCode}';
      if (dadosTemporarios[selectedMarket!] != null) {
        dadosTemporarios[selectedMarket!]![produtoId] = {
          'preco': produto.mercados?[selectedMarket!]?['preco'] ?? 0.0,
          'marca': produto.mercados?[selectedMarket!]?['marca'] ?? '',
        };
      }
    }
  }

  void _addProduto() async {
  await _mostrarDialogoAdicionarProduto();
}

  void _removeProduto(int index) {
  setState(() {
    produtos.removeAt(index);
    _atualizarDadosTemporarios(); // Atualiza os dados temporários
  });
}

  Future<void> _verificarListaFinalizada() async {
    var doc = await _firestore
        .collection('mercado_analise')
        .where('nome_mercado', isEqualTo: "${selectedMarket!} (${widget.dataFinalizacao})")
        .get();

    if (doc.docs.isNotEmpty) {
      setState(() {
        isListaFinalizada = doc.docs.first['finalizada'] ?? false;
      });
    }
  }

  bool _validarPrecos() {
    for (var produto in produtos) {
      if (produto.mercados?[selectedMarket!]?['preco'] == null || produto.mercados![selectedMarket!]!['preco'] == 0.0) {
        return false;
      }
    }
    return true;
  }

  // Nova implementação do diálogo de adicionar produto
  Future<void> _mostrarDialogoAdicionarProduto() async {
  final produtosSelecionados = await showDialog<List<Produto>>(
    context: context,
    builder: (context) => AdicionarProdutosDialog(
      produtosAtuais: produtos,
      mercadoSelecionado: selectedMarket!, // Garante que o mercado é passado corretamente
    ),
  );

  if (produtosSelecionados != null && produtosSelecionados.isNotEmpty) {
    setState(() {
      produtos.addAll(produtosSelecionados);
      _atualizarDadosTemporarios(); // Atualiza os dados temporários para o mercado selecionado
    });
  }
}

  Future<void> _finalizarTodosMercados() async {
    for (var mercado in dadosTemporarios.keys) {
      List<Produto> produtosMercado = produtos.map((p) {
        var produtoCopy = Produto(
          id: p.id,
          nome: p.nome,
          unidadeMedida: p.unidadeMedida,
          marcas: p.marcas,
        );
        produtoCopy.mercados = {mercado: p.mercados?[mercado] ?? {}};
        return produtoCopy;
      }).toList();

      await provider.finalizarLista(mercado, produtosMercado);
    }
    setState(() {
      dadosTemporarios.clear();
    });
  }

  Future<void> _finalizarMercadoAtual() async {
    await provider.finalizarLista(selectedMarket!, produtos);
    setState(() {
      dadosTemporarios.remove(selectedMarket);
    });
  }
Future<void> _salvarLista() async {
    if (_validarPrecos()) {
      final escolha = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Finalizar Lista'),
            content: Text('Deseja finalizar apenas o mercado atual ou todos os mercados?'),
            actions: <Widget>[
              TextButton(
                child: Text('Apenas o Atual'),
                onPressed: () {
                  Navigator.of(context).pop('atual');
                },
              ),
              TextButton(
                child: Text('Todos os Mercados'),
                onPressed: () {
                  Navigator.of(context).pop('todos');
                },
              ),
            ],
          );
        },
      );

      if (escolha != null) {
        if (escolha == 'atual') {
          await provider.finalizarLista(selectedMarket!, produtos);
          if (provider.mercadosSelecionados.isEmpty) {
            // Volta para /analise como era antes
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
            setState(() {
              selectedMarket = provider.mercadosSelecionados.first;
            });
            await _loadProductsForMarket(selectedMarket!);
          }
        } else {
          await provider.finalizarTodasListas(
            Map.fromEntries(provider.mercadosSelecionados.map((mercado) =>
              MapEntry(mercado, produtos.map((p) {
                var produtoCopy = Produto(
                  id: p.id,
                  nome: p.nome,
                  unidadeMedida: p.unidadeMedida,
                  marcas: p.marcas,
                );
                produtoCopy.mercados = {mercado: p.mercados?[mercado] ?? {}};
                return produtoCopy;
              }).toList())
            ))
          );
          // Volta para /analise como era antes
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lista(s) finalizada(s) e salva(s) com sucesso!')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, preencha todos os preços antes de finalizar.')),
      );
    }
  }

  void _cancelarELimpar() {
    setState(() {
      dadosTemporarios.clear();
    });
    // Volta para /analise como era antes
    Navigator.of(context).popUntil((route) => route.isFirst);
  }


  void _pesquisarProduto(String query) {
    // Implementar lógica de pesquisa se necessário
  }

  @override
Widget build(BuildContext context) {
  final analiseProvider = Provider.of<AnaliseProvider>(context, listen: false);

  if (selectedMarket == null) {
    return Center(child: CircularProgressIndicator());
  }

  final selectedListaCompra = analiseProvider.selectedListaCompra;

  return WillPopScope(
    onWillPop: () async {
      // Redireciona para a tela /compras ao pressionar o botão de voltar
      Navigator.of(context).pushReplacementNamed('/compras');
      return false; // Impede o comportamento padrão de voltar
    },
    child: Scaffold(
      appBar: _buildAppBar(),
      body: Consumer<CompararProdutosProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingProdutos || analiseProvider.isLoadingMercados) {
            return Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              _buildMarketSelector(),
              _buildTabelaHeader(),
              Expanded(
                child: ListView.builder(
                  itemCount: produtos.length,
                  itemBuilder: (context, index) {
                    return _buildProdutoRow(index, provider);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: selectedListaCompra != null && selectedListaCompra != "Carregar todos os produtos"
          ? FloatingActionButton(
              onPressed: _addProduto,
              child: Icon(Icons.add),
              backgroundColor: Colors.teal,
            )
          : null,
    ),
  );
}

  AppBar _buildAppBar() {
    return AppBar(
      title: Text('Comparar Produtos'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
      actions: [
        IconButton(
          icon: Icon(Icons.save),
          onPressed: _salvarLista,
          tooltip: 'Salvar a Lista',
        ),
        IconButton(
          icon: Icon(Icons.cancel),
          onPressed: _cancelarELimpar,
          tooltip: 'Cancelar',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildSearchField(),
        ),
      ),
    );
  }
Widget _buildSearchField() {
    return TextField(
      onChanged: _pesquisarProduto,
      decoration: InputDecoration(
        hintText: 'Pesquisar produto',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  Widget _buildTabelaHeader() {
    return Container(
      color: Colors.grey[200],
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildTabelaHeaderCell('Produto', flex: 3),
          _buildTabelaHeaderCell('Preço', flex: 2),
          _buildTabelaHeaderCell('Marca', flex: 2),
          SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTabelaHeaderCell(String title, {required int flex}) {
    return Flexible(
      flex: flex,
      fit: FlexFit.tight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildProdutoRow(int index, CompararProdutosProvider provider) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Flexible(
            flex: 3,
            fit: FlexFit.tight,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                produtos[index].nome,
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
          Flexible(
            flex: 2,
            fit: FlexFit.tight,
            child: _buildPrecoField(index),
          ),
          Flexible(
            flex: 2,
            fit: FlexFit.tight,
            child: _buildMarcaDropdown(index, provider),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeProduto(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrecoField(int index) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: TextFormField(
        initialValue: produtos[index].mercados?[selectedMarket]?['preco']?.toString() ?? '',
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          hintText: 'Preço',
          contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) {
          double? novoPreco = double.tryParse(value);
          if (novoPreco != null && selectedMarket != null) {
            setState(() {
              produtos[index].mercados ??= {};
              produtos[index].mercados![selectedMarket!] ??= {};
              produtos[index].mercados![selectedMarket!]['preco'] = novoPreco;
              _atualizarDadosTemporarios();
            });
          }
        },
      ),
    );
  }

  Widget _buildMarcaDropdown(int index, CompararProdutosProvider provider) {
    List<String> marcas = produtos[index].marcas ?? [];
    if (marcas.isEmpty) {
      marcas = ['GENERICA'];
    }

    marcas = marcas.toSet().toList();

    if (!marcas.contains('Adicionar nova marca')) {
      marcas.add('Adicionar nova marca');
    }

    String? selectedMarca = produtos[index].mercados?[selectedMarket!]?['marca'] as String?;

    if (selectedMarca != null && !marcas.contains(selectedMarca)) {
      selectedMarca = null;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: selectedMarca,
        hint: Text('Selecione a marca'),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        items: marcas.map((String marca) {
          return DropdownMenuItem<String>(
            value: marca,
            child: Text(marca),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue == 'Adicionar nova marca') {
            _mostrarDialogoNovaMarca(index, provider);
          } else {
            setState(() {
              produtos[index].mercados ??= {};
              produtos[index].mercados![selectedMarket!] ??= {};
              produtos[index].mercados![selectedMarket!]!['marca'] = newValue ?? '';
              _atualizarDadosTemporarios();
            });
          }
        },
      ),
    );
  }

  Widget _buildMarketSelector() {
  return Consumer2<AnaliseProvider, CompararProdutosProvider>(
    builder: (context, analiseProvider, compararProvider, child) {
      final mercadosDisponiveis = analiseProvider.mercados;
      
      print('Building market selector:');
      print('- Available markets: ${mercadosDisponiveis.length}');
      print('- Current selected market: ${analiseProvider.selectedMercado}');
      print('- Markets list: ${mercadosDisponiveis.join(", ")}');
      
      if (mercadosDisponiveis.isEmpty) {
        return Center(child: Text('Nenhum mercado disponível'));
      }

      // Atualiza selectedMarket com o valor do provider se necessário
      if (selectedMarket != analiseProvider.selectedMercado) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            selectedMarket = analiseProvider.selectedMercado;
          });
        });
      }

      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: DropdownButtonFormField<String>(
          value: selectedMarket ?? analiseProvider.selectedMercado,
          hint: Text('Selecione um mercado'),
          isExpanded: true,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: mercadosDisponiveis.map((String market) {
            return DropdownMenuItem<String>(
              value: market,
              child: Text(market),
            );
          }).toList(),
          onChanged: (String? newValue) async {
            if (newValue != null && newValue != selectedMarket) {
              print('Changing market to: $newValue');
              
              _atualizarDadosTemporarios();
              
              // Atualiza em ambos os providers
              await analiseProvider.selecionarMercadoEmPosicao(
                0, 
                newValue, 
                unicaSelecao: true
              );
              
              setState(() {
                selectedMarket = newValue;
              });
              
              await _loadProductsForMarket(newValue);
            }
          },
        ),
      );
    },
  );
}

  void _logEstadoAtual() {
    final analiseProvider = Provider.of<AnaliseProvider>(context, listen: false);
    print('\nEstado Atual:');
    print('- Mercado selecionado: $selectedMarket');
    print('- Mercados disponíveis: ${analiseProvider.mercados.length}');
    print('- Total de produtos: ${produtos.length}');
    print('- Dados temporários: ${dadosTemporarios.keys.length} mercados');
  }

  void _mostrarDialogoNovaMarca(int index, CompararProdutosProvider provider) {
    String novaMarca = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Adicionar Nova Marca'),
          content: TextField(
            onChanged: (value) => novaMarca = value,
            decoration: InputDecoration(hintText: 'Nome da marca'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (novaMarca.isNotEmpty) {
                  setState(() {
                    produtos[index].marcas ??= [];
                    produtos[index].marcas!.add(novaMarca.trim());
                    produtos[index].mercados ??= {};
                    produtos[index].mercados![selectedMarket!] ??= {};
                    produtos[index].mercados![selectedMarket!]!['marca'] = novaMarca.trim();
                    _atualizarDadosTemporarios();
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }
}