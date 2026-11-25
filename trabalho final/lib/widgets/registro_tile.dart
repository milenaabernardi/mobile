import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/movie.dart';
import '../models/registro_model.dart';
import '../theme/app_theme.dart';

/// Linha de um registro (usada no Diário e no Calendário).
class RegistroTile extends StatelessWidget {
  final Registro registro;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const RegistroTile({
    super.key,
    required this.registro,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final r = registro;
    return Card(
      color: AppColors.superficie,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.borda),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 84,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: _miniatura(r),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy').format(r.dataEvento),
                      style: const TextStyle(
                        color: AppColors.textoSecundario,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < r.nota ? Icons.star : Icons.star_border,
                            size: 15,
                            color: AppColors.verde,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: r.synced
                              ? 'Sincronizado com a nuvem'
                              : 'Salvo no aparelho (pendente)',
                          child: Icon(
                            r.synced
                                ? Icons.cloud_done_outlined
                                : Icons.cloud_off_outlined,
                            size: 16,
                            color: r.synced
                                ? AppColors.verde
                                : AppColors.laranja,
                          ),
                        ),
                        if (r.temLocalizacao) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.place_outlined,
                            size: 16,
                            color: AppColors.azul,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                  ),
                  IconButton(
                    tooltip: 'Excluir',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniatura(Registro r) {
    if (r.fotoBytes != null) {
      return Image.memory(
        r.fotoBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }
    if (r.posterPath != null) {
      return Image.network(
        Movie.imageUrl(r.posterPath!, size: 'w185'),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _vazio(),
      );
    }
    return _vazio();
  }

  Widget _vazio() => Container(
    color: AppColors.fundo,
    alignment: Alignment.center,
    child: const Icon(Icons.movie_outlined, color: AppColors.textoSecundario),
  );
}
