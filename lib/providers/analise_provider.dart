import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/produto.dart';

class AnaliseProvider extends ChangeNotifier {
  static const String CARREGAR_TODOS_PRODUTOS = "Carregar todos os produtos";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Propriedades privadas
  List<String> _allMercados = []; // Lista completa de mercados
  List<String> _mercados = []; // Lista de mercados filtrada
  List<String> _listasCompras = [];
  List<String> _setores = [];
  String? _selectedMercado;
  String? _selectedListaCompra;
  String? _selectedSetor;
  bool _isLoadingMercados = false;
  bool _isLoadingListasCompras = false;
  bool _isLoadingSetores = false;
  List<String?> _selectedMercados = [];
  bool _isSingleSelection = false;

  // Getters
  List<String> get mercados => _isSingleSelection && _selectedMercado != null 
      ? [_selectedMercado!] 
      : _mercados;
  List<String> get listasCompras => _listasCompras;
  List<String> get setores => _setores;
  String? get selectedMercado => _selectedMercado;
  String? get selectedListaCompra => _selectedListaCompra;
  String? get selectedSetor => _selectedSetor;
  bool get isLoadingMercados => _isLoadingMercados;
  bool get isLoadingListasCompras => _isLoadingListasCompras;
  bool get isLoadingSetores => _isLoadingSetores;
  List<String?> get selectedMercados => _selectedMercados;
  bool get isSingleSelection => _isSingleSelection;

  List<String> get listasComprasComOpcaoTodos {
    return [CARREGAR_TODOS_PRODUTOS, ..._listasCompras];
  }

  // Métodos de configuração
  void setSingleSelectionMode(bool isSingle) {
    print('Definindo modo de seleção única: $isSingle');
    _isSingleSelection = isSingle;
    if (isSingle) {
      // Se mudar para seleção única, mantém apenas o primeiro mercado selecionado
      if (_selectedMercados.isNotEmpty) {
        _selectedMercado = _selectedMercados.first;
        _selectedMercados = [_selectedMercado];
        _mercados = _selectedMercado != null ? [_selectedMercado!] : [];
      } else {
        _mercados = [];
      }
    } else {
      // Se mudar para seleção múltipla, restaura a lista completa
      _mercados = List.from(_allMercados);
    }
    notifyListeners();
  }

  // Métodos de carregamento
  Future<List<Produto>> carregarProdutosDaLista(String nomeLista) async {
    List<Produto> produtosDaLista = [];
    try {
      print('Procurando lista com nome: $nomeLista');

      QuerySnapshot listaSnapshot = await _firestore
          .collection('listas_compras')
          .where('nome', isEqualTo: nomeLista)
          .get();

      if (listaSnapshot.docs.isEmpty) {
        print('Lista não encontrada: $nomeLista');
        return [];
      }

      String listaId = listaSnapshot.docs.first.id;
      print('ID da lista encontrado: $listaId');

      QuerySnapshot comprasSnapshot = await _firestore
          .collection('listas_compras')
          .doc(listaId)
          .collection('compras')
          .get();

      print('Número de compras encontradas: ${comprasSnapshot.docs.length}');

      for (var compraDoc in comprasSnapshot.docs) {
        Map<String, dynamic> compraData = compraDoc.data() as Map<String, dynamic>;

        DocumentSnapshot? produtoDoc;
        if (compraData['produto_id'] != null) {
          produtoDoc = await _firestore
              .collection('produtos')
              .doc(compraData['produto_id'])
              .get();
        }

        Produto produto = _criarProdutoFromDocumentos(produtoDoc, compraData, compraDoc.id);
        produtosDaLista.add(produto);
        print('Produto adicionado: ${produto.nome}');
      }
    } catch (e) {
      print('Erro ao carregar produtos da lista: $e');
    }

    print('Total de produtos carregados: ${produtosDaLista.length}');
    return produtosDaLista;
  }

  Produto _criarProdutoFromDocumentos(
    DocumentSnapshot? produtoDoc,
    Map<String, dynamic> compraData,
    String compraId,
  ) {
    if (produtoDoc != null && produtoDoc.exists) {
      Produto produto = Produto.fromFirestore(produtoDoc);
      produto.quantidade = compraData['quantidade']?.toInt();
      produto.unidadeMedidaCompra = compraData['unidadeMedida'];
      return produto;
    } else {
      return Produto(
        id: compraData['produto_id'] ?? compraId,
        nome: compraData['nome'] ?? '',
        unidadeMedida: compraData['unidadeMedida'] ?? '',
        quantidade: compraData['quantidade']?.toInt(),
        categoriaId: compraData['categoriaId'],
        marcas: compraData['marcas'] != null ? List<String>.from(compraData['marcas']) : [],
        mercados: compraData['mercados'] as Map<String, dynamic>?,
        kgPorUnidade: compraData['kgPorUnidade']?.toDouble(),
      );
    }
  }

