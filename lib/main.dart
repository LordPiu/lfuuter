import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

// Imports de providers
import 'providers/compra_provider.dart';
import 'providers/produto_provider.dart';
import 'providers/mercado_provider.dart';
import 'providers/gasto_semanal_provider.dart';
import 'providers/nome_de_mercado_provider.dart';
import 'providers/categoria_provider.dart';
import 'providers/analise_provider.dart';
import 'providers/comparar_produtos_provider.dart';

// Imports de screens
import 'screens/tabela_de_produtos_screen.dart';
import 'screens/lista_de_compras_screen.dart';
import 'screens/compras_screen.dart';
import 'screens/mercado_screen.dart';
import 'screens/selecionar_lista_mercado_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/banco_dados_mercado_screen.dart';
import 'screens/banco_de_dados_screen.dart';
import 'screens/marca_screen.dart';
import 'screens/analise_screen.dart';
import 'screens/comparar_produtos_screen.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'widgets/keep_alive_wrapper.dart';

class AppInitializer extends StatefulWidget {
  final Widget child;
  const AppInitializer({Key? key, required this.child}) : super(key: key);

  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(Duration.zero); // Garante que o build inicial foi completado
    if (!mounted) return;

    final context = this.context;
    
    try {
      // Obtém as referências dos providers
      final produtoProvider = Provider.of<ProdutoProvider>(context, listen: false);
      final nomeDeMercadoProvider = Provider.of<NomeDeMercadoProvider>(context, listen: false);
      final categoriaProvider = Provider.of<CategoriaProvider>(context, listen: false);
      final compraProvider = Provider.of<CompraProvider>(context, listen: false);
      final mercadoProvider = Provider.of<MercadoProvider>(context, listen: false);
      final analiseProvider = Provider.of<AnaliseProvider>(context, listen: false);
      final compararProvider = Provider.of<CompararProdutosProvider>(context, listen: false);

      // Inicializa dados básicos em paralelo
      await Future.wait([
        produtoProvider.fetchProdutos(),
        nomeDeMercadoProvider.fetchNomesDeMercado(),
        categoriaProvider.fetchCategorias(),
        compraProvider.carregarListasCompras(),
        mercadoProvider.obterTodasListasFinalizadasMercado(),
      ]);

      // Inicializa dados que podem causar notificações
      await Future.wait([
        analiseProvider.carregarMercados(),
        analiseProvider.carregarTodosProdutos().then((produtos) {
          compararProvider.setProdutos(produtos);
          compararProvider.sincronizarComAnaliseProvider();
        }),
      ]);

    } catch (e) {
      print('Erro na inicialização dos dados: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Carregando dados...'),
                  ],
                ),
              ),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Erro ao carregar dados: ${snapshot.error}'),
              ),
            ),
          );
        }

        return widget.child;
      },
    );
  }
}

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: "assets/.env");
    await Firebase.initializeApp();

    final produtoProvider = ProdutoProvider();
    final nomeDeMercadoProvider = NomeDeMercadoProvider();
    final categoriaProvider = CategoriaProvider();
    final compraProvider = CompraProvider();
    final mercadoProvider = MercadoProvider();
    final analiseProvider = AnaliseProvider();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProdutoProvider>.value(value: produtoProvider),
          ChangeNotifierProvider<NomeDeMercadoProvider>.value(value: nomeDeMercadoProvider),
          ChangeNotifierProvider<CategoriaProvider>.value(value: categoriaProvider),
          ChangeNotifierProvider<CompraProvider>.value(value: compraProvider),
          ChangeNotifierProvider<MercadoProvider>.value(value: mercadoProvider),
          ChangeNotifierProvider<GastoSemanalProvider>(
            create: (_) => GastoSemanalProvider(),
          ),
          ChangeNotifierProvider<AnaliseProvider>.value(value: analiseProvider),
          ChangeNotifierProxyProvider<AnaliseProvider, CompararProdutosProvider>(
            create: (context) => CompararProdutosProvider(analiseProvider),
            update: (context, analiseProvider, previous) =>
                previous ?? CompararProdutosProvider(analiseProvider),
          ),
        ],
        child: AppInitializer(
          child: ControleDeEstoqueApp(),
        ),
      ),
    );
  } catch (e, stackTrace) {
    print('Erro durante a inicialização do app: $e');
    print('Stack trace: $stackTrace');
  }
}

class ControleDeEstoqueApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Estoque',
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', 'US'),
        const Locale('pt', 'BR'),
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => MenuScreen(),
        '/tabela_produtos': (context) => TabelaDeProdutosScreen(),
        '/lista_compras': (context) => ListaDeComprasScreen(),
        '/selecionar_lista_mercado': (context) => SelecionarListaMercadoScreen(),
        '/mercado': (context) => KeepAliveWrapper(child: MercadoScreen()),
        '/banco_de_dados': (context) => BancoDeDadosScreen(),
        '/banco_dados_mercado': (context) => BancoDadosMercadoScreen(),
        '/marca': (context) => MarcaScreen(),
        '/compras': (context) => ComprasScreen(),
        '/analise': (context) => AnaliseScreen(),
      },
    );
  }
}