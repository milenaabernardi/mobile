import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_contatos_flutter/utils/email_utils.dart';

void main() {
  group('Validação de e-mail', () {
    test('aceita e-mails válidos', () {
      expect(isValidEmail('nome@dominio.com'), isTrue);
      expect(isValidEmail('nome.sobrenome+tag@sub.dominio.com.br'), isTrue);
      expect(isValidEmail('a_b-c@uni-centro.edu.br'), isTrue);
    });

    test('rejeita e-mails inválidos', () {
      expect(isValidEmail(''), isFalse);
      expect(isValidEmail('semarroba.com'), isFalse);
      expect(isValidEmail('@dominio.com'), isFalse);
      expect(isValidEmail('nome@'), isFalse);
      expect(isValidEmail('nome@dominio'), isFalse);
      expect(isValidEmail('nome@dominio.c'), isFalse);
      expect(isValidEmail('nome@@dominio.com'), isFalse);
      expect(isValidEmail('nome..x@dominio.com'), isFalse);
      expect(isValidEmail('.nome@dominio.com'), isFalse);
      expect(isValidEmail('nome@-dominio.com'), isFalse);
      expect(isValidEmail('nome @dominio.com'), isFalse);
    });

    test('validateEmail devolve mensagem de erro', () {
      expect(validateEmail(''), isNotNull);
      expect(validateEmail('abc'), isNotNull);
      expect(validateEmail('abc@dominio.com'), isNull);
    });
  });
}
