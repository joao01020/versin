import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>> sendAiMessage(String message) async {
    // Aqui você chama a sua edge function ou serviço de IA que já funcionava
    final response = await _client.functions.invoke('chat-ai', body: {'text': message});
    return response.data;
  }
}