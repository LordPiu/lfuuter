// lib/models/produto.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Produto {
  String? id;
  String nome;
  String unidadeMedida;
  String? categoriaId;
  double? kgPorUnidade;
  List<String>? marcas;

  // Campos adicionais para a comparação
  double? preco;
  String? marcaUsada;
  String? mercadoUsado;

  // Novos campos adicionados para refletir os dados da compra
  int? quantidade;
  String? unidadeMedidaCompra;

  // Novo campo para armazenar dados específicos por mercado
  Map<String, dynamic>? mercados;

  Produto({
    this.id,
    required this.nome,
    required this.unidadeMedida,
    this.categoriaId,
    this.kgPorUnidade,
    this.marcas,
    this.preco,
    this.marcaUsada,
    this.mercadoUsado,
    this.quantidade,
    this.unidadeMedidaCompra,
    this.mercados,
  });

  factory Produto.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Produto(
      id: doc.id,
      nome: data['nome'] ?? '',
      unidadeMedida: data['unidadeMedida'] ?? '',
      categoriaId: data['categoriaId'],
      kgPorUnidade: data['kgPorUnidade']?.toDouble(),
      marcas: data['marcas'] != null ? List<String>.from(data['marcas']) : [],
      preco: data['preco']?.toDouble(),
      marcaUsada: data['marcaUsada'],
      mercadoUsado: data['mercadoUsado'],
      quantidade: data['quantidade'],
      unidadeMedidaCompra: data['unidadeMedidaCompra'],
      mercados: data['mercados'] != null ? Map<String, dynamic>.from(data['mercados']) : {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'unidadeMedida': unidadeMedida,
      'categoriaId': categoriaId,
      'kgPorUnidade': kgPorUnidade,
      'marcas': marcas,
      'preco': preco,
      'marcaUsada': marcaUsada,
      'mercadoUsado': mercadoUsado,
      'quantidade': quantidade,
      'unidadeMedidaCompra': unidadeMedidaCompra,
      'mercados': mercados,
    };
  }

  // Método para converter o Produto em um Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'unidadeMedida': unidadeMedida,
      'categoriaId': categoriaId,
      'kgPorUnidade': kgPorUnidade,
      'marcas': marcas,
      'preco': preco,
      'marcaUsada': marcaUsada,
      'mercadoUsado': mercadoUsado,
      'quantidade': quantidade,
      'unidadeMedidaCompra': unidadeMedidaCompra,
      'mercados': mercados,
    };
  }

  // Método para criar um Produto a partir de um Map
  factory Produto.fromMap(Map<String, dynamic> map) {
    return Produto(
      id: map['id'],
      nome: map['nome'] ?? '',
      unidadeMedida: map['unidadeMedida'] ?? '',
      categoriaId: map['categoriaId'],
      kgPorUnidade: map['kgPorUnidade']?.toDouble(),
      marcas: List<String>.from(map['marcas'] ?? []),
      preco: map['preco']?.toDouble(),
      marcaUsada: map['marcaUsada'],
      mercadoUsado: map['mercadoUsado'],
      quantidade: map['quantidade'],
      unidadeMedidaCompra: map['unidadeMedidaCompra'],
      mercados: map['mercados'] != null ? Map<String, dynamic>.from(map['mercados']) : {},
    );
  }
}
