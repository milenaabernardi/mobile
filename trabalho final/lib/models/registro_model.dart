import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Registro do diário: um filme que o usuário assistiu (ou vai assistir).
///
/// O mesmo objeto é usado no SQLite (toMap/fromMap) e no Firestore
/// (toFirestore/fromFirestore).
class Registro {
  /// Identificador único criado no próprio aparelho. Ele também é o id do
  /// documento no Firestore, então reenviar o registro nunca duplica.
  final String id;
  final String userId;

  /// Preenchido quando o registro já existe (ou pode existir) na nuvem.
  final String? remoteId;

  final String titulo;
  final String descricao;
  final int nota;
  final int? tmdbId;
  final String? posterPath;
  final DateTime dataEvento;
  final DateTime criadoEm;
  final DateTime updatedAt;
  final double? latitude;
  final double? longitude;
  final String? fotoBase64;
  /// false = ainda precisa ser enviado para a nuvem.
  final bool synced;
  /// Preenchido quando o usuário excluiu offline: a exclusão fica pendente.
  final DateTime? deletedAt;

  Registro({
    required this.id,
    required this.userId,
    required this.titulo,
    required this.dataEvento,
    required this.criadoEm,
    required this.updatedAt,
    this.remoteId,
    this.descricao = '',
    this.nota = 0,
    this.tmdbId,
    this.posterPath,
    this.latitude,
    this.longitude,
    this.fotoBase64,
    this.synced = false,
    this.deletedAt,
  });

  /// Bytes da foto (decodificados só quando necessário).
  late final Uint8List? fotoBytes = fotoBase64 == null
      ? null
      : base64Decode(fotoBase64!);

  bool get temLocalizacao => latitude != null && longitude != null;

  static String gerarId() {
    final agora = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final aleatorio = Random().nextInt(1 << 30).toRadixString(36);
    return '$agora$aleatorio';
  }

  Registro copyWith({
    String? remoteId,
    String? titulo,
    String? descricao,
    int? nota,
    int? tmdbId,
    String? posterPath,
    DateTime? dataEvento,
    DateTime? updatedAt,
    double? latitude,
    double? longitude,
    bool limparLocalizacao = false,
    String? fotoBase64,
    bool limparFoto = false,
    bool limparFilme = false,
    bool? synced,
    DateTime? deletedAt,
  }) {
    return Registro(
      id: id,
      userId: userId,
      remoteId: remoteId ?? this.remoteId,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      nota: nota ?? this.nota,
      tmdbId: limparFilme ? null : (tmdbId ?? this.tmdbId),
      posterPath: limparFilme ? null : (posterPath ?? this.posterPath),
      dataEvento: dataEvento ?? this.dataEvento,
      criadoEm: criadoEm,
      updatedAt: updatedAt ?? this.updatedAt,
      latitude: limparLocalizacao ? null : (latitude ?? this.latitude),
      longitude: limparLocalizacao ? null : (longitude ?? this.longitude),
      fotoBase64: limparFoto ? null : (fotoBase64 ?? this.fotoBase64),
      synced: synced ?? this.synced,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  // ---------- SQLite ----------
  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'remoteId': remoteId,
    'titulo': titulo,
    'descricao': descricao,
    'nota': nota,
    'tmdbId': tmdbId,
    'posterPath': posterPath,
    'dataEvento': dataEvento.millisecondsSinceEpoch,
    'criadoEm': criadoEm.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'latitude': latitude,
    'longitude': longitude,
    'fotoBase64': fotoBase64,
    'synced': synced ? 1 : 0,
    'deletedAt': deletedAt?.millisecondsSinceEpoch,
  };

  factory Registro.fromMap(Map<String, dynamic> m) {
    return Registro(
      id: m['id'] as String,
      userId: m['userId'] as String,
      remoteId: m['remoteId'] as String?,
      titulo: m['titulo'] as String,
      descricao: (m['descricao'] ?? '') as String,
      nota: (m['nota'] ?? 0) as int,
      tmdbId: m['tmdbId'] as int?,
      posterPath: m['posterPath'] as String?,
      dataEvento: DateTime.fromMillisecondsSinceEpoch(m['dataEvento'] as int),
      criadoEm: DateTime.fromMillisecondsSinceEpoch(m['criadoEm'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updatedAt'] as int),
      latitude: (m['latitude'] as num?)?.toDouble(),
      longitude: (m['longitude'] as num?)?.toDouble(),
      fotoBase64: m['fotoBase64'] as String?,
      synced: (m['synced'] ?? 0) == 1,
      deletedAt: m['deletedAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(m['deletedAt'] as int),
    );
  }

  // ---------- Firestore ----------
  Map<String, dynamic> toFirestore() => {
    'id': id,
    'userId': userId,
    'titulo': titulo,
    'descricao': descricao,
    'nota': nota,
    'tmdbId': tmdbId,
    'posterPath': posterPath,
    'dataEvento': Timestamp.fromDate(dataEvento),
    'criadoEm': Timestamp.fromDate(criadoEm),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'latitude': latitude,
    'longitude': longitude,
    'fotoBase64': fotoBase64,
    'synced': true, // na nuvem o registro já está sincronizado
  };

  factory Registro.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    DateTime data(dynamic v) => v is Timestamp ? v.toDate() : DateTime.now();
    return Registro(
      id: doc.id,
      userId: (d['userId'] ?? '') as String,
      remoteId: doc.id,
      titulo: (d['titulo'] ?? 'Sem título') as String,
      descricao: (d['descricao'] ?? '') as String,
      nota: (d['nota'] ?? 0) as int,
      tmdbId: d['tmdbId'] as int?,
      posterPath: d['posterPath'] as String?,
      dataEvento: data(d['dataEvento']),
      criadoEm: data(d['criadoEm']),
      updatedAt: data(d['updatedAt']),
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
      fotoBase64: d['fotoBase64'] as String?,
      synced: true,
    );
  }
}
