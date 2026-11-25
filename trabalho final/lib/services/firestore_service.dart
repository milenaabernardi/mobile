import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/registro_model.dart';

/// Comunicação com o Cloud Firestore.
///
/// Estrutura: users/{userId}/registros/{registroId}
/// Cada usuário só enxerga a própria subcoleção (veja firestore.rules).
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const Duration _limite = Duration(seconds: 15);

  CollectionReference<Map<String, dynamic>> _colecao(String userId) =>
      _db.collection('users').doc(userId).collection('registros');

  /// Create e Update: o id do documento é o id local do registro, então
  /// enviar duas vezes apenas sobrescreve (nunca duplica).
  Future<void> salvar(Registro r) {
    return _colecao(r.userId).doc(r.id).set(r.toFirestore()).timeout(_limite);
  }

  /// Delete
  Future<void> excluir(String userId, String registroId) {
    return _colecao(userId).doc(registroId).delete().timeout(_limite);
  }

  /// Read. Com [somenteCache] lê apenas o que o Firestore já guardou no
  /// aparelho (usado quando não há internet).
  Future<List<Registro>> listar(
    String userId, {
    bool somenteCache = false,
  }) async {
    final snapshot = await _colecao(userId)
        .get(
          GetOptions(
            source: somenteCache ? Source.cache : Source.serverAndCache,
          ),
        )
        .timeout(_limite);
    return snapshot.docs.map(Registro.fromFirestore).toList();
  }
}
