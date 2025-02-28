import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/compra.dart';

class CompraProvider with ChangeNotifier {
  List<Compra> _compras = [];
  List<Map<String, dynamic>> _listasCompras = [];
  String? _listaAtualId;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Compra> _excluidosTemporariamente = [];

  List<Compra> get compras => _compras;
  List<Map<String, dynamic>> get listasCompras => _listasCompras;
  String? get listaAtualId => _listaAtualId;
  List<Compra> get excluidosTemporariamente => _excluidosTemporariamente;

  Future<void> carregarListasCompras() async {
    QuerySnapshot querySnapshot = await _firestore.collection('listas_compras').get();
    _listasCompras = querySnapshot.docs.map((doc) => {
      'id': doc.id,
      'nome': doc['nome'],
      'data': doc['data'],
    }).toList();
    notifyListeners();
  }

  Future<void> carregarComprasPorLista(String listaId) async {
    _excluidosTemporariamente.clear();
    QuerySnapshot querySnapshot = await _firestore
        .collection('listas_compras')
        .doc(listaId)
        .collection('compras')
        .get();
    _compras = querySnapshot.docs
        .map((doc) => Compra.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
        .toList();
    _listaAtualId = listaId;
    notifyListeners();
  }

  Future<void> salvarOuAtualizarLista(List<Compra> compras, {String? nome}) async {
    if (_listaAtualId != null) {
      await _atualizarListaExistente(compras, nome: nome);
    } else {
      await _criarNovaLista(compras, nome: nome);
    }

    await salvarExclusoesTemporarias();
    await carregarListasCompras();
    notifyListeners();
  }

  Future<void> _atualizarListaExistente(List<Compra> compras, {String? nome}) async {
    if (_listaAtualId == null) return;

    if (nome != null && nome.trim().isNotEmpty) {
      await _firestore.collection('listas_compras').doc(_listaAtualId).update({'nome': nome.trim()});
    }

    for (var compra in compras) {
      if (compra.id != null) {
        await _firestore
            .collection('listas_compras')
            .doc(_listaAtualId)
            .collection('compras')
            .doc(compra.id)
            .set(compra.toMap()..['lista_id'] = _listaAtualId); // Adicionando o campo lista_id
      } else {
        await _firestore
            .collection('listas_compras')
            .doc(_listaAtualId)
            .collection('compras')
            .add(compra.toMap()..['lista_id'] = _listaAtualId); // Adicionando o campo lista_id
      }
    }

    for (var compra in _excluidosTemporariamente) {
      if (compra.id != null) {
        await _firestore
            .collection('listas_compras')
            .doc(_listaAtualId)
            .collection('compras')
            .doc(compra.id)
            .delete();
      }
    }
  }

  Future<void> _criarNovaLista(List<Compra> compras, {String? nome}) async {
    String nomeLista = (nome?.trim().isNotEmpty ?? false)
        ? nome!.trim()
        : DateFormat('dd/MM/yyyy').format(DateTime.now());

    DocumentReference listaRef = await _firestore.collection('listas_compras').add({
      'nome': nomeLista,
      'data': DateTime.now().toIso8601String(),
    });

    _listaAtualId = listaRef.id;

    for (var compra in compras) {
      await listaRef.collection('compras').add(compra.toMap()..['lista_id'] = _listaAtualId); // Adicionando o campo lista_id
    }
  }

  Future<void> salvarExclusoesTemporarias() async {
    if (_listaAtualId == null) return;
    for (var compra in _excluidosTemporariamente) {
      if (compra.id != null) {
        await _firestore
            .collection('listas_compras')
            .doc(_listaAtualId)
            .collection('compras')
            .doc(compra.id)
            .delete();
      }
    }
    _excluidosTemporariamente.clear();
  }

  void addCompraTemporaria(Compra compra) {
    _compras.add(compra);
    notifyListeners();
  }

  void removeCompraTemporaria(String compraId) {
    final compra = _compras.firstWhereOrNull((c) => c.id == compraId);
    if (compra != null) {
      _compras.remove(compra);
      _excluidosTemporariamente.add(compra);
      notifyListeners();
    }
  }

  void limparListaCompras() {
    _compras.clear();
    _listaAtualId = null;
    _excluidosTemporariamente.clear();
    notifyListeners();
  }

  Future<void> atualizarCompra(Compra compra) async {
    final index = _compras.indexWhere((c) => c.id == compra.id);
    if (index != -1) {
      _compras[index] = compra;
      if (compra.id != null && _listaAtualId != null) {
        await _firestore
            .collection('listas_compras')
            .doc(_listaAtualId)
            .collection('compras')
            .doc(compra.id)
            .set(compra.toMap()..['lista_id'] = _listaAtualId); // Adicionando o campo lista_id
      }
      notifyListeners();
    }
  }

  Future<void> removerCompra(Compra compra) async {
    try {
      _compras.removeWhere((c) => c.id == compra.id);
      if (compra.id != null) {
        _excluidosTemporariamente.add(compra);
      }
      notifyListeners();
    } catch (e) {
      print('Erro ao remover compra: $e');
      throw e;
    }
  }
}