  Future<List<Produto>> carregarTodosProdutos() async {
    List<Produto> todosProdutos = [];
    try {
      QuerySnapshot snapshot = await _firestore.collection('produtos').get();
      todosProdutos = snapshot.docs.map((doc) => Produto.fromFirestore(doc)).toList();
    } catch (e) {
      print('Erro ao carregar todos os produtos: $e');
    }
    return todosProdutos;
  }

  Future<void> carregarMercados() async {
    _isLoadingMercados = true;
    notifyListeners();
    
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('nomes_de_mercado')
          .get();
      
      _allMercados = snapshot.docs
          .map((doc) => doc['nome'] as String)
          .toList()
          .toSet()
          .toList();
      
      // Se estiver em modo de seleção única e tiver um mercado selecionado,
      // mostra apenas o mercado selecionado
      if (_isSingleSelection && _selectedMercado != null) {
        _mercados = [_selectedMercado!];
      } else {
        _mercados = List.from(_allMercados);
      }
      
      print('Mercados carregados: ${_allMercados.length}');
      print('Mercados filtrados: ${_mercados.length}');
    } catch (e) {
      print('Erro ao carregar mercados: $e');
      _allMercados = [];
      _mercados = [];
    }
    
    _isLoadingMercados = false;
    notifyListeners();
  }

  Future<void> carregarListasCompras() async {
    _isLoadingListasCompras = true;
    notifyListeners();
    try {
      QuerySnapshot snapshot = await _firestore.collection('listas_compras').get();
      _listasCompras = snapshot.docs.map((doc) => doc['nome'] as String).toList();
      print("Listas de compras carregadas: $_listasCompras");
    } catch (e) {
      print("Erro ao carregar listas de compras: $e");
    }
    _isLoadingListasCompras = false;
    notifyListeners();
  }

  Future<void> carregarSetores(String mercado) async {
    _isLoadingSetores = true;
    notifyListeners();
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('mercados')
          .doc(mercado)
          .collection('setores')
          .get();
      _setores = snapshot.docs.map((doc) => doc['nome'] as String).toList();
    } catch (e) {
      print("Erro ao carregar setores: $e");
    }
    _isLoadingSetores = false;
    notifyListeners();
  }

  // Métodos de seleção
  void selecionarMercado(String? newValue) {
    _selectedMercado = newValue;
    _selectedSetor = null;
    if (newValue != null && newValue.isNotEmpty) {
      carregarSetores(newValue);
    }
    notifyListeners();
  }

  void selecionarListaCompra(String? newValue) {
    _selectedListaCompra = newValue;
    notifyListeners();
  }

  void selecionarSetor(String? newValue) {
    _selectedSetor = newValue;
    notifyListeners();
  }

  Future<void> selecionarMercadoEmPosicao(int index, String? mercado, {bool unicaSelecao = false}) async {
    print('Selecionando mercado: $mercado em posição: $index (única seleção: $unicaSelecao)');

    if (mercado != null && !_allMercados.contains(mercado)) {
      print('Mercado $mercado não está na lista de mercados disponíveis');
      return;
    }

    if (unicaSelecao || _isSingleSelection) {
      _selectedMercados = mercado != null ? [mercado] : [];
      _selectedMercado = mercado;
      _isSingleSelection = true;
      _mercados = mercado != null ? [mercado] : [];
    } else {
      if (_selectedMercados.length > index) {
        _selectedMercados[index] = mercado;
      } else {
        while (_selectedMercados.length < index) {
          _selectedMercados.add(null);
        }
        _selectedMercados.add(mercado);
      }

      if (mercado == null || mercado.isEmpty) {
        _selectedMercados = _selectedMercados.sublist(0, index);
      }
      
      // Atualiza a lista de mercados filtrada
      _mercados = _allMercados.where((m) => 
        !_selectedMercados.contains(m) || m == mercado
      ).toList();
    }

    print('Status após seleção:');
    print('- Todos os mercados: ${_allMercados.length}');
    print('- Mercados filtrados: ${_mercados.length}');
    print('- Mercado selecionado: $_selectedMercado');
    print('- Mercados selecionados: ${_selectedMercados.where((m) => m != null).length}');
    
    notifyListeners();
  }

  // Métodos de limpeza
  Future<void> limparSelecoesMercados() async {
    _selectedMercados.clear();
    _selectedMercado = null;
    _selectedListaCompra = null;
    if (_isSingleSelection) {
      _mercados = [];
    } else {
      _mercados = List.from(_allMercados);
    }
    notifyListeners();
  }
}