import 'package:flutter_test/flutter_test.dart';

import 'package:trabalho_pratico/models/movie.dart';
import 'package:trabalho_pratico/models/registro_model.dart';
import 'package:trabalho_pratico/utils/validators.dart';

void main() {
  group('Validators', () {
    test('e-mail', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('abc'), isNotNull);
      expect(Validators.email('ana@email.com'), isNull);
    });

    test('senha e nome completo', () {
      expect(Validators.senha('123'), isNotNull);
      expect(Validators.senha('123456'), isNull);
      expect(Validators.nomeCompleto('Ana'), isNotNull);
      expect(Validators.nomeCompleto('Ana Souza'), isNull);
    });

    test('título do filme', () {
      expect(Validators.titulo('  '), isNotNull);
      expect(Validators.titulo('A'), isNotNull);
      expect(Validators.titulo('Cars'), isNull);
    });
  });

  group('Registro', () {
    test('toMap e fromMap preservam os dados (SQLite)', () {
      final agora = DateTime.now();
      final r = Registro(
        id: Registro.gerarId(),
        userId: 'u1',
        titulo: 'Interestelar',
        descricao: 'Muito bom',
        nota: 5,
        dataEvento: agora,
        criadoEm: agora,
        updatedAt: agora,
        latitude: -25.39,
        longitude: -51.46,
      );
      final volta = Registro.fromMap(r.toMap());
      expect(volta.id, r.id);
      expect(volta.titulo, 'Interestelar');
      expect(volta.nota, 5);
      expect(volta.latitude, -25.39);
      expect(volta.synced, false);
      expect(volta.deletedAt, isNull);
    });

    test('ids gerados são diferentes', () {
      expect(Registro.gerarId() == Registro.gerarId(), false);
    });
  });

  test('Movie.fromJson', () {
    final m = Movie.fromJson({
      'id': 1,
      'title': 'Filme',
      'poster_path': '/a.jpg',
      'vote_average': 8.0,
      'release_date': '2010-07-16',
    });
    expect(m.year, '2010');
    expect(m.stars, 4.0);
    expect(m.posterUrl, contains('/a.jpg'));
  });
}
