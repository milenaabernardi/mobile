import 'package:flutter/services.dart';

/// "Máscara" para o campo de e-mail.
///
/// E-mail não tem um tamanho fixo como CPF ou CEP, então a máscara aqui é uma
/// formatação em tempo real: remove espaços, converte para minúsculas, aceita
/// apenas caracteres válidos em um endereço e permite um único "@".
class EmailInputFormatter extends TextInputFormatter {
  static final RegExp _invalidChars = RegExp(r"[^a-z0-9@._%+\-]");

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.toLowerCase().replaceAll(_invalidChars, '');

    // Só um "@" é permitido: mantém o primeiro e descarta os demais.
    final firstAt = text.indexOf('@');
    if (firstAt != -1) {
      text = text.substring(0, firstAt + 1) +
          text.substring(firstAt + 1).replaceAll('@', '');
    }

    if (text == newValue.text) {
      return newValue;
    }

    // Mantém o cursor na posição correta depois de remover caracteres.
    final removed = newValue.text.length - text.length;
    final offset = (newValue.selection.baseOffset - removed)
        .clamp(0, text.length)
        .toInt();

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// Retorna `true` se [email] é um endereço válido (ex.: nome@dominio.com.br).
bool isValidEmail(String email) {
  final value = email.trim();
  if (value.isEmpty || value.length > 254) return false;

  final parts = value.split('@');
  if (parts.length != 2) return false;

  final local = parts[0];
  final domain = parts[1];

  // Parte local: letras, números e . _ % + - ; sem ponto no início/fim
  // e sem pontos consecutivos.
  if (local.isEmpty || local.length > 64) return false;
  if (!RegExp(r"^[a-zA-Z0-9._%+\-]+$").hasMatch(local)) return false;
  if (local.startsWith('.') || local.endsWith('.') || local.contains('..')) {
    return false;
  }

  // Domínio: rótulos separados por ponto, TLD com 2+ letras.
  if (!RegExp(
    r"^[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$",
  ).hasMatch(domain)) {
    return false;
  }

  return true;
}

/// Validador para usar em `TextFormField.validator`.
/// Retorna a mensagem de erro, ou `null` quando o e-mail é válido.
String? validateEmail(String? value) {
  final email = (value ?? '').trim();
  if (email.isEmpty) {
    return 'Informe o e-mail.';
  }
  if (!isValidEmail(email)) {
    return 'E-mail inválido. Exemplo: nome@dominio.com';
  }
  return null;
}
