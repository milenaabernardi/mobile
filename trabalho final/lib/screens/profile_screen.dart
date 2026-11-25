import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/profile_photo_store.dart';
import '../services/registro_repository.dart';
import '../theme/app_theme.dart';
import 'favorites_screen.dart';
import 'login_screen.dart';
import 'registro_actions.dart';

/// Aba "Perfil": usuário logado, foto, estado da conexão e logout.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final uid = AuthService().usuario?.uid;
    if (uid != null) ProfilePhotoStore.instance.carregar(uid);
  }

  Future<void> _sincronizar() async {
    final mensagem = await RegistroRepository.instance.sincronizar();
    if (mounted) mostrarAviso(context, mensagem ?? 'Tudo sincronizado.');
  }

  // ---------- Foto de perfil (galeria, câmera ou remover) ----------
  Future<void> _alterarFoto() async {
    final uid = AuthService().usuario?.uid;
    if (uid == null) return;
    final temFoto = ProfilePhotoStore.instance.foto.value != null;

    final acao = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.superficie,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.of(ctx).pop('galeria'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar uma foto'),
              onTap: () => Navigator.of(ctx).pop('camera'),
            ),
            if (temFoto)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remover foto'),
                onTap: () => Navigator.of(ctx).pop('remover'),
              ),
          ],
        ),
      ),
    );
    if (acao == null) return;

    if (acao == 'remover') {
      await ProfilePhotoStore.instance.remover(uid);
      return;
    }

    try {
      final arquivo = await _picker.pickImage(
        source: acao == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      if (arquivo == null) return;
      final bytes = await arquivo.readAsBytes();
      await ProfilePhotoStore.instance.salvar(uid, bytes);
    } catch (_) {
      if (mounted) mostrarAviso(context, 'Não foi possível abrir a imagem.');
    }
  }

  // ---------- Botão: Sair (logout) ----------
  Future<void> _sair() async {
    final repo = RegistroRepository.instance;

    // Tenta enviar o que estiver pendente antes de sair.
    await repo.sincronizar();
    if (!mounted) return;

    if (repo.pendentes > 0) {
      final sair = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Registros pendentes'),
          content: Text(
            '${repo.pendentes} registro(s) ainda não foram enviados à nuvem. '
            'Eles continuam salvos neste aparelho e serão enviados quando você '
            'entrar de novo, com internet.',
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Sair mesmo assim'),
            ),
          ],
        ),
      );
      if (sair != true) return;
    }

    repo.parar();
    ProfilePhotoStore.instance.limpar();
    await AuthService().sair();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final usuario = auth.usuario;
    final repo = RegistroRepository.instance;
    final nome = auth.nomeExibicao;
    final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Perfil',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  ValueListenableBuilder<Uint8List?>(
                    valueListenable: ProfilePhotoStore.instance.foto,
                    builder: (context, bytes, _) => GestureDetector(
                      onTap: _alterarFoto,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 38,
                            backgroundColor: AppColors.verde,
                            backgroundImage: bytes != null
                                ? MemoryImage(bytes)
                                : null,
                            child: bytes == null
                                ? Text(
                                    inicial,
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                    ),
                                  )
                                : null,
                          ),
                          const Positioned(
                            right: 0,
                            bottom: 0,
                            child: CircleAvatar(
                              radius: 13,
                              backgroundColor: AppColors.superficie,
                              child: Icon(Icons.camera_alt, size: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          usuario?.email ?? '',
                          style: const TextStyle(
                            color: AppColors.textoSecundario,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _alterarFoto,
                          icon: const Icon(
                            Icons.photo_camera_outlined,
                            size: 18,
                          ),
                          label: const Text('Alterar foto'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: repo,
                builder: (context, _) => Card(
                  color: AppColors.superficie,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              repo.online ? Icons.wifi : Icons.wifi_off,
                              color: repo.online
                                  ? AppColors.verde
                                  : AppColors.laranja,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              repo.online ? 'Conectado' : 'Sem conexão',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Registros aguardando envio: ${repo.pendentes}',
                          style: const TextStyle(
                            color: AppColors.textoSecundario,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: repo.sincronizando ? null : _sincronizar,
                            icon: repo.sincronizando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Icon(Icons.sync),
                            label: Text(
                              repo.sincronizando
                                  ? 'Sincronizando...'
                                  : 'Sincronizar agora',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.favorite_border,
                  color: AppColors.laranja,
                ),
                title: const Text('Meus favoritos'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _sair,
                icon: const Icon(Icons.logout),
                label: const Text('Sair da conta'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
