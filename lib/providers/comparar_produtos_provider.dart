import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/produto.dart';
import '../models/analise.dart';
import 'analise_provider.dart';

class CompararProdutosProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnaliseProvider? _analiseProvider;

  List<Produto> _produtos = [];
  List<String> _mercadosSelecionados = [];
  Map<String, List<Produto>> _produtosPorMercado = {};
  Map<String, Map<String, AnaliseProduto>> _analisesPorMercado = {};
  bool _isLoadingProdutos = false;

  CompararProdutosProvider([this._analiseProvider]) {
    if (_analiseProvider != null) {
      print('Inicializando com AnaliseProvider');
    }
  }

  // Getters
  List<Produto> get produtos => _produtos;
  List<String> get mercadosSelecionados => _mercadosSelecionados;
  bool get isLoadingProdutos => _isLoadingProdutos;
  String? get mercadoAtual => _analiseProvider?.selectedMercado;
  List<String> get mercadosDisponiveis => _analiseProvider?.mercados ?? [];

  // Função para limpar dados
  void limparDados() {
    _produtos.clear();
    _produtosPorMercado.clear();
    _mercadosSelecionados.clear();
    notifyListeners();
  }

  // Função para definir os mercados selecionados
  void setMercadosSelecionados(List<String> mercados) {
    print('Definindo mercados selecionados: $mercados');
    _mercadosSelecionados = mercados;
    notifyListeners();
  }

  // Função para definir os produtos
  void setProdutos(List<Produto> produtosParaComparar) {
    print('Definindo produtos: ${produtosParaComparar.length}');
    _produtos = produtosParaComparar;
    notifyListeners();
  }

  // Finalizar a lista de um mercado específico
  Future<void> finalizarLista(String mercado, List<Produto> produtos) async {
    print('Finalizando lista para mercado: $mercado');
    await _finalizarListaParaMercado(mercado, produtos);
    
    // Atualiza a lista de mercados selecionados
    _mercadosSelecionados.remove(mercado);
    notifyListeners();
  }

  // Finalizar todas as listas
  Future<void> finalizarTodasListas(Map<String, List<Produto>> produtosPorMercado) async {
    print('Finalizando todas as listas');
    for (var entry in produtosPorMercado.entries) {
      await _finalizarListaParaMercado(entry.key, entry.value);
    }
    limparDados();
  }

  Future<void> _finalizarListaParaMercado(String mercado, List<Produto> produtos) async {
    final agora = DateTime.now();
    final dataFormatada = "${agora.day}/${agora.month}/${agora.year}";
    final nomeLista = "$mercado ($dataFormatada)";

    try {
      final batch = _firestore.batch();

      DocumentReference mercadoAnaliseRef = _firestore.collection('mercado_analise').doc();
      batch.set(mercadoAnaliseRef, {
        'nome_mercado': nomeLista,
        'data_finalizacao': dataFormatada,
        'produtos': produtos.map((p) => {
          'nome': p.nome,
          'preco': p.mercados?[mercado]?['preco'],
          'marca': p.mercados?[mercado]?['marca'],
        }).toList(),
        'finalizada': true,
      });

      for (var produto in produtos) {
        if (produto.id != null) {
          DocumentReference produtoRef = _firestore.collection('produtos').doc(produto.id);
          batch.update(produtoRef, {
            'precoBase($mercado)': produto.mercados?[mercado]?['preco'],
            'marcaBase($mercado)': produto.mercados?[mercado]?['marca'],
          });
        }
      }

      await batch.commit();

      _analisesPorMercado[mercado] = Map.fromIterable(
        produtos,
        key: (p) => p.id!,
        value: (p) => AnaliseProduto(
          produtoId: p.id!,
          mercado: mercado,
          preco: p.mercados![mercado]!['preco'],
          marca: p.mercados![mercado]!['marca'],
        ),
      );

      print('Lista finalizada com sucesso para mercado: $mercado');
    } catch (e) {
      print('Erro ao finalizar lista para mercado $mercado: $e');
      throw e;
    }
  }

  Future<void> carregarProdutosPorMercado(String mercado) async {
    print('Carregando produtos para mercado: $mercado');
    _isLoadingProdutos = true;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('produtos')
          .where('mercadoUsado', isEqualTo: mercado)
          .get();

      _produtosPorMercado[mercado] = snapshot.docs
          .map((doc) => Produto.fromFirestore(doc))
          .toList();

      print('Carregados ${_produtosPorMercado[mercado]?.length} produtos para $mercado');
    } catch (e) {
      print('Erro ao carregar produtos para o mercado $mercado: $e');
      _produtosPorMercado[mercado] = [];
    }

    _isLoadingProdutos = false;
    notifyListeners();
  }

  // Método para sincronizar com o AnaliseProvider
  void sincronizarComAnaliseProvider() {
    if (_analiseProvider != null && _analiseProvider!.selectedMercado != null) {
      if (!_mercadosSelecionados.contains(_analiseProvider!.selectedMercado)) {
        _mercadosSelecionados.add(_analiseProvider!.selectedMercado!);
        notifyListeners();
      }
    }
  }
}