import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../theme/app_theme.dart';

// Painel inferior para escolher outra imagem (pôster ou backdrop).
void showImagePickerSheet({
  required BuildContext context,
  required String title,
  required Future<List<String>> imagesFuture,
  required String? selectedPath,
  required bool backdrop,
  required void Function(String path) onSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.superficie,
    builder: (ctx) {
      return SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<String>>(
                future: imagesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.verde),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.textoSecundario),
                        ),
                      ),
                    );
                  }
                  final images = snapshot.data ?? [];
                  if (images.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhuma imagem alternativa encontrada.',
                        style: TextStyle(color: AppColors.textoSecundario),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: images.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: backdrop ? 2 : 3,
                      childAspectRatio: backdrop ? 16 / 9 : 2 / 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, i) {
                      final path = images[i];
                      final selecionada = path == selectedPath;
                      return InkWell(
                        onTap: () {
                          onSelected(path);
                          Navigator.of(ctx).pop();
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: selecionada
                                  ? AppColors.verde
                                  : AppColors.borda,
                              width: selecionada ? 2.5 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            Movie.imageUrl(path,
                                size: backdrop ? 'w300' : 'w185'),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.fundo,
                              child: const Icon(Icons.broken_image_outlined,
                                  color: AppColors.textoSecundario),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
