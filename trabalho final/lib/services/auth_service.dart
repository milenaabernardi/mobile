import 'package:firebase_auth/firebase_auth.dart';

/// Erro com mensagem pronta para mostrar ao usuário.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

/// Tudo o que é Firebase Authentication fica aqui.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get usuario => _auth.currentUser;

  String get nomeExibicao {
    final u = usuario;
    if (u == null) return '';
    final nome = u.displayName?.trim() ?? '';
    return nome.isNotEmpty ? nome : (u.email ?? 'Usuário');
  }

  Future<void> entrar(String email, String senha) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_traduzir(e.code));
    } catch (_) {
      throw AuthException('Erro inesperado. Tente novamente.');
    }
  }

  Future<void> cadastrar(String nome, String email, String senha) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
      await cred.user?.updateDisplayName(nome.trim());
      await cred.user?.reload();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_traduzir(e.code));
    } catch (_) {
      throw AuthException('Erro inesperado. Tente novamente.');
    }
  }

  Future<void> recuperarSenha(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_traduzir(e.code));
    } catch (_) {
      throw AuthException('Erro inesperado. Tente novamente.');
    }
  }

  Future<void> sair() => _auth.signOut();

  String _traduzir(String codigo) {
    switch (codigo) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'E-mail ou senha incorretos.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'email-already-in-use':
        return 'Já existe uma conta com este e-mail.';
      case 'weak-password':
        return 'Senha muito fraca. Use pelo menos 6 caracteres.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde um pouco e tente de novo.';
      case 'operation-not-allowed':
        return 'Login por e-mail/senha não está ativado no Firebase.';
      default:
        return 'Não foi possível concluir ($codigo).';
    }
  }
}
