import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/mercado_provider.dart';
import '../providers/nome_de_mercado_provider.dart';
import '../models/mercado.dart';
import 'package:intl/intl.dart';

class MercadoScreen extends StatefulWidget {
  @override
  _MercadoScreenState createState() => _MercadoScreenState();
}

class _MercadoScreenState extends State<MercadoScreen> {
  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  Map<String, TextEditingController> _quantidadeControllers = {};
  Map<String, TextEditingController> _precoControllers = {};

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _quantidadeControllers.values.forEach((controller) => controller.dispose());
    _precoControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mercadoProvider = Provider.of<MercadoProvider>(context);
    double valorTotal = mercadoProvider.calcularValorTotal();

    // Verificação dos produtos carregados
    List<Mercado> listaFiltrada = _getListaFiltrada(mercadoProvider);
    print('Produtos carregados: ${listaFiltrada.map((p) => p.nome).toList()}');

    return WillPopScope(
      onWillPop: () async {
        _voltarParaMenuPrincipal(context);
        return false;
      },
      child: Scaffold(
        appBar: _buildAppBar(context, valorTotal),
        body: GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: _buildBody(listaFiltrada, mercadoProvider),
        ),
      ),
    );
  }

  List<Mercado> _getListaFiltrada(MercadoProvider mercadoProvider) {
    List<Mercado> lista = _searchQuery.isEmpty
        ? mercadoProvider.listaTemporaria
        : mercadoProvider.listaTemporaria.where((mercado) =>
            mercado.nome.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    lista.sort((a, b) {
      if (a.assinado == b.assinado) {
        return 0;
      } else if (!a.assinado && b.assinado) {
        return -1;
      } else {
        return 1;
      }
    });

    return lista;
  }

  AppBar _buildAppBar(BuildContext context, double valorTotal) {
    return AppBar(
      backgroundColor: Colors.teal,
      foregroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => _voltarParaMenuPrincipal(context),
      ),
      title: _buildAppBarTitle(valorTotal),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: _toggleSearch,
        ),
      ],
      bottom: _isSearching ? _buildSearchField() : null,
    );
  }

  Widget _buildAppBarTitle(double valorTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Mercado',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        Row(
          children: [
            const Text(
              'Valor Total:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            Text(
              'R\$ ${valorTotal % 1 == 0 ? valorTotal.toInt() : valorTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  PreferredSize _buildSearchField() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(50),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Pesquisar produto...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: _onSearchChanged,
        ),
      ),
    );
  }

  Widget _buildBody(List<Mercado> listaFiltrada, MercadoProvider mercadoProvider) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: listaFiltrada.isEmpty
                      ? _buildEmptyListMessage()
                      : _buildListView(listaFiltrada, mercadoProvider),
                ),
                const SizedBox(height: 16),
                _buildBottomButtons(context, mercadoProvider),
              ],
            ),
          );
  }

  Widget _buildEmptyListMessage() {
    return const Center(
      child: Text(
        'Nenhum produto encontrado.',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildListView(List<Mercado> listaFiltrada, MercadoProvider mercadoProvider) {
    return ListView.builder(
      itemCount: listaFiltrada.length,
      itemBuilder: (context, index) =>
          _buildProdutoCard(listaFiltrada[index], mercadoProvider, index),
    );
  }

  Widget _buildBottomButtons(BuildContext context, MercadoProvider mercadoProvider) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _finalizarCompra(context, mercadoProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: const BorderSide(color: Colors.teal, width: 1),
              ),
            ),
            child: const Text(
              'Finalizar Compra',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _showCancelConfirmation(context, mercadoProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: const BorderSide(color: Colors.red, width: 1),
              ),
            ),
            child: const Text(
              'Cancelar Compra',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProdutoCard(Mercado mercado, MercadoProvider mercadoProvider, int index) {
    final mercadoAtualizado = mercadoProvider.getMercadoAtual(mercado.id!);

    _quantidadeControllers.putIfAbsent(
      mercado.id!,
      () {
        print('Inicializando quantidade para o produto: ${mercado.nome}');
        return TextEditingController(
          text: mercadoAtualizado.quantidade % 1 == 0
              ? mercadoAtualizado.quantidade.toInt().toString()
              : mercadoAtualizado.quantidade.toString(),
        );
      },
    );
    _precoControllers.putIfAbsent(
      mercado.id!,
      () {
        print('Inicializando preço para o produto: ${mercado.nome}');
        return TextEditingController(text: _formatPrice(mercadoAtualizado.valorUnidade));
      },
    );

    bool podeAssinar = mercadoAtualizado.valorUnidade > 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProdutoHeader(
                mercado, mercadoAtualizado, mercadoProvider, podeAssinar),
            const SizedBox(height: 8),
            TextFormField(
              controller: _quantidadeControllers[mercado.id!],
              enabled: !mercadoAtualizado.assinado,
              decoration: InputDecoration(
                labelText: 'Quantidade',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                fillColor: Colors.grey[100],
                filled: true,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                if (!mercadoAtualizado.assinado) {
                  double quantidade = double.tryParse(value) ?? 0;
                  mercadoProvider.atualizarQuantidade(
                    mercadoAtualizado.id!,
                    quantidade % 1 == 0 ? quantidade.toInt().toDouble() : quantidade,
                  );
                  setState(() {}); // Atualiza a interface
                }
              },
            ),
            const SizedBox(height: 8),
            _buildPrecosFields(mercadoAtualizado, mercado, mercadoProvider),
            const SizedBox(height: 8),
            _buildMercadoDropdown(mercado, mercadoAtualizado, mercadoProvider, context),
          ],
        ),
      ),
    );
  }

  Widget _buildProdutoHeader(Mercado mercado, Mercado mercadoAtualizado, 
      MercadoProvider mercadoProvider, bool podeAssinar) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            mercado.nome,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        _buildAssinadoCheckbox(mercadoAtualizado, podeAssinar, mercadoProvider),
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'R\$ ${mercadoAtualizado.valorTotal % 1 == 0 ? mercadoAtualizado.valorTotal.toInt() : mercadoAtualizado.valorTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _excluirProduto(context, mercadoProvider, mercado),
        ),
      ],
    );
  }

  Widget _buildAssinadoCheckbox(Mercado mercadoAtualizado, bool podeAssinar, 
      MercadoProvider mercadoProvider) {
    return InkWell(
      onTap: () async {
        if (podeAssinar) {
          await mercadoProvider.atualizarAssinaturaProduto(mercadoAtualizado.id!, !mercadoAtualizado.assinado);
          setState(() {}); // Atualizar a UI após modificar a assinatura
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preencha o Preço Atual para assinar o produto.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Row(
        children: [
          Checkbox(
  value: mercadoAtualizado.assinado,
  onChanged: (value) async {
    if (podeAssinar) {
      try {
        // Atualiza a assinatura localmente, mantendo a lógica de atualização da UI
        await mercadoProvider.atualizarAssinaturaProduto(mercadoAtualizado.id!, !mercadoAtualizado.assinado);
        
        setState(() {}); // Atualizar a UI após modificar a assinatura
      } catch (e) {
        // Captura erros e exibe uma mensagem de erro, caso necessário
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao assinar o produto: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha o Preço Atual para assinar o produto.'),
          duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          const Text('COMPRADO', style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPrecosFields(Mercado mercadoAtualizado, Mercado mercado, MercadoProvider mercadoProvider) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _precoControllers[mercado.id!],
            enabled: !mercadoAtualizado.assinado,
            decoration: InputDecoration(
              labelText: 'Preço Atual',
              prefixText: 'R\$ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              fillColor: Colors.grey[100],
              filled: true,
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: mercadoAtualizado.assinado ? Colors.grey : Colors.black,
            ),
            onChanged: (value) {
              if (!mercadoAtualizado.assinado) {
                double preco = double.tryParse(value) ?? 0;
                mercadoProvider.atualizarPreco(mercadoAtualizado.id!, preco);
                setState(() {}); // Atualiza a interface
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            enabled: false,
            initialValue: mercado.precoAnterior != null
                ? _formatPrice(mercado.precoAnterior!)
                : '',
            decoration: InputDecoration(
              labelText: 'Preço Anterior',
              prefixText: 'R\$ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              fillColor: Colors.grey[100],
              filled: true,
            ),
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildMercadoDropdown(Mercado mercado, Mercado mercadoAtualizado, 
      MercadoProvider mercadoProvider, BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Mercado',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        fillColor: Colors.grey[100],
        filled: true,
      ),
      value: mercado.nomeMercado,
      items: Provider.of<NomeDeMercadoProvider>(context, listen: false)
          .nomesDeMercado
          .map((mercadoItem) {
        return DropdownMenuItem<String>(
          value: mercadoItem['nome'] as String,
          child: Text(
            mercadoItem['nome'] as String,
            style: const TextStyle(fontSize: 12, color: Colors.black),
          ),
        );
      }).toList(),
      onChanged: mercadoAtualizado.assinado
          ? null
          : (value) {
              mercadoProvider.atualizarMercadoProduto(mercado.id!, value);
              setState(() {}); // Atualiza a interface
            },
      style: const TextStyle(fontSize: 12, color: Colors.black),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
    );
  }

  void _toggleSearch() {
    setState(() {
      if (_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
      _isSearching = !_isSearching;
    });
  }

  void _voltarParaMenuPrincipal(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _excluirProduto(
      BuildContext context, MercadoProvider mercadoProvider, Mercado mercado) async {
    if (mercado.assinado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produto assinado não pode ser excluído.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final bool? confirmacao = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content:
              Text('Tem certeza que deseja excluir "${mercado.nome}" da lista?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Excluir'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmacao == true) {
      setState(() => _isLoading = true);
      try {
        await mercadoProvider.excluirProduto(mercado.id!);
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto excluído com sucesso')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir produto: $e')),
          );
        }
      }
    }
  }

  Future<void> _finalizarCompra(
      BuildContext context, MercadoProvider mercadoProvider) async {
    if (!mercadoProvider.todosProdutosAssinados()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, assine todos os produtos antes de finalizar.')),
      );
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Finalizar Compra'),
          content: const Text(
              'Tem certeza que deseja finalizar esta compra? Isso salvará todos os dados atuais para futuras comparações.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Finalizar'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await mercadoProvider.finalizarListaMercado();
        mercadoProvider.finalizarEdicao();
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Compra finalizada com sucesso!')),
          );
          Navigator.pushReplacementNamed(context, '/selecionar_lista_mercado');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao finalizar compra: $e')),
          );
        }
      }
    }
  }

  Future<void> _showCancelConfirmation(
      BuildContext context, MercadoProvider mercadoProvider) async {
    final bool? shouldCancel = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancelar Compra'),
          content: const Text(
              'Tem certeza que deseja cancelar a compra? Todas as alterações serão perdidas.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Não'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Sim, Cancelar'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true) {
      mercadoProvider.resetState(forceReset: true);
      mercadoProvider.finalizarEdicao();
      mercadoProvider.clearListaTemporaria();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compra cancelada. Os dados não foram salvos.')),
      );

      Navigator.pushReplacementNamed(context, '/selecionar_lista_mercado');
    }
  }

  String _formatPrice(double price) {
    return price % 1 == 0 ? price.toInt().toString() : price.toStringAsFixed(2);
  }
}
