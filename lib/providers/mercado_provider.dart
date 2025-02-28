import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/mercado.dart';
import 'package:intl/intl.dart';
import '../services/openai_service.dart';

class MercadoProvider with ChangeNotifier {
  List<Mercado> _mercados = [];
  List<Mercado> _listaTemporaria = [];
  double _valorTotalGeral = 0.0;
  Map<String, Mercado> _alteracoesTemporarias = {};
  String? _listaMercadoAtualId;
  OpenAIService? _openAIService;
  bool _edicaoEmAndamento = false;
  String? _listaEmEdicaoId;
  String? _selectedListaId;
  bool _isLoaded = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Mercado> get mercados => _mercados;
  double get valorTotalGeral => _valorTotalGeral;
  bool get edicaoEmAndamento => _edicaoEmAndamento;
  String? get listaEmEdicaoId => _listaEmEdicaoId;
  List<Mercado> get listaTemporaria => _listaTemporaria;
  bool get isLoaded => _isLoaded;
  String? get selectedListaId => _selectedListaId;
  String? get listaMercadoAtualId => _listaMercadoAtualId;

  OpenAIService get openAIService {
    _openAIService ??= OpenAIService();
    return _openAIService!;
  }

  bool isListaLoaded(String listaId) {
    return _selectedListaId == listaId && _isLoaded;
  }

