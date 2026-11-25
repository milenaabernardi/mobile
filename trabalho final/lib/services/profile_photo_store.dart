import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Foto de perfil guardada só no aparelho (uma para cada usuário).
/// É pequena (400 px, comprimida), então cabe nas preferências do app.
class ProfilePhotoStore {
  ProfilePhotoStore._();
  static final ProfilePhotoStore instance = ProfilePhotoStore._();

  final ValueNotifier<Uint8List?> foto = ValueNotifier<Uint8List?>(null);

  String _chave(String uid) => 'foto_perfil_$uid';

  Future<void> carregar(String uid) async {
    foto.value = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final texto = prefs.getString(_chave(uid));
      foto.value = texto == null ? null : base64Decode(texto);
    } catch (_) {
      foto.value = null;
    }
  }

  Future<void> salvar(String uid, Uint8List bytes) async {
    foto.value = bytes;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chave(uid), base64Encode(bytes));
    } catch (_) {}
  }

  Future<void> remover(String uid) async {
    foto.value = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chave(uid));
    } catch (_) {}
  }

  /// Usado no logout, para a foto de um usuário não aparecer para outro.
  void limpar() => foto.value = null;
}
