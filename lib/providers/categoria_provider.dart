// providers/categoria_provider.dart

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/categoria.dart';

class CategoriaProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'categorias';

  List<Categoria> _categorias = [];

  List<Categoria> get categorias => _categorias;

  CategoriaProvider() {
    fetchCategorias();
  }

  /// Busca todas as categorias do Firestore e atualiza a lista local.
  Future<void> fetchCategorias() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection(_collection).get();
      _categorias = querySnapshot.docs.map((doc) => Categoria.fromFirestore(doc)).toList();
      notifyListeners();
    } catch (e) {
      print('Erro ao buscar categorias: $e');
    }
  }

  /// Adiciona uma nova categoria ao Firestore.
  Future<void> addCategoria(String nome) async {
    try {
      DocumentReference docRef = await _firestore.collection(_collection).add({
        'nome': nome,
      });

      Categoria novaCategoria = Categoria(
        id: docRef.id,
        nome: nome,
        reference: docRef,
      );

      _categorias.add(novaCategoria);
      notifyListeners();
    } catch (e) {
      print('Erro ao adicionar categoria: $e');
      throw Exception('Falha ao adicionar categoria: $e');
    }
  }

  /// Deleta uma categoria do Firestore.
  Future<void> deleteCategoria(String id) async {
    try {
      DocumentReference docRef = _firestore.collection(_collection).doc(id);
      await docRef.delete();
      _categorias.removeWhere((categoria) => categoria.id == id);
      notifyListeners();
    } catch (e) {
      print('Erro ao deletar categoria: $e');
      throw Exception('Falha ao deletar categoria: $e');
    }
  }
}
