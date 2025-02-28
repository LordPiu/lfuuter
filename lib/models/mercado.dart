import 'package:flutter/foundation.dart';

class Mercado extends ChangeNotifier {
  final String? id;
  final String listaMercadoId;
  final String produtoId;
  final String nome;
  double quantidade;
  double quantidadeOriginal;
  final String unidade;
  final String unidadeMedida;
  final double? kgPorUnidade;
  double valorUnidade;
  double valorTotal;
  String? dataCompra;
  bool editando;
  bool assinado;
  String? nomeMercado;
  double? precoAnterior;

  Mercado({
    this.id,
    required this.listaMercadoId,
    required this.produtoId,
    required this.nome,
    required this.quantidade,
    required this.quantidadeOriginal,
    required this.unidade,
    required this.unidadeMedida,
    this.kgPorUnidade,
    required this.valorUnidade,
    required this.valorTotal,
    this.dataCompra,
    this.editando = false,
    this.assinado = false,
    this.nomeMercado,
    this.precoAnterior,
  });

  // Método copyWith
  Mercado copyWith({
    String? id,
    String? listaMercadoId,
    String? produtoId,
    String? nome,
    double? quantidade,
    double? quantidadeOriginal,
    String? unidade,
    String? unidadeMedida,
    double? kgPorUnidade,
    double? valorUnidade,
    double? valorTotal,
    String? dataCompra,
    bool? editando,
    bool? assinado,
    String? nomeMercado,
    double? precoAnterior,
  }) {
    return Mercado(
      id: id ?? this.id,
      listaMercadoId: listaMercadoId ?? this.listaMercadoId,
      produtoId: produtoId ?? this.produtoId,
      nome: nome ?? this.nome,
      quantidade: quantidade ?? this.quantidade,
      quantidadeOriginal: quantidadeOriginal ?? this.quantidadeOriginal,
      unidade: unidade ?? this.unidade,
      unidadeMedida: unidadeMedida ?? this.unidadeMedida,
      kgPorUnidade: kgPorUnidade ?? this.kgPorUnidade,
      valorUnidade: valorUnidade ?? this.valorUnidade,
      valorTotal: valorTotal ?? this.valorTotal,
      dataCompra: dataCompra ?? this.dataCompra,
      editando: editando ?? this.editando,
      assinado: assinado ?? this.assinado,
      nomeMercado: nomeMercado ?? this.nomeMercado,
      precoAnterior: precoAnterior ?? this.precoAnterior,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lista_mercado_id': listaMercadoId,
      'produto_id': produtoId,
      'nome': nome,
      'quantidade': quantidade,
      'quantidade_original': quantidadeOriginal,
      'unidade': unidade,
      'unidadeMedida': unidadeMedida,
      'kgPorUnidade': kgPorUnidade,
      'valor_unidade': valorUnidade,
      'valor_total': valorTotal,
      'data_compra': dataCompra,
      'assinado': assinado ? 1 : 0,
      'nome_mercado': nomeMercado,
      'preco_anterior': precoAnterior,
    };
  }

  factory Mercado.fromMap(Map<String, dynamic> map, {required String id}) {
  return Mercado(
      id: map['id'] as String?,
      listaMercadoId: map['lista_mercado_id'] as String,
      produtoId: map['produto_id'] as String,
      nome: map['nome'] as String,
      quantidade: (map['quantidade'] as num).toDouble(),
      quantidadeOriginal: (map['quantidade_original'] as num?)?.toDouble() ?? (map['quantidade'] as num).toDouble(),
      unidade: map['unidade'] as String? ?? '',
      unidadeMedida: map['unidadeMedida'] as String? ?? 'unidade',
      kgPorUnidade: (map['kgPorUnidade'] as num?)?.toDouble(),
      valorUnidade: (map['valor_unidade'] as num).toDouble(),
      valorTotal: (map['valor_total'] as num).toDouble(),
      dataCompra: map['data_compra'] as String?,
      editando: false,
      assinado: map['assinado'] == 1,
      nomeMercado: map['nome_mercado'] as String?,
      precoAnterior: (map['preco_anterior'] as num?)?.toDouble(),
    );
  }
}
