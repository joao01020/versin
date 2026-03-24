import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // No Linux (Debian), mantenha 127.0.0.1. 
  // Se for testar no celular físico, lembre de usar o IP da sua máquina.
  final String _baseUrl = 'http://127.0.0.1:8000/processar';

  Future<String> buscarSugestao({
    required String texto,
    required List<String> rimasUsuario,
    String? apiKeyPrivada, // NOVO: Campo para receber a chave do Controller
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
          'api_key_privada': apiKeyPrivada, // ENVIANDO O TURBO PARA O BACKEND
        }),
      ).timeout(const Duration(seconds: 4)); // Timeout curto para não travar o flow

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['resultado'] ?? "";
      } else {
        // Se der erro no servidor, retorna vazio para não poluir o balão
        return "";
      }
    } catch (e) {
      // Erro de conexão silencioso no balão de rimas para não atrapalhar a escrita
      return "";
    }
  }
}