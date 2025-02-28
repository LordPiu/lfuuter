import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'selecionar_lista_mercado_screen.dart';
import 'mercado_screen.dart';
import '../providers/mercado_navigation_provider.dart';

class MercadoWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MercadoNavigationProvider>(
      builder: (context, navigationProvider, child) {
        if (navigationProvider.isListaCarregada && navigationProvider.listaArguments != null) {
          return MercadoScreen(arguments: navigationProvider.listaArguments!);
        } else {
          return SelecionarListaMercadoScreen();
        }
      },
    );
  }
}