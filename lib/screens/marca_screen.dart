import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MarcaScreen extends StatefulWidget {
  @override
  _MarcaScreenState createState() => _MarcaScreenState();
}

class _MarcaScreenState extends State<MarcaScreen> {
  Map<String, bool> _expandedStates = {};
  Map<String, TextEditingController> _marcaControllers = {};
  Map<String, List<String>> _marcasPorProduto = {};
  Map<String, String> _nomesProdutos = {};
  Map<String, String?> _marcasUsadas = {};
  bool _isLoading = true;
  String _errorMessage = '';
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('produtos').get();
      setState(() {
        for (var doc in snapshot.docs) {
          String produtoId = doc.id;
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          _expandedStates[produtoId] = false;
          _marcaControllers[produtoId] = TextEditingController();
          _marcasPorProduto[produtoId] = List<String>.from(data['marcas'] ?? []);
          _nomesProdutos[produtoId] = data['nome'] ?? 'Produto sem nome';
          _marcasUsadas[produtoId] = data['marcaUsada'];
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar produtos: $e');
      setState(() {
        _errorMessage = 'Erro ao carregar produtos. Por favor, tente novamente.';
        _isLoading = false;
      });
    }
  }

  Future<void> _adicionarMarcaParaProduto(String produtoId, String novaMarca) async {
    if (novaMarca.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('produtos').doc(produtoId).update({
          'marcas': FieldValue.arrayUnion([novaMarca])
        });
        setState(() {
          _marcasPorProduto[produtoId]!.add(novaMarca);
        });
        _marcaControllers[produtoId]?.clear();
      } catch (e) {
        print('Erro ao adicionar marca: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar marca. Por favor, tente novamente.')),
        );
      }
    }
  }

  Future<void> _removerMarcaDeProduto(String produtoId, String marca) async {
    try {
      await FirebaseFirestore.instance.collection('produtos').doc(produtoId).update({
        'marcas': FieldValue.arrayRemove([marca])
      });
      setState(() {
        _marcasPorProduto[produtoId]!.remove(marca);
        if (_marcasUsadas[produtoId] == marca) {
          _marcasUsadas[produtoId] = null;
          _atualizarMarcaUsada(produtoId, null);
        }
      });
    } catch (e) {
      print('Erro ao remover marca: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover marca. Por favor, tente novamente.')),
      );
    }
  }

  Future<void> _atualizarMarcaUsada(String produtoId, String? novaMarcaUsada) async {
    try {
      await FirebaseFirestore.instance.collection('produtos').doc(produtoId).update({
        'marcaUsada': novaMarcaUsada
      });
      setState(() {
        _marcasUsadas[produtoId] = novaMarcaUsada;
      });
    } catch (e) {
      print('Erro ao atualizar marca usada: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar marca usada. Por favor, tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 1,
        title: Container(
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                hintText: 'Pesquisar...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red, fontSize: 16)))
              : Container(
                  color: Colors.white,
                  child: ListView.builder(
                    itemCount: _nomesProdutos.length,
                    itemBuilder: (context, index) {
                      String produtoId = _nomesProdutos.keys.elementAt(index);
                      String nomeProduto = _nomesProdutos[produtoId]!;
                      if (!nomeProduto.toLowerCase().contains(_searchQuery.toLowerCase())) {
                        return Container();
                      }
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            ListTile(
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(nomeProduto, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButton<String>(
                                      value: _marcasUsadas[produtoId],
                                      hint: Text('MARCA USADA', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                      isExpanded: true,
                                      items: [
                                        DropdownMenuItem<String>(
                                          value: null,
                                          child: Text('Nenhuma', style: TextStyle(fontSize: 12)),
                                        ),
                                        ..._marcasPorProduto[produtoId]!.map((String marca) {
                                          return DropdownMenuItem<String>(
                                            value: marca,
                                            child: Text(marca, style: TextStyle(fontSize: 12)),
                                          );
                                        }).toList(),
                                      ],
                                      onChanged: (String? newValue) {
                                        _atualizarMarcaUsada(produtoId, newValue);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(_expandedStates[produtoId]! ? Icons.expand_less : Icons.expand_more, size: 20),
                              onTap: () {
                                setState(() {
                                  _expandedStates[produtoId] = !_expandedStates[produtoId]!;
                                });
                              },
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            ),
                            if (_expandedStates[produtoId]!)
                              Padding(
                                padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('NOME DA MARCA', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w500)),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 36,
                                            child: TextField(
                                              controller: _marcaControllers[produtoId],
                                              decoration: InputDecoration(
                                                hintText: 'Digite o nome da marca',
                                                hintStyle: TextStyle(fontSize: 12, color: Colors.black54),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: BorderSide(color: Colors.grey),
                                                ),
                                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                              ),
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Container(
                                          height: 36,
                                          width: 36,
                                          child: ElevatedButton(
                                            onPressed: () => _adicionarMarcaParaProduto(produtoId, _marcaControllers[produtoId]!.text),
                                            child: Icon(Icons.add, size: 18, color: Colors.black),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                side: BorderSide(color: Colors.teal, width: 2),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    ..._marcasPorProduto[produtoId]!.map((marca) => 
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(marca, style: TextStyle(fontSize: 12)),
                                            IconButton(
                                              icon: Icon(Icons.delete, color: Colors.red.shade600, size: 18),
                                              onPressed: () => _removerMarcaDeProduto(produtoId, marca),
                                              padding: EdgeInsets.zero,
                                              constraints: BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ).toList(),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
