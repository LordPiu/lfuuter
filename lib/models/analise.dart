// lib/models/analise.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AnaliseProduto {
  String produtoId;
  String mercado;
  double preco;
  String marca;

  AnaliseProduto({
    required this.produtoId,
    required this.mercado,
    required this.preco,
    required this.marca,
  });

  factory AnaliseProduto.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AnaliseProduto(
      produtoId: data['produtoId'],
      mercado: data['mercado'],
      preco: data['preco']?.toDouble() ?? 0.0,
      marca: data['marca'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'produtoId': produtoId,
      'mercado': mercado,
      'preco': preco,
      'marca': marca,
    };
  }

  // Método para converter o AnaliseProduto em um Map
  Map<String, dynamic> toMap() {
    return {
      'produtoId': produtoId,
      'mercado': mercado,
      'preco': preco,
      'marca': marca,
    };
  }

  // Método para criar um AnaliseProduto a partir de um Map
  factory AnaliseProduto.fromMap(Map<String, dynamic> map) {
    return AnaliseProduto(
      produtoId: map['produtoId'],
      mercado: map['mercado'],
      preco: map['preco']?.toDouble() ?? 0.0,
      marca: map['marca'] ?? '',
    );
  }
}
