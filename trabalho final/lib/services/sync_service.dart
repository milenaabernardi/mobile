import '../database/registro_helper.dart';
import 'firestore_service.dart';

/// Envia para o Firestore o que ficou pendente no SQLite.
///
/// Regras:
///  * cada registro tem id único (o mesmo no SQLite e no Firestore), então
///    reenviar não duplica;
///  * depois de enviado, o registro é marcado como sincronizado e removido
///    do banco local;
///  * exclusões feitas offline ficam guardadas (deletedAt) e são replicadas.
class SyncService {
  final RegistroHelper _helper;
  final FirestoreService _firestore;
  bool _rodando = false;

  SyncService(this._helper, this._firestore);

  /// Retorna quantas operações foram concluídas.
  Future<int> sincronizar(String userId) async {
    if (_rodando) return 0;
    _rodando = true;
    var concluidas = 0;
    try {
      // 1) criações e edições pendentes
      for (final r in await _helper.listarPendentes(userId)) {
        // Se o envio demorar e o app perder a conexão, o Firestore pode
        // terminar o envio depois. Guardar o remoteId já evita que uma
        // exclusão posterior deixe lixo na nuvem.
        await _helper.atualizar(r.copyWith(remoteId: r.id));

        await _firestore.salvar(r.copyWith(remoteId: r.id, synced: true));

        // Só limpa o local se o usuário não editou o registro durante o envio.
        final atual = await _helper.buscarPorId(r.id);
        if (atual != null && atual.updatedAt == r.updatedAt) {
          await _helper.marcarSincronizado(r.id);
          await _helper.excluir(r.id); // dados já estão na nuvem
        }
        concluidas++;
      }

      // 2) exclusões pendentes
      for (final r in await _helper.listarExclusoesPendentes(userId)) {
        await _firestore.excluir(userId, r.remoteId ?? r.id);
        await _helper.excluir(r.id);
        concluidas++;
      }
    } finally {
      _rodando = false;
    }
    return concluidas;
  }
}
