import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/registro_model.dart';
import '../services/registro_repository.dart';
import 'registro_details_screen.dart';
import 'registro_form_screen.dart';

/// Ações compartilhadas entre as telas (Diário, Calendário, Detalhes).

void mostrarAviso(BuildContext context, String texto) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));
}

/// Abre o formulário para criar (registro == null) ou editar um registro.
/// Retorna true se o usuário salvou.
Future<bool> abrirFormularioRegistro(
  BuildContext context, {
  Registro? registro,
  Movie? filme,
  DateTime? data,
}) async {
  final salvou = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => RegistroFormScreen(
        registro: registro,
        filme: filme,
        dataInicial: data,
      ),
    ),
  );
  return salvou == true;
}

Future<void> abrirDetalhesRegistro(BuildContext context, Registro registro) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => RegistroDetailsScreen(registro: registro),
    ),
  );
}

/// Pergunta antes de excluir. Retorna true se foi excluído.
Future<bool> confirmarExclusao(BuildContext context, Registro registro) async {
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Excluir registro?'),
      content: Text('"${registro.titulo}" será removido do seu diário.'),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  if (confirmou != true) return false;

  await RegistroRepository.instance.excluir(registro);
  if (context.mounted) mostrarAviso(context, 'Registro excluído.');
  return true;
}
