import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Endereço retornado pela API ViaCEP.
class Address {
  Address({
    required this.cep,
    required this.street,
    required this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
  });

  final String cep;
  final String street; // logradouro
  final String complement; // complemento
  final String neighborhood; // bairro
  final String city; // localidade
  final String state; // uf

  factory Address.fromJson(Map<String, dynamic> json) {
    String read(String key) => (json[key] ?? '').toString().trim();

    return Address(
      cep: read('cep'),
      street: read('logradouro'),
      complement: read('complemento'),
      neighborhood: read('bairro'),
      city: read('localidade'),
      state: read('uf'),
    );
  }
}

/// Erro com mensagem pronta para mostrar ao usuário.
class CepException implements Exception {
  CepException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Consulta de CEP usando a API pública e gratuita ViaCEP
/// (https://viacep.com.br). Formato: GET https://viacep.com.br/ws/{cep}/json/
class CepService {
  static const Duration _timeout = Duration(seconds: 10);

  Future<Address> fetchAddress(String cep) async {
    final digits = cep.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) {
      throw CepException('CEP inválido. Informe os 8 dígitos.');
    }

    final uri = Uri.https('viacep.com.br', '/ws/$digits/json/');

    final http.Response response;
    try {
      response = await http.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw CepException('Tempo esgotado ao consultar o CEP. Tente novamente.');
    } catch (_) {
      throw CepException(
        'Não foi possível consultar o CEP. Verifique sua conexão com a internet.',
      );
    }

    if (response.statusCode == 400) {
      throw CepException('CEP inválido.');
    }
    if (response.statusCode != 200) {
      throw CepException('Erro ao consultar o CEP (${response.statusCode}).');
    }

    final dynamic data;
    try {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw CepException('Resposta inesperada do serviço de CEP.');
    }

    if (data is! Map<String, dynamic>) {
      throw CepException('Resposta inesperada do serviço de CEP.');
    }

    // Para CEP inexistente a API responde 200 com {"erro": true}
    // (em versões antigas, {"erro": "true"}).
    final erro = data['erro'];
    if (erro == true || erro == 'true') {
      throw CepException('CEP não encontrado.');
    }

    return Address.fromJson(data);
  }
}
