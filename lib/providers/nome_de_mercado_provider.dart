// providers/nome_de_mercado_provider.dart

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NomeDeMercadoProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'nomes_de_mercado';

  // Agora, cada mapa inclui também o DocumentReference
  List<Map<String, dynamic>> _nomesDeMercado = <Map<String, dynamic>>[];

  List<Map<String, dynamic>> get nomesDeMercado => _nomesDeMercado;

  NomeDeMercadoProvider() {
    fetchNomesDeMercado();
  }

  /// Busca todos os nomes de mercado do Firestore e atualiza a lista local.
  Future<void> fetchNomesDeMercado() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('nomes_de_mercado').get();
      _nomesDeMercado = snapshot.docs.map((doc) => {
        'id': doc.id,
        'nome': doc['nome'],
        'nome_lower': doc['nome_lower'],
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Erro ao buscar nomes de mercado: $e');
      _nomesDeMercado = [];
    }
  }

  /// Adiciona um novo nome de mercado ao Firestore após verificar duplicações.
  Future<void> addNomeDeMercado(String nome) async {
    try {
      print('Iniciando adição de nome de mercado: $nome');

      // Converter o nome para minúsculas para verificação case-insensitive
      String nomeLower = nome.toLowerCase();

      // Verificação de duplicação no Firestore
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('nome_lower', isEqualTo: nomeLower)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Se o nome já existe, lança um erro
        print('Erro: Nome de mercado "$nome" já existe.');
        throw Exception('Erro: Nome de mercado "$nome" já existe.');
      }

      // Caso contrário, adiciona o novo nome
      DocumentReference docRef = await _firestore.collection(_collection).add({
        'nome': nome,
        'nome_lower': nomeLower, // Campo para verificação case-insensitive
      });

      if (docRef.id.isNotEmpty) {
        _nomesDeMercado.add({
          'id': docRef.id,
          'nome': nome,
          'reference': docRef, // Adicionado DocumentReference
        });
        notifyListeners();
        print('Nome de mercado adicionado com sucesso.');
      } else {
        print('Falha ao adicionar nome de mercado. ID retornado: ${docRef.id}');
      }
    } catch (e, stackTrace) {
      print('Erro ao adicionar nome de mercado no provider: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Falha ao adicionar nome de mercado no provider: $e');
    }
  }

  /// Atualiza um nome de mercado existente no Firestore.
  Future<void> updateNomeDeMercado(String id, String novoNome) async {
    try {
      String novoNomeLower = novoNome.toLowerCase();

      // Verificação de duplicação para o novo nome, excluindo o documento atual
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('nome_lower', isEqualTo: novoNomeLower)
          .where(FieldPath.documentId, isNotEqualTo: id)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print('Erro: Outro nome de mercado com o nome "$novoNome" já existe.');
        throw Exception('Erro: Outro nome de mercado com o nome "$novoNome" já existe.');
      }

      // Atualiza no Firestore
      DocumentReference docRef = _firestore.collection(_collection).doc(id);
      await docRef.update({
        'nome': novoNome,
        'nome_lower': novoNomeLower,
      });

      // Atualiza na lista local
      int index = _nomesDeMercado.indexWhere((item) => item['id'] == id);
      if (index != -1) {
        _nomesDeMercado[index]['nome'] = novoNome;
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao atualizar nome de mercado: $e');
      throw Exception('Falha ao atualizar nome de mercado: $e');
    }
  }

  /// Deleta um nome de mercado do Firestore.
  Future<void> deleteNomeDeMercado(String id) async {
    try {
      DocumentReference docRef = _firestore.collection(_collection).doc(id);
      await docRef.delete();
      _nomesDeMercado.removeWhere((item) => item['id'] == id);
      notifyListeners();
    } catch (e) {
      print('Erro ao deletar nome de mercado: $e');
      throw Exception('Falha ao deletar nome de mercado: $e');
    }
  }
}
