// banco_dados_mercado_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detalhes_lista_screen.dart';

class BancoDadosMercadoScreen extends StatelessWidget {
  final DateTime? dataInicio;
  final DateTime? dataFim;

  BancoDadosMercadoScreen({this.dataInicio, this.dataFim});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Banco de Dados - Mercado',
              style: TextStyle(color: Colors.black87)),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.teal,
            tabs: [
              Tab(text: 'Gasto Total'),
              Tab(text: 'Comparação de Preços'),
              Tab(text: 'Comparação de Mercado'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            GastoTotalTab(dataInicio: dataInicio, dataFim: dataFim),
            Center(child: Text('Comparação de Preços (Em desenvolvimento)')),
            Center(child: Text('Comparação de Mercado (Em desenvolvimento)')),
          ],
        ),
      ),
    );
  }
}

class GastoTotalTab extends StatefulWidget {
  final DateTime? dataInicio;
  final DateTime? dataFim;

  GastoTotalTab({this.dataInicio, this.dataFim});

  @override
  _GastoTotalTabState createState() => _GastoTotalTabState();
}

class _GastoTotalTabState extends State<GastoTotalTab> {
  List<Map<String, dynamic>> listas = [];
  bool isLoading = false;
  String mensagemErro = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    print('initState chamado');
    if (widget.dataInicio != null && widget.dataFim != null) {
      _filtrarPeriodoEspecifico(widget.dataInicio!, widget.dataFim!);
    } else {
      _filtrarMesAtual();
    }
  }

  void _filtrarPeriodoEspecifico(DateTime inicio, DateTime fim) async {
  setState(() {
    isLoading = true;
    mensagemErro = '';
  });

  try {
    QuerySnapshot querySnapshot = await _firestore
        .collection('listas_finalizadas') // Mudança aqui
        .where('dataFinalizacao', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('dataFinalizacao', isLessThanOrEqualTo: Timestamp.fromDate(fim))
        .get();

    List<Map<String, dynamic>> resultado = querySnapshot.docs.map((doc) {
  var data = doc.data() as Map<String, dynamic>;
  var valorTotal = 0.0;
  if (data['valorTotal'] != null) {
    valorTotal = (data['valorTotal'] as num).toDouble();
  } else if (data['valor_total'] != null) {
    valorTotal = (data['valor_total'] as num).toDouble();
  }
  print('Valor total processado: $valorTotal');
  
  return {
    'id': doc.id,
    'titulo': data['titulo'] ?? 'Título não informado',
    'dataFinalizacao': data['dataFinalizacao'] is Timestamp
        ? (data['dataFinalizacao'] as Timestamp).toDate().toIso8601String()
        : null,
    'valor_total': valorTotal,
  };
}).toList();

    setState(() {
      isLoading = false;
      if (resultado.isEmpty) {
        mensagemErro = 'Nenhuma lista finalizada encontrada para este período.';
        listas = [];
      } else {
        listas = resultado;
      }
    });
  } catch (e) {
    setState(() {
      isLoading = false;
      mensagemErro = 'Erro ao buscar listas finalizadas: $e';
      listas = [];
    });
  }
}

  void _filtrarMesAtual() async {
  print('Filtro Mês Atual chamado');
  setState(() {
    isLoading = true;
    mensagemErro = '';
  });

  DateTime now = DateTime.now();
  DateTime primeiroDiaMes = DateTime(now.year, now.month, 1);
  DateTime ultimoDiaMes = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  try {
    QuerySnapshot querySnapshot = await _firestore
    .collection('listas_finalizadas')
    .where('dataFinalizacao', isGreaterThanOrEqualTo: Timestamp.fromDate(primeiroDiaMes))
    .where('dataFinalizacao', isLessThanOrEqualTo: Timestamp.fromDate(ultimoDiaMes))
    .get();

    querySnapshot.docs.forEach((doc) {
  print('Documento ID: ${doc.id}');
  print('Dados do documento: ${doc.data()}');
}); 

    List<Map<String, dynamic>> resultado = querySnapshot.docs.map((doc) {
  var data = doc.data() as Map<String, dynamic>;
  var valorTotal = 0.0;
  if (data['valorTotal'] != null) {
    valorTotal = (data['valorTotal'] as num).toDouble();
  } else if (data['valor_total'] != null) {
    valorTotal = (data['valor_total'] as num).toDouble();
  }
  print('Valor total processado: $valorTotal');
  
  return {
    'id': doc.id,
    'titulo': data['titulo'] ?? 'Título não informado',
    'dataFinalizacao': data['dataFinalizacao'] is Timestamp
        ? (data['dataFinalizacao'] as Timestamp).toDate().toIso8601String()
        : null,
    'valor_total': valorTotal,
  };
}).toList();

    setState(() {
      isLoading = false;
      if (resultado.isEmpty) {
        mensagemErro = 'Nenhuma lista de compras encontrada para esta data.';
        listas = [];
      } else {
        listas = resultado;
      }
    });
  } catch (e) {
    print('Erro ao buscar listas: $e');
    setState(() {
      isLoading = false;
      mensagemErro = 'Erro ao buscar listas: $e';
      listas = [];
    });
  }
}

  void _filtrarMesAnterior() async {
    setState(() {
      isLoading = true;
      mensagemErro = '';
    });

    DateTime now = DateTime.now();
    DateTime primeiroDiaMesAnterior = DateTime(now.year, now.month - 1, 1);
    DateTime ultimoDiaMesAnterior =
        DateTime(now.year, now.month, 0, 23, 59, 59);

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('listas_finalizadas')
          .where('dataFinalizacao',
              isGreaterThanOrEqualTo: Timestamp.fromDate(primeiroDiaMesAnterior))
          .where('dataFinalizacao',
              isLessThanOrEqualTo: Timestamp.fromDate(ultimoDiaMesAnterior))
          .get();

      List<Map<String, dynamic>> resultado = querySnapshot.docs.map((doc) {
  var data = doc.data() as Map<String, dynamic>;
  var valorTotal = 0.0;
  if (data['valorTotal'] != null) {
    valorTotal = (data['valorTotal'] as num).toDouble();
  } else if (data['valor_total'] != null) {
    valorTotal = (data['valor_total'] as num).toDouble();
  }
  print('Valor total processado: $valorTotal');
  
  return {
    'id': doc.id,
    'titulo': data['titulo'] ?? 'Título não informado',
    'dataFinalizacao': data['dataFinalizacao'] is Timestamp
        ? (data['dataFinalizacao'] as Timestamp).toDate().toIso8601String()
        : null,
    'valor_total': valorTotal,
  };
}).toList();

      setState(() {
        isLoading = false;
        if (resultado.isEmpty) {
          mensagemErro = 'Nenhuma lista de compras encontrada para esta data.';
          listas = [];
        } else {
          listas = resultado;
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        mensagemErro = 'Erro ao buscar listas: $e';
        listas = [];
      });
    }
  }

  void _filtrarDataPersonalizada() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );

    if (picked != null) {
      setState(() {
        isLoading = true;
        mensagemErro = '';
      });

      try {
        QuerySnapshot querySnapshot = await _firestore
            .collection('listas_finalizadas')
            .where('dataFinalizacao',
                isGreaterThanOrEqualTo: Timestamp.fromDate(picked.start))
            .where('dataFinalizacao',
                isLessThanOrEqualTo: Timestamp.fromDate(picked.end))
            .get();

        List<Map<String, dynamic>> resultado = querySnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'titulo': doc['titulo'] ?? 'Título não informado',
            'dataFinalizacao': doc['dataFinalizacao'] != null
                ? (doc['dataFinalizacao'] as Timestamp).toDate().toIso8601String()
                : null,
            'valor_total': doc['valor_total']?.toDouble() ?? 0.0,
          };
        }).toList();

        setState(() {
          isLoading = false;
          if (resultado.isEmpty) {
            mensagemErro = 'Nenhuma lista de compras encontrada para esta data.';
            listas = [];
          } else {
            listas = resultado;
          }
        });
      } catch (e) {
        setState(() {
          isLoading = false;
          mensagemErro = 'Erro ao buscar listas: $e';
          listas = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'GASTO TOTAL',
            style: TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFilterButton(
                  context, 'MÊS ATUAL', Icons.calendar_today, _filtrarMesAtual),
              _buildFilterButton(context, 'MÊS ANTERIOR', Icons.calendar_month,
                  _filtrarMesAnterior),
              _buildFilterButton(context, 'DATA PERSONALIZADA', Icons.date_range,
                  _filtrarDataPersonalizada),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : mensagemErro.isNotEmpty
                    ? Center(child: Text(mensagemErro))
                    : ListView.builder(
                        itemCount: listas.length,
                        itemBuilder: (context, index) {
                          return _buildListItem(context, listas[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 12, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(fontSize: 10),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, Map<String, dynamic> lista) {
    String dataFinalizacao = '';
    if (lista['dataFinalizacao'] != null) {
      DateTime data = DateTime.parse(lista['dataFinalizacao']);
      dataFinalizacao = DateFormat('dd/MM/yyyy').format(data);
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    lista['titulo'] ?? 'Título não informado',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DetalhesListaScreen(listaFinalizadaId: lista['id']),
                      ),
                    );
                  },
                  child: const Text('VERIFICA A LISTA',
                      style: TextStyle(fontSize: 10)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
              ],
            ),
            const Divider(height: 16, thickness: 0.8),
            Text(
              'Data: $dataFinalizacao',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 4),
            Text(
          'Valor total gasto: R\$ ${NumberFormat('#,##0.00', 'pt_BR').format(lista['valor_total'] ?? 0)}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
