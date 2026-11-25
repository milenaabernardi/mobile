import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/movie.dart';
import '../models/registro_model.dart';
import '../services/registro_repository.dart';
import '../theme/app_theme.dart';
import '../utils/map_launcher.dart';
import '../widgets/movie_card.dart';
import 'registro_actions.dart';

/// Consulta dos detalhes de um registro, com editar e excluir.
class RegistroDetailsScreen extends StatefulWidget {
  final Registro registro;
  const RegistroDetailsScreen({super.key, required this.registro});

  @override
  State<RegistroDetailsScreen> createState() => _RegistroDetailsScreenState();
}

class _RegistroDetailsScreenState extends State<RegistroDetailsScreen> {
  late Registro _registro = widget.registro;

  Future<void> _editar() async {
    final salvou = await abrirFormularioRegistro(context, registro: _registro);
    if (!salvou || !mounted) return;
    // Pega a versão atualizada na lista do repositório.
    final atualizado = RegistroRepository.instance.registros.where(
      (r) => r.id == _registro.id,
    );
    if (atualizado.isNotEmpty) setState(() => _registro = atualizado.first);
  }

  // ---------- Botão: Abrir no mapa ----------
  Future<void> _abrirMapa() async {
    final r = _registro;
    if (!r.temLocalizacao) return;
    final abriu = await abrirNoMapa(r.latitude!, r.longitude!);
    if (!abriu && mounted) {
      mostrarAviso(context, 'Não foi possível abrir o mapa.');
    }
  }

  Future<void> _excluir() async {
    final excluiu = await confirmarExclusao(context, _registro);
    if (excluiu && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final r = _registro;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes'),
        actions: [
          IconButton(
            tooltip: 'Editar',
            onPressed: _editar,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Excluir',
            onPressed: _excluir,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (r.fotoBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      r.fotoBytes!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                  )
                else if (r.posterPath != null)
                  Center(
                    child: SizedBox(
                      height: 240,
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: MoviePoster(
                            url: Movie.imageUrl(r.posterPath!, size: 'w500'),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  r.titulo,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < r.nota ? Icons.star : Icons.star_border,
                        color: AppColors.verde,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Chip(
                      avatar: Icon(
                        r.synced
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_off_outlined,
                        size: 16,
                        color: r.synced ? AppColors.verde : AppColors.laranja,
                      ),
                      label: Text(r.synced ? 'Sincronizado' : 'Pendente'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _linha(
                  Icons.calendar_month_outlined,
                  'Assistido em',
                  DateFormat(
                    "dd 'de' MMMM 'de' yyyy",
                    'pt_BR',
                  ).format(r.dataEvento),
                ),
                _linha(
                  Icons.edit_calendar_outlined,
                  'Última alteração',
                  DateFormat('dd/MM/yyyy HH:mm').format(r.updatedAt),
                ),
                if (r.temLocalizacao) ...[
                  _linha(
                    Icons.place_outlined,
                    'Localização',
                    'Lat ${r.latitude!.toStringAsFixed(6)}  •  Lon ${r.longitude!.toStringAsFixed(6)}',
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _abrirMapa,
                      icon: const Icon(
                        Icons.map_outlined,
                        color: AppColors.azul,
                      ),
                      label: const Text('Abrir no mapa'),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Resenha',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  r.descricao.isEmpty ? 'Sem observações.' : r.descricao,
                  style: const TextStyle(height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _linha(IconData icone, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: AppColors.textoSecundario),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$titulo: ',
                    style: const TextStyle(color: AppColors.textoSecundario),
                  ),
                  TextSpan(text: valor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
