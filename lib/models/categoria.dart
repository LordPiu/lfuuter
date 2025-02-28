// models/categoria.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Categoria {
  final String? id; // ID do Firestore
  final String nome;
  final DocumentReference? reference; // Referência ao documento no Firestore

  Categoria({
    this.id,
    required this.nome,
    this.reference,
  });

  /// Converte o objeto para um mapa para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
    };
  }

  /// Cria uma instância de Categoria a partir de um DocumentSnapshot do Firestore
  factory Categoria.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Categoria(
      id: doc.id,
      nome: data['nome'] ?? '',
      reference: doc.reference,
    );
  }

  Categoria copyWith({
    String? id,
    String? nome,
    DocumentReference? reference,
  }) {
    return Categoria(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      reference: reference ?? this.reference,
    );
  }

  @override
  String toString() {
    return 'Categoria(id: $id, nome: $nome)';
  }
}
