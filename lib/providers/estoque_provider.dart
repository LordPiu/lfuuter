import 'package:flutter/foundation.dart';
import '../models/estoque.dart';
import '../models/produto.dart';
import '../db/database_helper.dart';

class EstoqueProvider with ChangeNotifier {
  List<Estoque> _estoques = [];
  List<Produto> _produtos = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Estoque> get estoques => _estoques;

  Future<void> fetchEstoques() async {
    print('Fetching estoques...');
    final estoquesMaps = await _dbHelper.queryAllEstoque();
    print('Estoques fetched: ${estoquesMaps.length}');
    _estoques = estoquesMaps.map((map) => Estoque.fromMap(map)).toList();
    notifyListeners();
  }

  Future<void> atualizarEstoque(int produtoId, double novaQuantidade) async {
    int index = _estoques.indexWhere((e) => e.produtoId == produtoId);
    if (index != -1) {
      Estoque estoqueAtualizado = _estoques[index].copyWith(
        quantidadeAtual: novaQuantidade,
        ultimaAtualizacao: DateTime.now(),
      );
      await _dbHelper.updateEstoque(estoqueAtualizado.toMap());
      _estoques[index] = estoqueAtualizado;
      notifyListeners();
    }
  }

  Future<void> definirNivelMinimo(int produtoId, double nivelMinimo) async {
    int index = _estoques.indexWhere((e) => e.produtoId == produtoId);
    if (index != -1) {
      Estoque estoqueAtualizado = _estoques[index].copyWith(
        nivelMinimo: nivelMinimo,
      );
      await _dbHelper.updateEstoque(estoqueAtualizado.toMap());
      _estoques[index] = estoqueAtualizado;
      notifyListeners();
    }
  }

  Future<List<Estoque>> getProdutosComEstoqueBaixo() async {
    return _estoques.where((e) => e.quantidadeAtual <= e.nivelMinimo).toList();
  }

  Produto getProdutoPorId(int produtoId) {
    return _produtos.firstWhere((p) => p.id == produtoId);
  }

  Future<void> fetchProdutos() async {
    _produtos = await _dbHelper.getProdutos();
    notifyListeners();
  }

  Future<void> addTestEstoque() async {
    print('Adding test estoque item...');
    await _dbHelper.insertEstoque({
      'produto_id': 1,
      'quantidade_atual': 10,
      'nivel_minimo': 5,
      'ultima_atualizacao': DateTime.now().toIso8601String(),
    });
    print('Test estoque item added. Fetching updated estoques...');
    await fetchEstoques();
  }
}