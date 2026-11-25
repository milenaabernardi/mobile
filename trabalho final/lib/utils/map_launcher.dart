import 'package:url_launcher/url_launcher.dart';

/// Abre as coordenadas no mapa (app Google Maps ou navegador).
/// Retorna false se não foi possível abrir.
Future<bool> abrirNoMapa(double latitude, double longitude) async {
  final lat = latitude.toStringAsFixed(6);
  final lon = longitude.toStringAsFixed(6);
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
  );
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
