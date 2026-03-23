import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // Se estiver testando no Emulador Android: 10.0.2.2
  // Se estiver no Celular Real: Use o IP da sua máquina (ex: 192.168.15.X)
  final String _baseUrl = 'http://127.0.0.1:8000/processar';

  Future<String> buscarSugestao({
    required String texto,
    required List<String> rimasUsuario,
    bool isComando = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'texto_usuario': texto,
          'lista_rimas': rimasUsuario,
          'is_comando': isComando,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['resultado'];
      } else {
        return "Erro ao carregar rima";
      }
    } catch (e) {
      return "Erro de conexão com o servidor";
    }
  }
}