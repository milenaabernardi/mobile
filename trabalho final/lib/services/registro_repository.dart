import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../database/registro_helper.dart';
import '../models/registro_model.dart';
import 'connectivity_service.dart';
import 'firestore_service.dart';
import 'sync_service.dart';

/// Camada "offline first" usada pelas telas.
///
/// Fluxo de cadastro/edição:
///   1. salva no SQLite (sempre funciona, com ou sem internet);
///   2. se houver internet, envia ao Firestore, marca como sincronizado e
///      limpa o registro local;
///   3. se não houver, o registro fica pendente e é enviado quando a conexão
///      voltar.
///
/// As telas escutam este objeto (ChangeNotifier) e se atualizam sozinhas.
class RegistroRepository extends ChangeNotifier {
  RegistroRepository._();
  static final RegistroRepository instance = RegistroRepository._();

  final RegistroHelper _helper = RegistroHelper();
  final FirestoreService _firestore = FirestoreService();
  final ConnectivityService _conexao = ConnectivityService.instance;
  late final SyncService _sync = SyncService(_helper, _firestore);

  String? userId;
  List<Registro> registros = [];
  int pendentes = 0;
  bool online = true;
  bool carregando = false;
  bool sincronizando = false;
  String? erroNuvem;

  StreamSubscription<dynamic>? _assinatura;
  Timer? _novaTentativa;

  // ---------- Ciclo de vida ----------
  /// Chamado depois do login (ou ao abrir o app já logado).
  void iniciar(String uid) {
    userId = uid;
    _assinatura?.cancel();
    _assinatura = _conexao.ouvir((estaOnline) {
      online = estaOnline;
      notifyListeners();
      if (estaOnline) {
        sincronizar();
      } else {
        _tentarNovamente();
      }
    });
    carregar().then((_) => sincronizar());
  }

  /// Chamado no logout.
  void parar() {
    _assinatura?.cancel();
    _assinatura = null;
    _novaTentativa?.cancel();
    userId = null;
    registros = [];
    pendentes = 0;
    erroNuvem = null;
    notifyListeners();
  }

  // Logo que a internet volta, a rede às vezes ainda não está pronta.
  // Tentamos de novo algumas vezes.
  void _tentarNovamente([int tentativa = 1]) {
    _novaTentativa?.cancel();
    if (tentativa > 4) return;
    _novaTentativa = Timer(const Duration(seconds: 5), () async {
      if (userId == null) return;
      if (await _conexao.temInternet()) {
        online = true;
        notifyListeners();
        await sincronizar();
      } else {
        _tentarNovamente(tentativa + 1);
      }
    });
  }

  // ---------- READ ----------
  /// Junta o que está pendente no SQLite com o que está na nuvem.
  Future<void> carregar() async {
    final uid = userId;
    if (uid == null) return;
    carregando = true;
    notifyListeners();
    try {
      online = await _conexao.temInternet();
      final locais = await _helper.listarAtivos(uid);
      final idsLocais = await _helper.listarIds(uid);

      var nuvem = <Registro>[];
      erroNuvem = null;
      try {
        nuvem = await _firestore.listar(uid, somenteCache: !online);
      } catch (e) {
        if (online) erroNuvem = _descreverErro(e);
      }

      final lista = <Registro>[
        ...locais,
        // O que existe localmente (edição ou exclusão pendente) tem prioridade.
        ...nuvem.where((r) => !idsLocais.contains(r.id)),
      ]..sort((a, b) => b.dataEvento.compareTo(a.dataEvento));

      registros = lista;
      pendentes = await _helper.contarPendentes(uid);
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  String _descreverErro(Object e) {
    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        return 'permissão negada no Firestore (publique as regras de segurança)';
      }
      return e.code;
    }
    if (e is TimeoutException) return 'a nuvem demorou para responder';
    return 'falha ao acessar a nuvem';
  }

  // ---------- CREATE / UPDATE ----------
  /// Salva no SQLite e tenta enviar. Retorna true se já foi para a nuvem.
  Future<bool> salvar(Registro r) async {
    final novo = r.copyWith(synced: false, updatedAt: DateTime.now());
    final existente = await _helper.buscarPorId(novo.id);
    if (existente == null) {
      await _helper.inserir(novo);
    } else {
      await _helper.atualizar(novo);
    }
    await carregar(); // a tela já mostra o registro (pendente)
    await sincronizar();
    return (await _helper.buscarPorId(novo.id)) == null;
  }

  // ---------- DELETE ----------
  Future<void> excluir(Registro r) async {
    final local = await _helper.buscarPorId(r.id);
    final jaEstaNaNuvem = (local?.remoteId ?? r.remoteId) != null;

    if (!jaEstaNaNuvem) {
      // Nunca saiu do aparelho: basta apagar do SQLite.
      await _helper.excluir(r.id);
    } else {
      // Já existe na nuvem: guarda a exclusão para replicar depois.
      await _helper.inserir(
        r.copyWith(remoteId: r.id, deletedAt: DateTime.now(), synced: false),
      );
    }
    await carregar();
    await sincronizar();
  }

  // ---------- SINCRONIZAÇÃO ----------
  /// Retorna uma mensagem para mostrar ao usuário (ou null).
  Future<String?> sincronizar() async {
    final uid = userId;
    if (uid == null || sincronizando) return null;

    online = await _conexao.temInternet();
    if (!online) {
      notifyListeners();
      return 'Sem conexão. Os registros serão enviados quando a internet voltar.';
    }

    sincronizando = true;
    notifyListeners();
    try {
      final enviados = await _sync.sincronizar(uid);
      await carregar();
      return enviados > 0
          ? '$enviados alteração(ões) sincronizada(s) com a nuvem.'
          : null;
    } catch (_) {
      await carregar();
      return 'Não foi possível sincronizar agora. Tentaremos novamente.';
    } finally {
      sincronizando = false;
      notifyListeners();
    }
  }
}
