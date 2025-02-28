// lib/widgets/mercado_product_row.dart

import 'package:flutter/material.dart';
import '../models/mercado.dart';

class MercadoProductRow extends StatelessWidget {
  final Mercado mercado;
  final String produtoNome;
  final Function(Mercado) onChanged;
  final VoidCallback onEdit;

  MercadoProductRow({
    required this.mercado,
    required this.produtoNome,
    required this.onChanged,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: mercado.comprado,
        onChanged: (value) {
          onChanged(mercado.copyWith(comprado: value ?? false));
        },
      ),
      title: Text(produtoNome),
      subtitle: Text('${mercado.quantidade} ${mercado.unidade} - R\$ ${mercado.valorTotal.toStringAsFixed(2)}'),
      trailing: IconButton(
        icon: Icon(Icons.edit),
        onPressed: onEdit,
      ),
    );
  }
}
