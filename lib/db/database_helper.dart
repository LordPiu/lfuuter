// lib/db/database_helper.dart

import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';
import '../models/produto.dart';
import '../models/compra.dart';
import '../models/mercado.dart';

class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._init();

  // Logger para depuração
  final Logger logger = Logger();

  // Instância do banco de dados
  static Database? _database;

  // Construtor privado
  DatabaseHelper._init();

  // Getter para obter a instância do banco de dados
  Future<Database> get database async {
    if (_database != null) return _database!;
    logger.i('Iniciando a abertura do banco de dados');
    _database = await _initDB('estoque.db');
    logger.i('Banco de dados aberto com sucesso: $_database');
    return _database!;
  }

  // Método para inicializar o banco de dados
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 24, // Atualize a versão conforme necessário
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      readOnly: false,
      singleInstance: true,
    );
  }

  // Método para criar o banco de dados
  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL';
    const integerType = 'INTEGER NOT NULL';

    // Criação da tabela 'categorias'
    await db.execute('''
      CREATE TABLE categorias (
        id $idType,
        nome $textType
      )
    ''');

    // Criação da tabela 'produtos'
    await db.execute('''
      CREATE TABLE produtos (
        id $idType,
        nome $textType,
        unidadeMedida $textType,
        kgPorUnidade $realType,
        categoria_id INTEGER,
        FOREIGN KEY (categoria_id) REFERENCES categorias (id)
      )
    ''');

    // Criação da tabela 'listas_compras'
    await db.execute('''
      CREATE TABLE listas_compras (
        id $idType,
        data_criacao $textType,
        nome $textType
      )
    ''');

    // Criação da tabela 'compras'
    await db.execute('''
  CREATE TABLE compras (
    id $idType,
    lista_id $integerType,
    produto_id $integerType,
    quantidade $realType,
    data $textType,
    unidadeMedida $textType,
    kgPorUnidade $realType,
    FOREIGN KEY (lista_id) REFERENCES listas_compras (id) ON DELETE CASCADE,
    FOREIGN KEY (produto_id) REFERENCES produtos (id) ON DELETE CASCADE
  )
''');

    // Criação da tabela 'mercado'
    await db.execute('''
      CREATE TABLE mercado (
        id $idType,
        lista_id $integerType,
        compra_id $integerType,
        produto_id $integerType,
        nome $textType,
        comprado INTEGER DEFAULT 0,
        quantidade $realType,
        quantidade_original $realType,
        unidade TEXT,
        valor_unidade $realType,
        valor_total $realType,
        data_compra $textType,
        FOREIGN KEY (lista_id) REFERENCES listas_compras (id) ON DELETE CASCADE,
        FOREIGN KEY (compra_id) REFERENCES compras (id) ON DELETE CASCADE,
        FOREIGN KEY (produto_id) REFERENCES produtos (id) ON DELETE CASCADE
      )
    ''');

    // Criação da tabela 'historico_compras'
    await db.execute('''
      CREATE TABLE historico_compras (
        id $idType,
        produto_id $integerType,
        quantidade $realType,
        valor_total $realType,
        data_compra $textType,
        FOREIGN KEY (produto_id) REFERENCES produtos (id) ON DELETE CASCADE
      )
    ''');

    // Criação da tabela 'listas_mercado'
    await db.execute('''
      CREATE TABLE listas_mercado (
        id $idType,
        lista_compras_id $integerType NOT NULL,
        data_criacao $textType NOT NULL,
        nome $textType NOT NULL,
        nome_mercado TEXT,
        finalizada INTEGER DEFAULT 0,
        FOREIGN KEY (lista_compras_id) REFERENCES listas_compras (id) ON DELETE CASCADE
      )
    ''');

    // Criação da tabela 'mercado_itens'
    await db.execute('''
  CREATE TABLE mercado_itens (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    lista_mercado_id INTEGER NOT NULL,
    produto_id INTEGER NOT NULL,
    nome TEXT NOT NULL,
    quantidade REAL,
    quantidade_original REAL,
    unidade TEXT,
    unidadeMedida TEXT NOT NULL DEFAULT 'unidade',
    kgPorUnidade REAL,
    valor_unidade REAL,
    valor_total REAL,
    comprado INTEGER DEFAULT 0,
    data_compra TEXT NOT NULL,
    assinado INTEGER DEFAULT 0,
    nome_mercado TEXT,
    preco_anterior REAL,
    ordem INTEGER DEFAULT 0,
    FOREIGN KEY (lista_mercado_id) REFERENCES listas_mercado (id) ON DELETE CASCADE,
    FOREIGN KEY (produto_id) REFERENCES produtos (id) ON DELETE CASCADE
  )
''');

    // Criação da tabela 'listas_finalizadas'
    await db.execute('''
      CREATE TABLE listas_finalizadas (
        id $idType,
        lista_mercado_id $integerType,
        data_finalizacao $textType,
        titulo $textType,
        valor_total $realType,
        FOREIGN KEY (lista_mercado_id) REFERENCES listas_mercado (id) ON DELETE CASCADE
      )
    ''');

    // Criação da tabela 'itens_lista_finalizada'
    await db.execute('''
      CREATE TABLE itens_lista_finalizada (
        id $idType,
        lista_finalizada_id $integerType,
        produto_id $integerType,
        nome $textType,
        quantidade_comprada $realType,
        preco_unidade $realType,
        valor_total $realType,
        nome_mercado TEXT,
        FOREIGN KEY (lista_finalizada_id) REFERENCES listas_finalizadas (id) ON DELETE CASCADE,
        FOREIGN KEY (produto_id) REFERENCES produtos (id) ON DELETE CASCADE
      )
    ''');

    // Criação da tabela 'nomes_de_mercado'
    await db.execute('''
      CREATE TABLE nomes_de_mercado (
        id $idType,
        nome $textType
      )
    ''');

    // Criação de índices para otimizar consultas
    await _createIndexes(db);
  }

  // Método para criar índices
  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_compras_lista_id ON compras (lista_id)');
    await db.execute('CREATE INDEX idx_compras_produto_id ON compras (produto_id)');
    await db.execute('CREATE INDEX idx_mercado_lista_id ON mercado (lista_id)');
    await db.execute('CREATE INDEX idx_mercado_compra_id ON mercado (compra_id)');
    await db.execute('CREATE INDEX idx_mercado_produto_id ON mercado (produto_id)');
    await db.execute('CREATE INDEX idx_mercado_data_compra ON mercado (data_compra)');
    await db.execute('CREATE INDEX idx_historico_produto_id ON historico_compras (produto_id)');
    await db.execute('CREATE INDEX idx_historico_data_compra ON historico_compras (data_compra)');
    await db.execute('CREATE INDEX idx_mercado_itens_lista_mercado_id ON mercado_itens (lista_mercado_id)');
    await db.execute('CREATE INDEX idx_mercado_itens_produto_id ON mercado_itens (produto_id)');
    await db.execute('CREATE INDEX idx_listas_finalizadas_lista_mercado_id ON listas_finalizadas (lista_mercado_id)');
    await db.execute('CREATE INDEX idx_itens_lista_finalizada_lista_finalizada_id ON itens_lista_finalizada (lista_finalizada_id)');
    await db.execute('CREATE INDEX idx_itens_lista_finalizada_produto_id ON itens_lista_finalizada (produto_id)');
  }

  // Método para atualizar o banco de dados
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 19) {
      await db.execute('ALTER TABLE produtos ADD COLUMN unidadeMedida TEXT NOT NULL DEFAULT "unidade"');
      await db.execute('ALTER TABLE produtos ADD COLUMN kgPorUnidade REAL');
    }
    if (oldVersion < 20) {
      await db.execute('ALTER TABLE mercado_itens ADD COLUMN unidadeMedida TEXT NOT NULL DEFAULT "unidade"');
      await db.execute('ALTER TABLE mercado_itens ADD COLUMN kgPorUnidade REAL');
    }
    if (oldVersion < 21) {
      await db.execute('''
        CREATE TABLE nomes_de_mercado (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 22) {
      await db.execute('ALTER TABLE produtos ADD COLUMN categoria_id INTEGER');
    }
    if (oldVersion < 23) {
      await db.execute('ALTER TABLE mercado_itens ADD COLUMN assinado INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE mercado_itens ADD COLUMN nome_mercado TEXT');
      await db.execute('ALTER TABLE mercado_itens ADD COLUMN preco_anterior REAL');
      await db.execute('ALTER TABLE itens_lista_finalizada ADD COLUMN nome_mercado TEXT');
      await db.execute('ALTER TABLE mercado_itens ADD COLUMN ordem INTEGER DEFAULT 0');
    }
    if (oldVersion < 24) { // Aumente a versão para 24
      // Adiciona as novas colunas à tabela compras se elas não existirem
      await db.execute('ALTER TABLE compras ADD COLUMN unidadeMedida TEXT');
      await db.execute('ALTER TABLE compras ADD COLUMN kgPorUnidade REAL');
    }
  }
  // ----------------------------
  // Métodos para gerenciar categorias
  // ----------------------------

  /// Obtém todas as categorias ordenadas pelo nome
  Future<List<Map<String, dynamic>>> getCategorias() async {
    final db = await database;
    final result = await db.query('categorias', orderBy: 'nome');
    return result;
  }

  /// Insere uma nova categoria
  Future<int> insertCategoria(Map<String, dynamic> categoria) async {
    final db = await database;
    return await db.insert('categorias', categoria);
  }

  /// Deleta uma categoria pelo ID
  Future<int> deleteCategoria(int id) async {
    final db = await database;
    return await db.delete('categorias', where: 'id = ?', whereArgs: [id]);
  }

  // ----------------------------
  // Métodos para gerenciar produtos
  // ----------------------------

  /// Obtém todos os produtos
  Future<List<Produto>> getProdutos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('produtos');
    logger.i('Buscando todos os produtos');

    if (maps.isEmpty) {
      logger.i('Nenhum produto encontrado no banco de dados.');
    } else {
      logger.i('Produtos encontrados: ${maps.length}');
    }

    return List.generate(maps.length, (i) {
      return Produto.fromMap(maps[i]);
    });
  }

  /// Insere um novo produto
  Future<int> insertProduto(Produto produto) async {
    final db = await database;
    final result = await db.insert('produtos', produto.toMap());
    logger.i('Produto inserido: ${produto.nome}, ID: $result');
    return result;
  }

  /// Atualiza um produto existente
  Future<int> updateProduto(Produto produto) async {
    final db = await database;
    final result = await db.update(
      'produtos',
      produto.toMap(),
      where: 'id = ?',
      whereArgs: [produto.id],
    );
    logger.i('Produto atualizado: ${produto.nome}, ID: ${produto.id}');
    return result;
  }

  /// Deleta um produto pelo ID
  Future<int> deleteProduto(int id) async {
    final db = await database;
    final result = await db.delete(
      'produtos',
      where: 'id = ?',
      whereArgs: [id],
    );
    logger.i('Produto deletado, ID: $id');
    return result;
  }

  // ----------------------------
  // Métodos para gerenciar compras
  // ----------------------------

  /// Insere uma nova compra associada a uma lista
  Future<int> insertCompra(Compra compra) async {
    final db = await database;
    final compraMap = compra.toMap();
    final result = await db.insert('compras', compraMap);
    logger.i('Compra inserida: Produto ID ${compra.produtoId}, ID: $result');
    return result;
  }

  /// Obtém todas as compras de uma determinada lista
  Future<List<Compra>> getComprasPorLista(int listaId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT c.*, p.nome as produto_nome
      FROM compras c
      JOIN produtos p ON c.produto_id = p.id
      WHERE c.lista_id = ?
    ''', [listaId]);
    logger.i('Buscando compras da lista, ID: $listaId');
    return List.generate(maps.length, (i) {
      return Compra.fromMap({
        ...maps[i],
        'nome': maps[i]['produto_nome'],
      });
    });
  }

  /// Atualiza uma compra existente
  Future<int> updateCompra(Compra compra) async {
    final db = await database;
    final compraMap = compra.toMap();
    // Remove campos nulos para evitar erros de atualização
    compraMap.removeWhere((key, value) => value == null);
    final result = await db.update(
      'compras',
      compraMap,
      where: 'id = ?',
      whereArgs: [compra.id],
    );
    logger.i('Compra atualizada: Produto ID ${compra.produtoId}, ID: ${compra.id}');
    return result;
  }

  /// Deleta uma compra pelo ID
  Future<int> deleteCompra(int id) async {
    final db = await database;
    return await db.delete(
      'compras',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Cria uma nova lista de compras com produtos associados
  Future<int> criarListaCompras(String titulo, List<Map<String, dynamic>> produtos) async {
    final db = await database;
    int listaId = 0;
    await db.transaction((txn) async {
      listaId = await txn.insert('listas_compras', {
        'data_criacao': DateTime.now().toIso8601String(),
        'nome': titulo,
      });

      for (var produto in produtos) {
        await txn.insert('compras', {
          'lista_id': listaId,
          'produto_id': produto['produto_id'],
          'quantidade': produto['quantidade'],
          'data': DateTime.now().toIso8601String(),
        });
      }
    });
    logger.i('Nova lista de compras criada: $titulo, ID: $listaId');
    return listaId;
  }

  /// Obtém todas as listas de compras
  Future<List<Map<String, dynamic>>> getListasCompras() async {
    final db = await database;
    final result = await db.query('listas_compras', orderBy: 'data_criacao DESC');
    logger.i('Buscando todas as listas de compras');
    return result;
  }

  /// Obtém todos os produtos de uma determinada lista de compras
  Future<List<Map<String, dynamic>>> getProdutosListaCompras(int listaId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT c.*, p.nome, p.unidadeMedida, p.kgPorUnidade
      FROM compras c
      JOIN produtos p ON c.produto_id = p.id
      WHERE c.lista_id = ?
    ''', [listaId]);
    logger.i('Buscando produtos da lista de compras, ID: $listaId');
    return result;
  }

  // ----------------------------
  // Métodos para gerenciar mercado
  // ----------------------------

  /// Insere um novo item de mercado
  Future<int> insertMercado(Mercado mercado) async {
    final db = await database;
    final mercadoMap = mercado.toMap();
    mercadoMap['data_compra'] = DateTime.now().toIso8601String();
    final result = await db.insert('mercado', mercadoMap);
    logger.i('Item de mercado inserido: ${mercado.nome}, ID: $result');

    // Adiciona ao histórico de compras
    await _addHistoricoCompra(
      mercado.produtoId,
      mercado.quantidade,
      mercado.valorTotal,
      mercadoMap['data_compra'],
    );

    return result;
  }

  /// Obtém todos os itens de mercado de uma determinada lista
  Future<List<Mercado>> getMercadoPorLista(int listaId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT m.*, c.produto_id, p.nome
      FROM mercado m
      JOIN compras c ON m.compra_id = c.id
      JOIN produtos p ON c.produto_id = p.id
      WHERE m.lista_id = ?
    ''', [listaId]);
    logger.i('Buscando itens de mercado da lista, ID: $listaId');
    return List.generate(maps.length, (i) {
      return Mercado.fromMap({
        ...maps[i],
        'nome': maps[i]['nome'],
      });
    });
  }

  /// Atualiza um item de mercado existente
  Future<int> updateMercado(Mercado mercado) async {
    final db = await database;
    final mercadoMap = mercado.toMap();
    mercadoMap['data_compra'] = DateTime.now().toIso8601String();

    final result = await db.update(
      'mercado',
      mercadoMap,
      where: 'id = ?',
      whereArgs: [mercado.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    logger.i('Item de mercado atualizado: ${mercado.nome}, ID: ${mercado.id}');

    // Adiciona ao histórico de compras
    await _addHistoricoCompra(
      mercado.produtoId,
      mercado.quantidade,
      mercado.valorTotal,
      mercadoMap['data_compra'],
    );

    return result;
  }

  /// Deleta um item de mercado pelo ID
  Future<int> deleteMercado(int id) async {
    final db = await database;
    final result = await db.delete(
      'mercado',
      where: 'id = ?',
      whereArgs: [id],
    );
    logger.i('Item de mercado deletado, ID: $id');
    return result;
  }

  // ----------------------------
  // Métodos auxiliares para histórico
  // ----------------------------

  /// Adiciona uma entrada no histórico de compras
  Future<int> _addHistoricoCompra(int produtoId, double quantidade, double valorTotal, String dataCompra) async {
    final db = await database;
    final historico = {
      'produto_id': produtoId,
      'quantidade': quantidade,
      'valor_total': valorTotal,
      'data_compra': dataCompra,
    };
    final result = await db.insert('historico_compras', historico);
    logger.i('Histórico de compra adicionado: Produto ID: $produtoId, Data: $dataCompra');
    return result;
  }

  /// Obtém o histórico de compras de um produto específico
  Future<List<Map<String, dynamic>>> getHistoricoCompraProduto(int produtoId) async {
    final db = await database;
    final result = await db.query(
      'historico_compras',
      where: 'produto_id = ?',
      whereArgs: [produtoId],
      orderBy: 'data_compra DESC',
    );
    logger.i('Buscando histórico de compras do produto ID: $produtoId');
    return result;
  }

  // ----------------------------
  // Métodos para comparações e análises
  // ----------------------------

  /// Compara gastos em um determinado período
  Future<Map<String, double>> compararGastosPeriodo(String dataInicio, String dataFim) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(valor_total) as total_gasto, strftime('%Y-%m', data_compra) as mes
      FROM mercado
      WHERE data_compra BETWEEN ? AND ?
      GROUP BY mes
      ORDER BY mes
    ''', [dataInicio, dataFim]);

    logger.i('Comparando gastos no período: $dataInicio a $dataFim');
    return Map.fromEntries(result.map((r) => MapEntry(r['mes'] as String, r['total_gasto'] as double)));
  }

  /// Obtém a quantidade comprada de um produto em um período específico
  Future<List<Map<String, dynamic>>> getQuantidadeCompradaProdutoPorPeriodo(int produtoId, String dataInicio, String dataFim) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(quantidade) as total_quantidade, strftime('%Y-%m', data_compra) as mes
      FROM historico_compras
      WHERE produto_id = ? AND data_compra BETWEEN ? AND ?
      GROUP BY mes
      ORDER BY mes
    ''', [produtoId, dataInicio, dataFim]);

    logger.i('Buscando quantidade comprada do produto ID: $produtoId no período: $dataInicio a $dataFim');
    return result;
  }

  // ----------------------------
  // Métodos para gerenciar listas de mercado
  // ----------------------------


  Future<void> atualizarNomeLista(int listaId, String novoNome) async {
    final db = await database;
    await db.update(
      'listas_compras',
      {'nome': novoNome},
      where: 'id = ?',
      whereArgs: [listaId],
    );
  }

  Future<void> adicionarCompraALista(int listaId, Compra compra) async {
    final db = await database;
    await db.insert('compras', {
      ...compra.toMap(),
      'lista_id': listaId,
    });
  }


  /// Cria uma nova lista de mercado
  Future<int> criarListaMercado(int listaComprasId, String nome, String? nomeMercado) async {
    final db = await database;
    final listaMercadoId = await db.insert('listas_mercado', {
      'lista_compras_id': listaComprasId,
      'data_criacao': DateTime.now().toIso8601String(),
      'nome': nome,
      'nome_mercado': nomeMercado,
    });
    logger.i('Nova lista de mercado criada: $nome, ID: $listaMercadoId');
    return listaMercadoId;
  }

  /// Obtém todas as listas de mercado
  Future<List<Map<String, dynamic>>> getListasMercado() async {
    final db = await database;
    final result = await db.query('listas_mercado', orderBy: 'data_criacao DESC');
    logger.i('Buscando todas as listas de mercado');
    return result;
  }

  /// Obtém todos os itens de mercado de uma lista específica
  Future<List<Map<String, dynamic>>> getMercadoItensPorLista(int listaMercadoId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT mi.*, p.unidadeMedida, p.kgPorUnidade
      FROM mercado_itens mi
      JOIN produtos p ON mi.produto_id = p.id
      WHERE mi.lista_mercado_id = ?
    ''', [listaMercadoId]);
    logger.i('Buscando itens da lista de mercado, ID: $listaMercadoId');
    return result;
  }

  /// Insere um novo item na lista de mercado
  Future<int> insertMercadoItem(Map<String, dynamic> item) async {
    final db = await database;
    item['data_compra'] = item['data_compra'] ?? DateTime.now().toIso8601String();
    final result = await db.insert('mercado_itens', item);
    logger.i('Item de mercado inserido: ${item['nome']}, ID: $result');
    return result;
  }

  /// Atualiza um item na lista de mercado
  Future<int> updateMercadoItem(Map<String, dynamic> item) async {
    final db = await database;

    // Remover apenas campos que não devem ser atualizados
    item.remove('compra_id');

    final result = await db.update(
      'mercado_itens',
      item,
      where: 'id = ?',
      whereArgs: [item['id']],
    );
    logger.i('Item de mercado atualizado: ${item['nome']}, ID: ${item['id']}');
    return result;
  }

  /// Finaliza uma lista de mercado
  Future<int> finalizarListaMercado(int listaMercadoId) async {
    final db = await database;
    final result = await db.update(
      'listas_mercado',
      {'finalizada': 1},
      where: 'id = ?',
      whereArgs: [listaMercadoId],
    );
    logger.i('Lista de mercado finalizada, ID: $listaMercadoId');
    return result;
  }

  // ----------------------------
  // Métodos para gerenciar listas finalizadas
  // ----------------------------

  /// Cria uma lista finalizada com seus itens
  Future<int> criarListaFinalizada(int listaMercadoId, List<Map<String, dynamic>> itens, double valorTotal, String titulo) async {
    final db = await database;
    final batch = db.batch();

    final listaFinalizadaId = await db.insert('listas_finalizadas', {
      'lista_mercado_id': listaMercadoId,
      'data_finalizacao': DateTime.now().toIso8601String(),
      'titulo': titulo,
      'valor_total': valorTotal,
    });

    for (var item in itens) {
      batch.insert('itens_lista_finalizada', {
        'lista_finalizada_id': listaFinalizadaId,
        'produto_id': item['produto_id'],
        'nome': item['nome'],
        'quantidade_comprada': item['quantidade_comprada'],
        'preco_unidade': item['preco_unidade'],
        'valor_total': item['valor_total'],
        'nome_mercado': item['nome_mercado'],
      });
    }

    await batch.commit();
    logger.i('Lista finalizada criada: $titulo, ID: $listaFinalizadaId');
    return listaFinalizadaId;
  }

  /// Obtém todas as listas finalizadas
  Future<List<Map<String, dynamic>>> obterListasFinalizadas() async {
    final db = await database;
    return await db.query('listas_finalizadas', orderBy: 'data_finalizacao DESC');
  }

  /// Obtém os detalhes de uma lista finalizada específica
  Future<Map<String, dynamic>> obterDetalhesListaFinalizada(int listaFinalizadaId) async {
    final db = await database;
    final listaFinalizada = await db.query(
      'listas_finalizadas',
      where: 'id = ?',
      whereArgs: [listaFinalizadaId],
    );
    final itens = await db.query(
      'itens_lista_finalizada',
      where: 'lista_finalizada_id = ?',
      whereArgs: [listaFinalizadaId],
    );

    logger.i('Obtendo detalhes da lista finalizada, ID: $listaFinalizadaId');
    return {
      'detalhes': listaFinalizada.first,
      'itens': itens,
    };
  }

  /// Obtém todas as listas finalizadas do mercado com seus itens
Future<List<Map<String, dynamic>>> obterTodasListasFinalizadasMercado() async {
  final db = await database;
  final listasFinalizadas = await db.rawQuery('''
    SELECT lf.*, lc.nome AS nome_lista_compras
    FROM listas_finalizadas lf
    LEFT JOIN listas_mercado lm ON lf.lista_mercado_id = lm.id
    LEFT JOIN listas_compras lc ON lm.lista_compras_id = lc.id
  ''');
  logger.i('Listas finalizadas encontradas: ${listasFinalizadas.length}');

  List<Map<String, dynamic>> resultado = [];

  for (var lista in listasFinalizadas) {
    final itens = await db.query(
      'itens_lista_finalizada',
      where: 'lista_finalizada_id = ?',
      whereArgs: [lista['id']],
    );
    logger.i('Itens para lista ${lista['id']}: ${itens.length}');
    resultado.add({
      ...lista,
      'itens': itens,
    });
  }

  logger.i('Total de listas com itens: ${resultado.length}');
  return resultado;
}

  /// Obtém todas as listas finalizadas dentro de um período específico
  Future<List<Map<String, dynamic>>> obterListasFinalizadasPorPeriodo(DateTime inicio, DateTime fim) async {
  final db = await database;
  final result = await db.query(
    'listas_finalizadas',
    where: 'data_finalizacao BETWEEN ? AND ?',
    whereArgs: [inicio.toIso8601String(), fim.toIso8601String()],
    orderBy: 'data_finalizacao DESC',
  );
  print('Listas obtidas para o período ${inicio.toString()} a ${fim.toString()}: ${result.length}');
  return result;
}

  /// Compara uma lista planejada com uma lista finalizada
  Future<Map<String, dynamic>> compararListasPlanejadaEFinalizada(int listaComprasId, int listaFinalizadaId) async {
    final db = await database;
    final listaCompras = await getProdutosListaCompras(listaComprasId);
    final listaFinalizada = await db.query(
      'itens_lista_finalizada',
      where: 'lista_finalizada_id = ?',
      whereArgs: [listaFinalizadaId],
    );

    Map<int, Map<String, dynamic>> comparacao = {};

    for (var item in listaCompras) {
      comparacao[item['produto_id'] as int] = {
        'nome': item['nome'],
        'quantidade_planejada': item['quantidade'],
        'quantidade_comprada': 0,
        'preco_planejado': 0,
        'preco_pago': 0,
        'valor_planejado': 0,
        'valor_gasto': 0,
      };
    }

    for (var item in listaFinalizada) {
      int produtoId = item['produto_id'] as int;
      if (comparacao.containsKey(produtoId)) {
        comparacao[produtoId]!['quantidade_comprada'] = item['quantidade_comprada'];
        comparacao[produtoId]!['preco_pago'] = item['preco_unidade'];
        comparacao[produtoId]!['valor_gasto'] = item['valor_total'];
      }
    }

    logger.i('Comparação entre lista de compras $listaComprasId e lista finalizada $listaFinalizadaId realizada');
    return {
      'itens': comparacao.values.toList(),
      'total_planejado': comparacao.values.fold(0.0, (sum, item) => sum + (item['valor_planejado'] as double)),
      'total_gasto': comparacao.values.fold(0.0, (sum, item) => sum + (item['valor_gasto'] as double)),
    };
  }

  // ----------------------------
  // Métodos para gerenciar nomes de mercado
  // ----------------------------

  /// Obtém todos os nomes de mercado
  Future<List<Map<String, dynamic>>> getNomesDeMercado() async {
    final db = await database;
    return await db.query('nomes_de_mercado', orderBy: 'nome');
  }

  /// Insere um novo nome de mercado
  Future<int> insertNomeDeMercado(String nome) async {
    try {
      final db = await database;
      logger.i('Tentando inserir nome de mercado: $nome');
      final result = await db.insert('nomes_de_mercado', {'nome': nome});
      logger.i('Nome de mercado inserido com sucesso. ID: $result');
      return result;
    } catch (e, stackTrace) {
      logger.e('Erro ao inserir nome de mercado: $e');
      logger.e('Stack trace: $stackTrace');
      throw Exception('Falha ao inserir nome de mercado: $e');
    }
  }

  /// Atualiza um nome de mercado existente
  Future<int> updateNomeDeMercado(int id, String novoNome) async {
    final db = await database;
    return await db.update(
      'nomes_de_mercado',
      {'nome': novoNome},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deleta um nome de mercado pelo ID
  Future<int> deleteNomeDeMercado(int id) async {
    final db = await database;
    return await db.delete(
      'nomes_de_mercado',
      where: 'id = ?',
      whereArgs: [id],
    );
  }



/// Para produtos assinalados irem para final
  Future<void> atualizarOrdemProduto(int id, int ordem) async {
    final db = await database;
    await db.update(
      'mercado_itens',
      {'ordem': ordem},
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  // ----------------------------
  // Método para obter listas finalizadas por lista de compras
  // ----------------------------

  /// Obtém todas as listas finalizadas associadas a uma lista de compras específica
  Future<List<Map<String, dynamic>>> obterListasFinalizadasPorListaCompras(int listaComprasId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT lf.*
      FROM listas_finalizadas lf
      JOIN listas_mercado lm ON lf.lista_mercado_id = lm.id
      WHERE lm.lista_compras_id = ?
      ORDER BY lf.data_finalizacao DESC
    ''', [listaComprasId]);
    logger.i('Obtendo listas finalizadas para a lista de compras ID: $listaComprasId');
    return result;
  }
}
