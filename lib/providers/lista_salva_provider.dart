// providers/lista_salva_provider.dart

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lista_salva.dart';

class ListaSalvaProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'listas_salvas';

  List<ListaSalva> _listasSalvas = [];

  List<ListaSalva> get listasSalvas => _listasSalvas;

  ListaSalvaProvider() {
    fetchListasSalvas();
  }

  /// Busca todas as listas salvas do Firestore e atualiza a lista local.
  Future<void> fetchListasSalvas() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection(_collection).get();
      _listasSalvas = querySnapshot.docs.map((doc) => ListaSalva.fromFirestore(doc)).toList();
      notifyListeners();
    } catch (e) {
      print('Erro ao buscar listas salvas: $e');
    }
  }

  /// Adiciona uma nova lista salva ao Firestore.
  Future<void> addListaSalva(ListaSalva lista) async {
    try {
      DocumentReference docRef = await _firestore.collection(_collection).add(lista.toMap());
      ListaSalva novaLista = lista.copyWith(id: docRef.id, reference: docRef);
      _listasSalvas.add(novaLista);
      notifyListeners();
    } catch (e) {
      print('Erro ao adicionar lista salva: $e');
      throw Exception('Falha ao adicionar lista salva: $e');
    }
  }
}
