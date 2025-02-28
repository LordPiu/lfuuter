class Estoque {
  int? id;
  int produtoId;
  double quantidadeAtual;
  double nivelMinimo;
  DateTime ultimaAtualizacao;

  Estoque({
    this.id,
    required this.produtoId,
    required this.quantidadeAtual,
    required this.nivelMinimo,
    required this.ultimaAtualizacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'produto_id': produtoId,
      'quantidade_atual': quantidadeAtual,
      'nivel_minimo': nivelMinimo,
      'ultima_atualizacao': ultimaAtualizacao.toIso8601String(),
    };
  }

  factory Estoque.fromMap(Map<String, dynamic> map) {
    return Estoque(
      id: map['id'],
      produtoId: map['produto_id'],
      quantidadeAtual: map['quantidade_atual'],
      nivelMinimo: map['nivel_minimo'],
      ultimaAtualizacao: DateTime.parse(map['ultima_atualizacao']),
    );
  }

  // Adicionando o método copyWith
  Estoque copyWith({
    int? id,
    int? produtoId,
    double? quantidadeAtual,
    double? nivelMinimo,
    DateTime? ultimaAtualizacao,
  }) {
    return Estoque(
      id: id ?? this.id,
      produtoId: produtoId ?? this.produtoId,
      quantidadeAtual: quantidadeAtual ?? this.quantidadeAtual,
      nivelMinimo: nivelMinimo ?? this.nivelMinimo,
      ultimaAtualizacao: ultimaAtualizacao ?? this.ultimaAtualizacao,
    );
  }
}