import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mercado.dart';
import '../providers/mercado_provider.dart';
import '../providers/nome_de_mercado_provider.dart';
import '../providers/compra_provider.dart';

class SelecionarListaMercadoScreen extends StatefulWidget {
  @override
  _SelecionarListaMercadoScreenState createState() => _SelecionarListaMercadoScreenState();
}

class _SelecionarListaMercadoScreenState extends State<SelecionarListaMercadoScreen> {
  List<Map<String, dynamic>> _listasCompras = [];
  List<Map<String, dynamic>> _listasFinalizadas = [];
  String? _selectedListaId;
  String? _selectedListaFinalizadaId;
  String? _selectedNomeMercado;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _verificarEdicaoEmAndamento();
    _carregarListasCompras();
    _carregarListasFinalizadas();
  }

  Future<void> _carregarListasCompras() async {
    setState(() => _isLoading = true);
    final compraProvider = Provider.of<CompraProvider>(context, listen: false);

    try {
      await compraProvider.carregarListasCompras();
      setState(() {
        _listasCompras = compraProvider.listasCompras;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar listas de compras: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar listas de compras')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _verificarEdicaoEmAndamento() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mercadoProvider = Provider.of<MercadoProvider>(context, listen: false);
      if (mercadoProvider.edicaoEmAndamento) {
        Navigator.pushReplacementNamed(context, '/mercado');
      } else {
        _carregarListasCompras();
        _carregarListasFinalizadas();
      }
    });
  }

  Future<void> _carregarListasFinalizadas() async {
    setState(() => _isLoading = true);
    final mercadoProvider = Provider.of<MercadoProvider>(context, listen: false);
    try {
      _listasFinalizadas = await mercadoProvider.obterTodasListasFinalizadasMercado();
      setState(() => _isLoading = false);
    } catch (e) {
      print('Erro ao carregar listas finalizadas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar listas finalizadas')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Selecionar Lista de Compras',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildListaComprasDropdown(),
                  SizedBox(height: 16),
                  _buildListasFinalizadasDropdown(),
                  SizedBox(height: 16),
                  _buildNomeMercadoDropdown(),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _onContinuePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.teal, width: 2),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Continuar',
                      style: TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildListaComprasDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Selecione uma lista de compras',
        labelStyle: TextStyle(fontSize: 13, color: Colors.grey[700]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      ),
      value: _selectedListaId,
      items: _listasCompras
          .map((lista) {
            if (lista['id'] != null && lista['nome'] != null) {
              return DropdownMenuItem<String>(
                value: lista['id'] as String,
                child: Text(lista['nome'] as String),
              );
            }
            return null;
          })
          .whereType<DropdownMenuItem<String>>() // Filtra itens nulos
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedListaId = value;
          _selectedNomeMercado = null;
        });
      },
    );
  }

 Widget _buildListasFinalizadasDropdown() {
  return DropdownButtonFormField<String?>(
    decoration: InputDecoration(
      labelText: 'Selecione uma lista finalizada (opcional)',
      labelStyle: TextStyle(fontSize: 13, color: Colors.grey[700]),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
    ),
    value: _selectedListaFinalizadaId,
    items: [
      DropdownMenuItem<String?>(
        value: null,
        child: Text('Nenhuma (Nova lista)', style: TextStyle(fontSize: 13)),
      ),
      ..._listasFinalizadas.map((lista) {
        String titulo = lista['titulo'] as String? ?? 'Lista sem título';
        String dataFinalizacao = lista['data_finalizacao'] as String? ?? 'Data desconhecida';
        
        // Extrair apenas a data da string do título, se possível
        String dataFormatada = '';
        if (titulo.contains(' - ')) {
          dataFormatada = titulo.split(' - ').last;
          titulo = titulo.split(' - ').first;
        } else {
          DateTime dataParsed = DateTime.tryParse(dataFinalizacao) ?? DateTime.now();
          dataFormatada = "${dataParsed.day.toString().padLeft(2, '0')}/${dataParsed.month.toString().padLeft(2, '0')}/${dataParsed.year}";
        }
        
        return DropdownMenuItem<String?>(
          value: lista['id'] as String,
          child: Text('$titulo - $dataFormatada', style: TextStyle(fontSize: 13)),
        );
      }).toList(),
    ],
    onChanged: (String? value) {
      setState(() {
        _selectedListaFinalizadaId = value;
      });
    },
  );
}

  Widget _buildNomeMercadoDropdown() {
    return Consumer<NomeDeMercadoProvider>(
      builder: (context, nomeDeMercadoProvider, child) {
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Selecione um mercado',
            labelStyle: TextStyle(fontSize: 13, color: Colors.grey[700]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          ),
          value: _selectedNomeMercado ?? 'Selecione um mercado',
          items: [
            DropdownMenuItem<String>(
              value: 'Selecione um mercado',
              child: Text('Selecione um mercado', style: TextStyle(fontSize: 13)),
            ),
            ...nomeDeMercadoProvider.nomesDeMercado.map((mercado) {
              return DropdownMenuItem<String>(
                value: mercado['nome'] as String,
                child: Text(mercado['nome'] as String, style: TextStyle(fontSize: 13)),
              );
            }).toList(),
          ],
          onChanged: (value) {
            setState(() {
              _selectedNomeMercado = value;
            });
          },
        );
      },
    );
  }

  void _onContinuePressed() async {
    if (_selectedListaId != null && _selectedNomeMercado != null) {
      final mercadoProvider = Provider.of<MercadoProvider>(context, listen: false);
      final compraProvider = Provider.of<CompraProvider>(context, listen: false);
      
      setState(() => _isLoading = true);
      try {
        await compraProvider.carregarComprasPorLista(_selectedListaId!);
        await mercadoProvider.carregarOuCriarListaMercado(_selectedListaId!, _selectedNomeMercado!);

        mercadoProvider.setListaTemporaria(compraProvider.compras.map((compra) => Mercado(
          id: compra.id,
          listaMercadoId: mercadoProvider.listaMercadoAtualId!,
          produtoId: compra.produtoId ?? '',
          nome: compra.nome,
          quantidade: compra.quantidade.toDouble(),
          quantidadeOriginal: compra.quantidade.toDouble(),
          unidade: compra.unidadeMedida ?? 'UNIDADE',
          unidadeMedida: compra.unidadeMedida ?? 'UNIDADE',
          valorUnidade: 0.0,
          valorTotal: 0.0,
          assinado: false,
          editando: false,
          nomeMercado: _selectedNomeMercado,
        )).toList());

        if (_selectedListaFinalizadaId != null) {
          await mercadoProvider.carregarPrecosAnteriores(_selectedListaFinalizadaId);
        }

        mercadoProvider.iniciarEdicao(_selectedListaId!);
        Navigator.pushReplacementNamed(context, '/mercado');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar lista: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, selecione uma lista de compras e um mercado')),
      );
    }
  }
}

