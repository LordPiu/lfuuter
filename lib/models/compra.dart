import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
import 'package:collection/collection.dart';

class Compra {
  final String? id;
  final String? listaId;
  final String produtoId;
  final String nome;
  final double quantidade;
  final DateTime? data;
  final String unidadeMedida;
  final double? kgPorUnidade;

  Compra({
    this.id,
    this.listaId,
    required this.produtoId,
    required this.nome,
    required this.quantidade,
    this.data,
    this.unidadeMedida = 'unidade',
    this.kgPorUnidade,
  });

  /// Método que converte os dados para um formato adequado para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'lista_id': listaId,
      'produto_id': produtoId,
      'nome': nome,
      'quantidade': quantidade,
      'data': data?.toIso8601String(),  // Converte `data` para string ISO 8601
      'unidadeMedida': unidadeMedida,
      'kgPorUnidade': kgPorUnidade,
    };
  }

  /// Método que cria um objeto `Compra` a partir de um `Map`
  factory Compra.fromMap(Map<String, dynamic> map, {String? id}) {
    return Compra(
      id: id,
      listaId: map['lista_id'] as String?,
      produtoId: map['produto_id'] as String, // Confirma que produtoId é uma String
      nome: map['nome'] ?? '',
      quantidade: (map['quantidade'] as num?)?.toDouble() ?? 0.0,
      // Verifica se o campo 'data' está presente e converte para `DateTime`
      data: map['data'] != null ? DateTime.tryParse(map['data'] as String) : null,
      unidadeMedida: map['unidadeMedida'] ?? 'unidade',
      kgPorUnidade: (map['kgPorUnidade'] as num?)?.toDouble(),
    );
  }

  /// Método que cria um objeto `Compra` a partir de um `DocumentSnapshot` do Firestore
  factory Compra.fromFirestore(DocumentSnapshot doc) {
    return Compra.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
  }

  /// Método para copiar o objeto `Compra` com novos valores opcionais
  Compra copyWith({
    String? id,
    String? listaId,
    String? produtoId,
    String? nome,
    double? quantidade,
    DateTime? data,
    String? unidadeMedida,
    double? kgPorUnidade,
  }) {
    return Compra(
      id: id ?? this.id,
      listaId: listaId ?? this.listaId,
      produtoId: produtoId ?? this.produtoId,
      nome: nome ?? this.nome,
      quantidade: quantidade ?? this.quantidade,
      data: data ?? this.data,
      unidadeMedida: unidadeMedida ?? this.unidadeMedida,
      kgPorUnidade: kgPorUnidade ?? this.kgPorUnidade,
    );
  }

  @override
  String toString() {
    return 'Compra(id: $id, listaId: $listaId, produtoId: $produtoId, nome: $nome, quantidade: $quantidade, data: $data, unidadeMedida: $unidadeMedida, kgPorUnidade: $kgPorUnidade)';
  }
}
