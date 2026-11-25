import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}

/// GPS: permissão, serviço ligado e coordenadas.
class LocationService {
  /// true se ainda não pedimos permissão (vale explicar o motivo antes).
  Future<bool> precisaExplicar() async {
    final permissao = await Geolocator.checkPermission();
    return permissao == LocationPermission.denied;
  }

  Future<Position> obterPosicao() async {
    // 1) o GPS do aparelho está ligado?
    final ativo = await Geolocator.isLocationServiceEnabled();
    if (!ativo) {
      throw LocationException(
        'O GPS está desligado. Ative a localização do aparelho.',
      );
    }

    // 2) permissão
    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied) {
      throw LocationException('Permissão de localização negada.');
    }
    if (permissao == LocationPermission.deniedForever) {
      throw LocationException(
        'Permissão bloqueada. Libere a localização nas configurações do aparelho.',
      );
    }

    // 3) latitude e longitude
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }
}
