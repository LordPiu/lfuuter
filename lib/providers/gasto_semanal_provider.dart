// providers/gasto_semanal_provider.dart

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GastoSemanalProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double _gastoSemanal = 0.0;
  double _gastoSemanaAnterior = 0.0;
  bool _isLoading = false;
  String _errorMessage = '';

  double get gastoSemanal => _gastoSemanal;
  double get gastoSemanaAnterior => _gastoSemanaAnterior;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> calcularGastos() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      DateTime hoje = DateTime.now();
      DateTime inicioSemanaAtual = hoje.subtract(Duration(days: hoje.weekday - 1));
      DateTime fimSemanaAtual = inicioSemanaAtual.add(Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      DateTime inicioSemanaAnterior = inicioSemanaAtual.subtract(Duration(days: 7));
      DateTime fimSemanaAnterior = inicioSemanaAnterior.add(Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      _gastoSemanal = await _calcularGastoPeriodo(inicioSemanaAtual, fimSemanaAtual);
      _gastoSemanaAnterior = await _calcularGastoPeriodo(inicioSemanaAnterior, fimSemanaAnterior);

      print('Gasto Semanal: $_gastoSemanal');
      print('Gasto Semana Anterior: $_gastoSemanaAnterior');
    } catch (e) {
      print('Erro ao calcular gastos: $e');
      _errorMessage = 'Erro ao calcular gastos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<double> _calcularGastoPeriodo(DateTime inicio, DateTime fim) async {
    try {
      print('Calculando gasto para o período: ${DateFormat('dd/MM/yyyy').format(inicio)} a ${DateFormat('dd/MM/yyyy').format(fim)}');
      
      QuerySnapshot querySnapshot = await _firestore
          .collection('listas_finalizadas')
          .where('dataFinalizacao', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
          .where('dataFinalizacao', isLessThanOrEqualTo: Timestamp.fromDate(fim))
          .get();

      print('Número de documentos encontrados: ${querySnapshot.docs.length}');

      double total = 0.0;
      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        double valorTotal = 0.0;
        if (data.containsKey('valorTotal')) {
          valorTotal = (data['valorTotal'] as num).toDouble();
        } else if (data.containsKey('valor_total')) {
          valorTotal = (data['valor_total'] as num).toDouble();
        }
        print('Documento ${doc.id}: Valor Total = $valorTotal');
        total += valorTotal;
      }

      print('Total calculado para o período: $total');
      return total;
    } catch (e) {
      print('Erro ao calcular gasto do período: $e');
      throw e; // Propaga o erro para ser tratado em calcularGastos()
    }
  }
}