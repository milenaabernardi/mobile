/// Validações de formulário (retornam a mensagem de erro, ou null se estiver ok).
class Validators {
  static final RegExp _email = RegExp(r'^[\w\.\-+]+@[\w\-]+(\.[\w\-]+)+$');

  static String? email(String? v) {
    final texto = v?.trim() ?? '';
    if (texto.isEmpty) return 'Informe o e-mail.';
    if (!_email.hasMatch(texto)) return 'E-mail inválido.';
    return null;
  }

  static String? senha(String? v) {
    final texto = v ?? '';
    if (texto.isEmpty) return 'Informe a senha.';
    if (texto.length < 6) return 'A senha deve ter pelo menos 6 caracteres.';
    return null;
  }

  static String? nomeCompleto(String? v) {
    final texto = v?.trim() ?? '';
    if (texto.isEmpty) return 'Informe o nome completo.';
    if (texto.split(RegExp(r'\s+')).length < 2) {
      return 'Digite nome e sobrenome.';
    }
    return null;
  }

  static String? titulo(String? v) {
    final texto = v?.trim() ?? '';
    if (texto.isEmpty) return 'Informe o nome do filme.';
    if (texto.length < 2) return 'Digite pelo menos 2 caracteres.';
    return null;
  }
}
