/// EXERCÍCIO 1: validação do formato de email.
///
/// Aceita algo como `nome@dominio.com` (com pontos, + e hífens no nome,
/// e um domínio com pelo menos um ponto e TLD de 2+ letras).
final RegExp _emailRegex = RegExp(
  r'^[\w.+\-]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)*\.[A-Za-z]{2,}$',
);

bool isValidEmail(String email) => _emailRegex.hasMatch(email.trim());
