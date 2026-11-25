import 'package:flutter/material.dart';
import '../services/registro_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_message.dart';
import '../widgets/registro_tile.dart';
import 'registro_actions.dart';

/// Aba "Diário": lista dos registros (nuvem + pendentes do aparelho).
class DiarioScreen extends StatelessWidget {
  const DiarioScreen({super.key});

  Future<void> _sincronizar(BuildContext context) async {
    final mensagem = await RegistroRepository.instance.sincronizar();
    if (context.mounted) {
      mostrarAviso(context, mensagem ?? 'Tudo sincronizado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = RegistroRepository.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meu diário',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          ListenableBuilder(
            listenable: repo,
            builder: (context, _) => IconButton(
              tooltip: 'Sincronizar agora',
              onPressed: repo.sincronizando
                  ? null
                  : () => _sincronizar(context),
              icon: repo.sincronizando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.verde,
                      ),
                    )
                  : const Icon(Icons.sync),
            ),
          ),
        ],
      ),
      // heroTag nulo: há mais de um botão flutuante no app (Diário e Calendário)
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => abrirFormularioRegistro(context),
        icon: const Icon(Icons.add),
        label: const Text('Registrar filme'),
      ),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          return Column(
            children: [
              _StatusBanner(repo: repo),
              Expanded(child: _corpo(context, repo)),
            ],
          );
        },
      ),
    );
  }

  Widget _corpo(BuildContext context, RegistroRepository repo) {
    if (repo.carregando && repo.registros.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.verde),
      );
    }
    return RefreshIndicator(
      color: AppColors.verde,
      onRefresh: repo.carregar,
      child: repo.registros.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 80),
                EmptyMessage(
                  icon: Icons.menu_book_outlined,
                  text: 'Seu diário está vazio.\nToque em "Registrar filme" para começar.',
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: repo.registros.length,
              itemBuilder: (context, i) {
                final r = repo.registros[i];
                return RegistroTile(
                  registro: r,
                  onTap: () => abrirDetalhesRegistro(context, r),
                  onEdit: () => abrirFormularioRegistro(context, registro: r),
                  onDelete: () => confirmarExclusao(context, r),
                );
              },
            ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final RegistroRepository repo;
  const _StatusBanner({required this.repo});

  @override
  Widget build(BuildContext context) {
    String? texto;
    Color cor = AppColors.laranja;
    IconData icone = Icons.cloud_off_outlined;

    if (!repo.online) {
      texto = repo.pendentes > 0
          ? 'Sem conexão • ${repo.pendentes} registro(s) aguardando envio'
          : 'Sem conexão • você pode continuar usando o app';
    } else if (repo.erroNuvem != null) {
      texto = 'Não foi possível ler a nuvem: ${repo.erroNuvem}';
      cor = Colors.redAccent;
      icone = Icons.error_outline;
    } else if (repo.pendentes > 0) {
      texto = '${repo.pendentes} registro(s) aguardando envio';
      icone = Icons.cloud_upload_outlined;
    }

    if (texto == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: cor.withAlpha(35),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icone, color: cor, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
