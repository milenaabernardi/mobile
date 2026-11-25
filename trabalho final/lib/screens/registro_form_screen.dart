import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/movie.dart';
import '../models/registro_model.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/registro_repository.dart';
import '../services/tmdb_service.dart';
import '../theme/app_theme.dart';
import '../utils/map_launcher.dart';
import '../utils/validators.dart';
import '../widgets/movie_card.dart';
import 'registro_actions.dart';

/// Formulário de cadastro e edição de um registro do diário.
class RegistroFormScreen extends StatefulWidget {
  final Registro? registro; // null = novo registro
  final Movie? filme; // preenche o título a partir de um filme da TMDB
  final DateTime? dataInicial;

  const RegistroFormScreen({
    super.key,
    this.registro,
    this.filme,
    this.dataInicial,
  });

  @override
  State<RegistroFormScreen> createState() => _RegistroFormScreenState();
}

class _RegistroFormScreenState extends State<RegistroFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  final _local = LocationService();
  final _picker = ImagePicker();
  final _tmdb = TmdbService();

  // Sugestões de filmes enquanto o usuário digita
  Timer? _debounce;
  int _consulta = 0;
  List<Movie> _sugestoes = [];
  bool _buscandoSugestoes = false;
  String? _tituloVinculado; // título do filme escolhido na lista

  int _nota = 0;
  late DateTime _data;
  double? _latitude;
  double? _longitude;
  String? _foto; // base64
  int? _tmdbId;
  String? _posterPath;

  bool _salvando = false;
  bool _buscandoLocal = false;

  bool get _editando => widget.registro != null;

  @override
  void initState() {
    super.initState();
    final r = widget.registro;
    if (r != null) {
      _titulo.text = r.titulo;
      _descricao.text = r.descricao;
      _nota = r.nota;
      _data = r.dataEvento;
      _latitude = r.latitude;
      _longitude = r.longitude;
      _foto = r.fotoBase64;
      _tmdbId = r.tmdbId;
      _posterPath = r.posterPath;
      if (r.tmdbId != null) _tituloVinculado = r.titulo;
    } else {
      final f = widget.filme;
      if (f != null) {
        _titulo.text = f.title;
        _tmdbId = f.id;
        _posterPath = f.posterPath;
        _tituloVinculado = f.title;
      }
      _data = widget.dataInicial ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titulo.dispose();
    _descricao.dispose();
    super.dispose();
  }

  // ---------- Sugestões de filmes (TMDB) enquanto digita ----------
  void _aoDigitarTitulo(String texto) {
    final busca = texto.trim();

    // Mudou o texto depois de escolher um filme: desfaz o vínculo.
    if (_tmdbId != null && busca != _tituloVinculado) {
      setState(() {
        _tmdbId = null;
        _posterPath = null;
        _tituloVinculado = null;
      });
    }

    _debounce?.cancel();
    if (busca.length < 2 || busca == _tituloVinculado) {
      _consulta++;
      setState(() {
        _sugestoes = [];
        _buscandoSugestoes = false;
      });
      return;
    }
    // Espera o usuário parar de digitar antes de consultar a API.
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _buscarSugestoes(busca),
    );
  }

  Future<void> _buscarSugestoes(String busca) async {
    final minhaConsulta = ++_consulta;
    setState(() => _buscandoSugestoes = true);
    try {
      final filmes = await _tmdb.searchMovies(busca);
      if (!mounted || minhaConsulta != _consulta) return;
      setState(() => _sugestoes = filmes.take(6).toList());
    } catch (_) {
      // Sem internet ou sem chave: o usuário ainda pode digitar o nome à mão.
      if (!mounted || minhaConsulta != _consulta) return;
      setState(() => _sugestoes = []);
    } finally {
      if (mounted && minhaConsulta == _consulta) {
        setState(() => _buscandoSugestoes = false);
      }
    }
  }

  void _escolherFilme(Movie f) {
    _debounce?.cancel();
    _consulta++;
    _titulo.value = TextEditingValue(
      text: f.title,
      selection: TextSelection.collapsed(offset: f.title.length),
    );
    setState(() {
      _tmdbId = f.id;
      _posterPath = f.posterPath;
      _tituloVinculado = f.title;
      _sugestoes = [];
      _buscandoSugestoes = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _desvincularFilme() {
    setState(() {
      _tmdbId = null;
      _posterPath = null;
      _tituloVinculado = null;
    });
  }

  Widget _blocoSugestoes() {
    if (_buscandoSugestoes && _sugestoes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: LinearProgressIndicator(minHeight: 2, color: AppColors.verde),
      );
    }
    if (_sugestoes.isEmpty) return const SizedBox.shrink();
    return Card(
      color: AppColors.superficie,
      margin: const EdgeInsets.only(top: 6),
      child: Column(
        children: [
          for (final f in _sugestoes)
            ListTile(
              dense: true,
              leading: SizedBox(
                width: 34,
                height: 50,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: MoviePoster(
                    url: f.posterPath == null
                        ? null
                        : Movie.imageUrl(f.posterPath!, size: 'w92'),
                  ),
                ),
              ),
              title: Text(
                f.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(f.year),
              onTap: () => _escolherFilme(f),
            ),
        ],
      ),
    );
  }

  Widget _blocoFilmeVinculado() {
    if (_tmdbId == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 6),
        child: Text(
          'Digite para buscar o filme na TMDB ou escreva o nome manualmente.',
          style: TextStyle(color: AppColors.textoSecundario, fontSize: 12),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 54,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: MoviePoster(
                url: _posterPath == null
                    ? null
                    : Movie.imageUrl(_posterPath!, size: 'w92'),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Filme vinculado à TMDB',
              style: TextStyle(
                color: AppColors.verde,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Desvincular filme',
            onPressed: _desvincularFilme,
            icon: const Icon(Icons.link_off),
          ),
        ],
      ),
    );
  }

  // ---------- Data ----------
  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

  // ---------- Localização (GPS) ----------
  Future<void> _obterLocalizacao() async {
    // Explica o motivo ANTES de pedir a permissão.
    if (await _local.precisaExplicar()) {
      if (!mounted) return;
      final continuar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Usar sua localização?'),
          content: const Text(
            'O Cineboxd usa o GPS para registrar o lugar onde você assistiu ao filme. '
            'A localização só é lida quando você toca neste botão.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Agora não'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (continuar != true) return;
    }

    setState(() => _buscandoLocal = true);
    try {
      final posicao = await _local.obterPosicao();
      if (!mounted) return;
      setState(() {
        _latitude = posicao.latitude;
        _longitude = posicao.longitude;
      });
    } on LocationException catch (e) {
      if (mounted) mostrarAviso(context, e.message);
    } catch (_) {
      if (mounted) {
        mostrarAviso(
          context,
          'Não foi possível obter a localização. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _buscandoLocal = false);
    }
  }

  // ---------- Botão: Ver no mapa ----------
  Future<void> _verNoMapa() async {
    if (_latitude == null || _longitude == null) return;
    final abriu = await abrirNoMapa(_latitude!, _longitude!);
    if (!abriu && mounted) {
      mostrarAviso(context, 'Não foi possível abrir o mapa.');
    }
  }

  // ---------- Foto (galeria ou câmera) ----------
  Future<void> _escolherFoto() async {
    final origem = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.superficie,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar uma foto'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (origem == null) return;

    try {
      // Imagem pequena e comprimida: ela vai junto com o registro.
      final arquivo = await _picker.pickImage(
        source: origem,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 60,
      );
      if (arquivo == null) return;
      final bytes = await arquivo.readAsBytes();
      if (bytes.length > 700 * 1024) {
        if (mounted)
          mostrarAviso(context, 'Imagem muito grande. Escolha outra.');
        return;
      }
      if (!mounted) return;
      setState(() => _foto = base64Encode(bytes));
    } catch (_) {
      if (mounted) mostrarAviso(context, 'Não foi possível abrir a imagem.');
    }
  }

  // ---------- Salvar ----------
  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = AuthService().usuario?.uid;
    if (uid == null) {
      mostrarAviso(context, 'Sessão expirada. Entre novamente.');
      return;
    }

    setState(() => _salvando = true);
    try {
      final agora = DateTime.now();
      final Registro registro;
      if (widget.registro == null) {
        registro = Registro(
          id: Registro.gerarId(),
          userId: uid,
          titulo: _titulo.text.trim(),
          descricao: _descricao.text.trim(),
          nota: _nota,
          tmdbId: _tmdbId,
          posterPath: _posterPath,
          dataEvento: _data,
          criadoEm: agora,
          updatedAt: agora,
          latitude: _latitude,
          longitude: _longitude,
          fotoBase64: _foto,
        );
      } else {
        registro = widget.registro!.copyWith(
          titulo: _titulo.text.trim(),
          descricao: _descricao.text.trim(),
          nota: _nota,
          tmdbId: _tmdbId,
          posterPath: _posterPath,
          limparFilme: _tmdbId == null,
          dataEvento: _data,
          latitude: _latitude,
          longitude: _longitude,
          limparLocalizacao: _latitude == null,
          fotoBase64: _foto,
          limparFoto: _foto == null,
        );
      }

      final enviado = await RegistroRepository.instance.salvar(registro);
      if (!mounted) return;
      mostrarAviso(
        context,
        enviado ? 'Registro salvo e sincronizado com a nuvem.' : 'Registro salvo no aparelho. Será enviado quando houver internet.',
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) mostrarAviso(context, 'Erro ao salvar o registro.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar registro' : 'Novo registro'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _titulo,
                    validator: Validators.titulo,
                    onChanged: _aoDigitarTitulo,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Filme *',
                      prefixIcon: Icon(Icons.movie_outlined),
                    ),
                  ),
                  _blocoSugestoes(),
                  _blocoFilmeVinculado(),
                  const SizedBox(height: 18),
                  const Text(
                    'Nota',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (i) => IconButton(
                        tooltip: '${i + 1} estrela(s)',
                        onPressed: () =>
                            setState(() => _nota = _nota == i + 1 ? 0 : i + 1),
                        icon: Icon(
                          i < _nota ? Icons.star : Icons.star_border,
                          color: AppColors.verde,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Data em que assistiu',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _escolherData,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(DateFormat('dd/MM/yyyy').format(_data)),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _descricao,
                    maxLines: 4,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Resenha / observações',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _blocoLocalizacao(),
                  const SizedBox(height: 16),
                  _blocoFoto(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _salvando
                              ? null
                              : () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _salvando ? null : _salvar,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: _salvando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text('Salvar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _blocoLocalizacao() {
    final tem = _latitude != null && _longitude != null;
    return Card(
      color: AppColors.superficie,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.place_outlined, color: AppColors.azul),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tem
                        ? 'Latitude: ${_latitude!.toStringAsFixed(6)}\nLongitude: ${_longitude!.toStringAsFixed(6)}'
                        : 'Nenhuma localização registrada',
                  ),
                ),
                if (tem)
                  IconButton(
                    tooltip: 'Remover localização',
                    onPressed: () => setState(() {
                      _latitude = null;
                      _longitude = null;
                    }),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            if (tem)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _verNoMapa,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Ver no mapa'),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _buscandoLocal ? null : _obterLocalizacao,
                icon: _buscandoLocal
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  _buscandoLocal
                      ? 'Obtendo localização...'
                      : 'Usar minha localização',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blocoFoto() {
    final bytes = _foto == null ? null : base64Decode(_foto!);
    return Card(
      color: AppColors.superficie,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.memory(
                  bytes,
                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _escolherFoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      bytes == null ? 'Adicionar foto' : 'Trocar foto',
                    ),
                  ),
                ),
                if (bytes != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Remover foto',
                    onPressed: () => setState(() => _foto = null),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
