// lib/providers/produto_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/produto.dart';

class ProdutoProvider with ChangeNotifier {
  List<Produto> _produtos = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Produto> get produtos => _produtos;

  ProdutoProvider() {
    fetchProdutos();
  }

  Future<void> fetchProdutos() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('produtos').get();
      _produtos = querySnapshot.docs.map((doc) => Produto.fromFirestore(doc)).toList();
      notifyListeners();
    } catch (e) {
      print('Erro ao buscar produtos: $e');
    }
  }

  Future<void> addProduto(String nome, String unidadeMedida, {String? categoriaId, double? kgPorUnidade}) async {
    try {
      DocumentReference docRef = await _firestore.collection('produtos').add({
        'nome': nome,
        'unidadeMedida': unidadeMedida,
        'categoriaId': categoriaId,
        'kgPorUnidade': kgPorUnidade,
      });
      
      Produto novoProduto = Produto(
        id: docRef.id,
        nome: nome,
        unidadeMedida: unidadeMedida,
        categoriaId: categoriaId,
        kgPorUnidade: kgPorUnidade,
      );
      
      _produtos.add(novoProduto);
      notifyListeners();
    } catch (e) {
      print('Erro ao adicionar produto: $e');
      throw e;
    }
  }

  Future<void> updateProduto(String id, String novoNome, String novaUnidadeMedida, {String? novaCategoriaId, double? novoKgPorUnidade}) async {
    try {
      await _firestore.collection('produtos').doc(id).update({
        'nome': novoNome,
        'unidadeMedida': novaUnidadeMedida,
        'categoriaId': novaCategoriaId,
        'kgPorUnidade': novoKgPorUnidade,
      });

      int index = _produtos.indexWhere((p) => p.id == id);
      if (index != -1) {
        _produtos[index] = Produto(
          id: id,
          nome: novoNome,
          unidadeMedida: novaUnidadeMedida,
          categoriaId: novaCategoriaId,
          kgPorUnidade: novoKgPorUnidade,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao atualizar produto: $e');
      throw e;
    }
  }

  Future<void> deleteProduto(String id) async {
    try {
      await _firestore.collection('produtos').doc(id).delete();
      _produtos.removeWhere((produto) => produto.id == id);
      notifyListeners();
    } catch (e) {
      print('Erro ao excluir produto: $e');
      throw e;
    }
  }
}