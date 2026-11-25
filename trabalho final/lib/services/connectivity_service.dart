import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Descobre se o aparelho tem internet de verdade e avisa quando muda.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  // As versões do connectivity_plus devolvem um valor ou uma lista;
  // este método aceita os dois formatos.
  bool _temInterface(dynamic resultado) {
    if (resultado is List) {
      return resultado.any((e) => e != ConnectivityResult.none);
    }
    return resultado != ConnectivityResult.none;
  }

  /// Confere a rede e tenta resolver um endereço do Google (internet real).
  Future<bool> temInternet() async {
    try {
      final dynamic resultado = await _connectivity.checkConnectivity();
      if (!_temInterface(resultado)) return false;
      final enderecos = await InternetAddress.lookup('firestore.googleapis.com')
          .timeout(const Duration(seconds: 4));
      return enderecos.isNotEmpty && enderecos.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Chama [aoMudar] sempre que a conexão ligar ou desligar.
  StreamSubscription<dynamic> ouvir(void Function(bool online) aoMudar) {
    return _connectivity.onConnectivityChanged.listen((
      dynamic resultado,
    ) async {
      if (!_temInterface(resultado)) {
        aoMudar(false);
        return;
      }
      aoMudar(await temInternet());
    });
  }
}