  Future<void> fetchMercados() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('mercados').get();
    _mercados = querySnapshot.docs.map((doc) => Mercado.fromMap(doc.data() as Map<String, dynamic>, id: doc.id)).toList();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> iniciarEdicao(String listaId) async {
    _edicaoEmAndamento = true;
    _listaEmEdicaoId = listaId;
    if (_listaTemporaria.isEmpty && _mercados.isNotEmpty) {
      setListaTemporaria(_mercados);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void finalizarEdicao() {
    _edicaoEmAndamento = false;
    _listaEmEdicaoId = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void resetState({bool forceReset = false}) {
    if (!_edicaoEmAndamento || forceReset) {
      _listaMercadoAtualId = null;
      _selectedListaId = null;
      _isLoaded = false;
      _mercados.clear();
      _alteracoesTemporarias.clear();
      _valorTotalGeral = 0;
      _edicaoEmAndamento = false;
      _listaEmEdicaoId = null;
      _listaTemporaria.clear();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> excluirProduto(String id) async {
    try {
      final mercado = _listaTemporaria.firstWhere((m) => m.id == id, orElse: () => throw Exception('Produto não encontrado.'));
      if (mercado.assinado) {
        throw Exception('Produto assinado não pode ser excluído.');
      }

      await _firestore
          .collection('listas_mercado')
          .doc(_listaMercadoAtualId)
          .collection('itens')
          .doc(id)
          .delete();

      _listaTemporaria.removeWhere((m) => m.id == id);
      _alteracoesTemporarias.remove(id);
      _atualizarValoresTotais();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      print('Erro ao excluir produto: $e');
      throw e;
    }
  }

  Future<String> askAIAboutMercado(String question) async {
    try {
      List<Map<String, dynamic>> dadosMercado = await obterTodasListasFinalizadasMercado();
      
      if (dadosMercado.isEmpty) {
        print('Nenhum dado de mercado encontrado.');
        return "Não há dados de mercado disponíveis para responder à pergunta.";
      }
      
      String dadosFormatados = dadosMercado.map((lista) {
        return "Lista ${lista['id']} (${lista['data_finalizacao']}):\n" +
               (lista['itens'] as List<dynamic>).map((item) =>
                 "  - ${item['nome']}: ${item['quantidade_comprada']} unidades, "
                 "Preço: R\$${item['preco_unidade']}, "
                 "Total: R\$${item['valor_total']}"
               ).join('\n');
      }).join('\n\n');
      
      print('Dados formatados para envio à IA:\n$dadosFormatados');
      
      return await openAIService.askOpenAI(question, dadosFormatados);
    } catch (e) {
      print('Erro ao perguntar à IA: $e');
      return "Desculpe, ocorreu um erro ao processar sua pergunta: $e";
    }
  }

  void setListaTemporaria(List<Mercado> listaOriginal) {
  _listaTemporaria = List.from(listaOriginal.map((m) => m.copyWith()));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    notifyListeners();
  });
}

  void atualizarItemTemporario(Mercado item) {
    int index = _listaTemporaria.indexWhere((m) => m.id == item.id);
    if (index != -1) {
      _listaTemporaria[index] = item;
      _alteracoesTemporarias[item.id!] = item;
      calcularValorTotal();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  void clearListaTemporaria() {
    _listaTemporaria.clear();
    _alteracoesTemporarias.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> carregarOuCriarListaMercado(String listaComprasId, String? nomeMercado) async {
  _limparDadosTemporarios();
  if (_selectedListaId != listaComprasId || !_isLoaded) {
    try {
      print('Carregando ou criando lista de mercado para lista de compras: $listaComprasId');
      var listaSnapshot = await _firestore.collection('listas_mercado')
          .where('listaComprasId', isEqualTo: listaComprasId)
          .where('finalizada', isEqualTo: false)
          .get();

      if (listaSnapshot.docs.isEmpty) {
        var novaLista = await _firestore.collection('listas_mercado').add({
          'listaComprasId': listaComprasId,
          'nomeMercado': nomeMercado,
          'finalizada': false,
          'dataCriacao': DateTime.now(),
        });

        _listaMercadoAtualId = novaLista.id;
        print('Nova lista de mercado criada com ID: $_listaMercadoAtualId');
      } else {
        var listaMercado = listaSnapshot.docs.first;
        _listaMercadoAtualId = listaMercado.id;
        print('Lista de mercado existente carregada com ID: $_listaMercadoAtualId');
      }

      await _carregarItensMercado();
      setListaTemporaria(_mercados);  // Certifique-se de que os itens estão sendo carregados
      _selectedListaId = listaComprasId;
      _isLoaded = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      print('Erro ao carregar ou criar lista de mercado: $e');
      throw e;
    }
  }
}

Future<void> _carregarItensMercado() async {
  if (_listaMercadoAtualId == null) {
    throw Exception('Nenhuma lista de mercado selecionada');
  }

  try {
    // Consulta para buscar os produtos da subcoleção "compras"
    var itensSnapshot = await _firestore
        .collection('listas_compras')  // Coleção principal
        .doc(_listaMercadoAtualId)     // O ID da lista de compras atual
        .collection('compras')         // Subcoleção onde os produtos estão armazenados
        .get();

    // Verifica se o snapshot contém documentos
    print("Quantidade de documentos carregados: ${itensSnapshot.docs.length}");

    // Verifica se existem produtos nessa subcoleção
    if (itensSnapshot.docs.isNotEmpty) {
      _mercados = itensSnapshot.docs.map((doc) {
        // Log do conteúdo de cada documento
        print("Produto encontrado: ${doc.data()}");
        return Mercado.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
      }).toList();

      // Atualiza a lista temporária com os produtos carregados
      setListaTemporaria(_mercados);
    } else {
      // Se não houver produtos, limpa a lista
      print("Nenhum produto encontrado.");
      _mercados.clear();
      clearListaTemporaria();
    }

    _alteracoesTemporarias.clear();
    _atualizarValoresTotais();
    notifyListeners();
  } catch (e) {
    print('Erro ao carregar itens do mercado: $e');
    throw e;
  }
}

  Future<void> carregarMercadoPorLista(String listaId) async {
    try {
      print('Carregando lista de mercado: $listaId');
      _listaMercadoAtualId = listaId;
      await _carregarItensMercado();
      print('Lista de mercado carregada com ${_mercados.length} itens');
    } catch (e) {
      print('Erro ao carregar mercado: $e');
      throw e;
    }
  }

  double calcularValorTotal() {
  double novoValorTotal = _listaTemporaria.fold(0, (total, mercado) {
    var mercadoAtualizado = _alteracoesTemporarias[mercado.id] ?? mercado;
    return total + mercadoAtualizado.valorTotal;
  });

  // Verifica se o valor total mudou antes de notificar
  if (novoValorTotal != _valorTotalGeral) {
    _valorTotalGeral = novoValorTotal;
    print('Valor Total Geral: $_valorTotalGeral');
    notifyListeners(); // Notifica somente se houver mudança no valor
  }

  return _valorTotalGeral;
}

  Future<void> atualizarQuantidade(String id, double novaQuantidade) async {
    try {
      var mercado = _listaTemporaria.firstWhere((m) => m.id == id);
      var mercadoAtualizado = mercado.copyWith(
        quantidade: novaQuantidade,
        valorTotal: novaQuantidade * mercado.valorUnidade,
      );
      atualizarItemTemporario(mercadoAtualizado);
      _atualizarValoresTotais();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      print('Erro ao atualizar quantidade: $e');
      throw e;
    }
  }

  Future<void> atualizarPreco(String id, double novoPreco) async {
    try {
      var mercado = _listaTemporaria.firstWhere((m) => m.id == id);
      var mercadoAtualizado = mercado.copyWith(
        valorUnidade: novoPreco,
        valorTotal: mercado.quantidade * novoPreco,
      );
      atualizarItemTemporario(mercadoAtualizado);
      calcularValorTotal();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      print('Erro ao atualizar preço: $e');
      throw e;
    }
  }

  void _atualizarValoresTotais() {
    _valorTotalGeral = _listaTemporaria.fold(0, (total, mercado) {
      var mercadoAtualizado = _alteracoesTemporarias[mercado.id] ?? mercado;
      return total + mercadoAtualizado.valorTotal;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> atualizarAssinaturaProduto(String id, bool assinado) async {
  try {
    final index = _listaTemporaria.indexWhere((m) => m.id == id);
    if (index != -1) {
      var mercadoAtualizado = _listaTemporaria[index].copyWith(assinado: assinado);
      _listaTemporaria[index] = mercadoAtualizado;
      _alteracoesTemporarias[id] = mercadoAtualizado;

      // Notifica a interface que a assinatura foi atualizada
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  } catch (e) {
    print('Erro ao atualizar assinatura: $e');
    throw e;
  }
}


  void atualizarMercadoProduto(String id, String? nomeMercado) {
    final index = _listaTemporaria.indexWhere((m) => m.id == id);
    if (index != -1) {
      var mercadoAtual = _alteracoesTemporarias[id] ?? _mercados[index];
      var mercadoAtualizado = mercadoAtual.copyWith(nomeMercado: nomeMercado);
      _alteracoesTemporarias[id] = mercadoAtualizado;
      _listaTemporaria[index] = mercadoAtualizado;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  void _limparDadosTemporarios() {
    _listaTemporaria.clear();
    _alteracoesTemporarias.clear();
    _mercados.clear();
    _valorTotalGeral = 0;
    _listaMercadoAtualId = null;
    _selectedListaId = null;
    _isLoaded = false;
    _edicaoEmAndamento = false;
    _listaEmEdicaoId = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> _salvarAlteracaoImediata(Mercado mercado) async {
    try {
      await _firestore
          .collection('listas_mercado')
          .doc(_listaMercadoAtualId)
          .collection('itens')
          .doc(mercado.id)
          .update(mercado.toMap());
      print('Alteração salva imediatamente para o item: ${mercado.id}');
    } catch (e) {
      print('Erro ao salvar alteração imediata: $e');
      throw e;
    }
  }

  Mercado getMercadoAtual(String id) {
    return _listaTemporaria.firstWhere((m) => m.id == id);
  }

  bool todosProdutosAssinados() {
    bool todosAssinados = true;
    for (var mercado in _listaTemporaria) {
      var mercadoAtual = _alteracoesTemporarias[mercado.id] ?? mercado;
      print('Produto: ${mercadoAtual.nome}, Assinado: ${mercadoAtual.assinado}');
      if (!mercadoAtual.assinado) {
        todosAssinados = false;
        print('Produto não assinado encontrado: ${mercadoAtual.nome}');
      }
    }
    print('Todos os produtos assinados: $todosAssinados');
    return todosAssinados;
  }

  Future<void> salvarListaTemporaria() async {
    try {
      for (var item in _listaTemporaria) {
        await _firestore
            .collection('listas_mercado')
            .doc(_listaMercadoAtualId)
            .collection('itens')
            .doc(item.id)
            .update(item.toMap());
      }
      _mercados = List.from(_listaTemporaria);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      print('Erro ao salvar lista temporária: $e');
      throw e;
    }
  }

  Future<void> _salvarOrdemProdutos() async {
    try {
      for (int i = 0; i < _listaTemporaria.length; i++) {
        await _firestore
            .collection('listas_mercado')
            .doc(_listaMercadoAtualId)
            .collection('itens')
            .doc(_listaTemporaria[i].id)
            .update({'ordem': i});
      }
    } catch (e) {
      print('Erro ao salvar ordem dos produtos: $e');
      throw e;
    }
  }

  Future<void> salvarAlteracoes() async {
  try {
    print('Iniciando salvamento de alterações. Total de alterações: ${_alteracoesTemporarias.length}');

    for (var entry in _alteracoesTemporarias.entries) {
      String itemId = entry.key;
      Mercado mercado = entry.value;

      // Verifica se o documento existe antes de tentar atualizá-lo
      DocumentSnapshot docSnapshot = await _firestore
          .collection('listas_mercado')
          .doc(_listaMercadoAtualId)
          .collection('itens')
          .doc(itemId)
          .get();

      if (docSnapshot.exists) {
        // Atualiza o documento existente
        print('Salvando alterações para o item: ${mercado.nome}');
        await _firestore
            .collection('listas_mercado')
            .doc(_listaMercadoAtualId)
            .collection('itens')
            .doc(itemId)
            .update(mercado.toMap());
      } else {
        // Trata o caso de documento não encontrado (se necessário, pode adicionar ou tratar de outra forma)
        print('Documento para o item ${mercado.nome} não encontrado. Criando novo documento...');
        await _firestore
            .collection('listas_mercado')
            .doc(_listaMercadoAtualId)
            .collection('itens')
            .doc(itemId)
            .set(mercado.toMap()); // Pode usar `set` para criar o documento se ele não existir
      }

      // Atualiza a lista local com as alterações feitas
      final index = _mercados.indexWhere((m) => m.id == itemId);
      if (index != -1) {
        _mercados[index] = mercado;
      }
    }

    _alteracoesTemporarias.clear(); 
    _atualizarValoresTotais();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    print('Todas as alterações foram salvas com sucesso.');
  } catch (e) {
    print('Erro ao salvar alterações: $e');
    throw e;
  }
}

 Future<void> finalizarListaMercado() async {
  if (_listaMercadoAtualId == null) {
    throw Exception('Nenhuma lista de mercado selecionada');
  }

  if (!todosProdutosAssinados()) {
    throw Exception('Todos os produtos devem ser assinados antes de finalizar.');
  }

  try {
    await salvarAlteracoes();

    String dataAtual = DateFormat('dd/MM/yyyy').format(DateTime.now());
    String tituloLista = 'Lista Finalizada - $dataAtual';

    List<Map<String, dynamic>> itensFinalizados = _listaTemporaria.map((mercado) {
      return {
        'produto_id': mercado.produtoId,
        'nome': mercado.nome,
        'quantidade_comprada': mercado.quantidade,
        'preco_unidade': mercado.valorUnidade,
        'valor_total': mercado.valorTotal,
        'nome_mercado': mercado.nomeMercado,
      };
    }).toList();

    // Cria a lista finalizada no Firestore na coleção `listas_finalizadas`
     DocumentReference listaFinalizadaRef = await _firestore.collection('listas_finalizadas').add({
      'id': '', // Será preenchido após a criação do documento
      'listaMercadoId': _listaMercadoAtualId,
      'itens': itensFinalizados,
      'valorTotal': _valorTotalGeral,
      'titulo': tituloLista,
      'dataFinalizacao': DateTime.now(),
      'nome_lista_compras': tituloLista, // Adicionando este campo
    });

    print('Lista finalizada criada com ID: ${listaFinalizadaRef.id}');

    // Atualiza o documento com seu próprio ID
    await listaFinalizadaRef.update({'id': listaFinalizadaRef.id});

    // Marca a lista de mercado original como finalizada no Firestore
    await _firestore.collection('listas_mercado').doc(_listaMercadoAtualId).update({'finalizada': true});
    
    // Limpa os dados temporários
    _limparDadosTemporarios();
    
    print('Lista de mercado finalizada com sucesso.');
  } catch (e) {
    print('Erro ao finalizar lista de mercado: $e');
    throw e;
  }
}



  void imprimirEstadoAtual() {
    print('Estado atual da lista:');
    _listaTemporaria.forEach((mercado) {
      var mercadoAtual = _alteracoesTemporarias[mercado.id] ?? mercado;
      print('Produto: ${mercadoAtual.nome}, Assinado: ${mercadoAtual.assinado}');
    });
  }

  Future<void> carregarPrecosAnteriores(String? listaFinalizadaId) async {
  try {
    if (listaFinalizadaId != null) {
      var detalhesLista = await _firestore
          .collection('listas_finalizadas')
          .doc(listaFinalizadaId)
          .get();

      if (detalhesLista.exists) {
        List<dynamic> itensAnteriores = detalhesLista['itens'];

        for (var mercado in _listaTemporaria) {
          var itemAnterior = itensAnteriores.firstWhere(
            (item) => item['produto_id'] == mercado.produtoId,
            orElse: () => null
          );
          if (itemAnterior != null) {
            mercado.precoAnterior = itemAnterior['preco_unidade'].toDouble();
          }
        }

        notifyListeners();
      }
    }
  } catch (e) {
    print('Erro ao carregar preços anteriores: $e');
    throw e;
  }
}

  Future<List<Map<String, dynamic>>> obterTodasListasFinalizadasMercado() async {
  try {
    var snapshot = await _firestore.collection('listas_finalizadas').get();
    return snapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      String dataFinalizacao = data['dataFinalizacao'] is Timestamp 
          ? DateFormat('dd/MM/yyyy').format((data['dataFinalizacao'] as Timestamp).toDate())
          : data['dataFinalizacao']?.toString() ?? 'Data desconhecida';
      
      String titulo = 'Lista Finalizada - $dataFinalizacao';
      
      return {
        'id': doc.id,
        'titulo': titulo,
        'data_finalizacao': dataFinalizacao,
      };
    }).toList();
  } catch (e) {
    print('Erro ao obter listas finalizadas: $e');
    throw e;
  }
}

  Future<List<Map<String, dynamic>>> obterListasFinalizadasPorListaCompras(String listaComprasId) async {
    try {
      var snapshot = await _firestore
          .collection('listas_finalizadas')
          .where('listaComprasId', isEqualTo: listaComprasId)
          .get();

      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Erro ao obter listas finalizadas por lista de compras: $e');
      throw e;
    }
  }
}
