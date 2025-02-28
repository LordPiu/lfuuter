// detalhes_lista_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetalhesListaScreen extends StatefulWidget {
  final String listaFinalizadaId;

  DetalhesListaScreen({required this.listaFinalizadaId});

  @override
  _DetalhesListaScreenState createState() => _DetalhesListaScreenState();
}

class _DetalhesListaScreenState extends State<DetalhesListaScreen> {
  bool isLoading = true;
  Map<String, dynamic>? detalhesLista;

  @override
  void initState() {
    super.initState();
    _carregarDetalhes();
  }

  void _carregarDetalhes() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('listas_finalizadas')
          .doc(widget.listaFinalizadaId)
          .get();

      if (doc.exists) {
        setState(() {
          detalhesLista = doc.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          detalhesLista = null;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar detalhes: $e');
      setState(() {
        detalhesLista = null;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes da Lista'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : detalhesLista == null
              ? Center(child: Text('Erro ao carregar os detalhes da lista.'))
              : _buildDetalhes(),
    );
  }

  Widget _buildDetalhes() {
    List<dynamic> itensDynamic = detalhesLista!['itens'] ?? [];
    List<Map<String, dynamic>> itens = List<Map<String, dynamic>>.from(itensDynamic);
    double valorTotal = detalhesLista!['valorTotal'] ?? 0.0;
    String dataFinalizacao = '';
    if (detalhesLista!['dataFinalizacao'] != null) {
      Timestamp timestamp = detalhesLista!['dataFinalizacao'] as Timestamp;
      dataFinalizacao = DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Título: ${detalhesLista!['titulo'] ?? 'Não informado'}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Data de Finalização: $dataFinalizacao'),
              SizedBox(height: 8),
              Text('Valor Total: R\$ ${NumberFormat('#,##0.00', 'pt_BR').format(valorTotal)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: itens.length,
            itemBuilder: (context, index) {
              var item = itens[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(item['nome'] ?? 'Nome não informado'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quantidade: ${item['quantidade_comprada'] ?? 'N/A'}'),
                      Text('Preço Unitário: R\$ ${NumberFormat('#,##0.00', 'pt_BR').format(item['preco_unidade'] ?? 0)}'),
                      Text('Nome do Mercado: ${item['nome_mercado'] ?? 'Não informado'}'),
                    ],
                  ),
                  trailing: Text('Total: R\$ ${NumberFormat('#,##0.00', 'pt_BR').format(item['valor_total'] ?? 0)}'),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}