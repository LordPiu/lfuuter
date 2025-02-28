// models/nome_mercado.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class NomeMercado {
  final String? id; // ID do Firestore
  final String nome;

  NomeMercado({
    this.id,
    required this.nome,
  });

  /// Converte o objeto para um mapa para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
    };
  }

  /// Cria uma instância de NomeMercado a partir de um DocumentSnapshot do Firestore
  factory NomeMercado.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NomeMercado(
      id: doc.id,
      nome: data['nome'] ?? '',
    );
  }
}
