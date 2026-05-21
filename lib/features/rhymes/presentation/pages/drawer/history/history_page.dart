import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:versin/features/rhymes/presentation/widgets/empty_state_widget/empty_state_widget.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _supabase = Supabase.instance.client;

  // STREAM ATUALIZADA: Usa 'user_id' conforme o seu SQL Schema V2.8
  Stream<List<Map<String, dynamic>>> _getHistoryStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('lyrics_history')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId) 
        .order('created_at', ascending: false);
  }

  Widget _buildConfigTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text(
          "HISTÓRICO DE PRODUÇÃO",
          style: TextStyle(
            fontSize: 10, 
            letterSpacing: 2, 
            fontWeight: FontWeight.bold, 
            color: Colors.white38
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white10));
          }

          if (snapshot.hasError) {
            debugPrint("Erro na Stream de Histórico: ${snapshot.error}");
          }

          final history = snapshot.data ?? [];

          if (history.isEmpty) {
            return const VersinEmptyState(
              title: "HISTÓRICO VAZIO",
              subtitle: "Suas sessões de estúdio aparecerão aqui.",
              icon: Icons.history_rounded,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              
              // Mapeamento baseado nas colunas do seu SQL V2.8
              final bpm = item['bpm'] ?? 120;
              final structure = item['structure'] ?? 'N/A';
              final content = item['content'] ?? 'Sem letra registrada.';
              final theme = item['theme'] ?? 'Geral';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _buildConfigTag("$bpm BPM", Colors.orange),
                            const SizedBox(width: 8),
                            _buildConfigTag(theme.toUpperCase(), Colors.purpleAccent),
                          ],
                        ),
                        Text(
                          _formatDate(item['created_at']), 
                          style: const TextStyle(color: Colors.white24, fontSize: 10)
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      content.length > 120 ? "${content.substring(0, 120)}..." : content,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Colors.white10),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.account_tree_outlined, size: 12, color: Colors.cyan),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "ESTRUTURA: ${structure.toUpperCase()}",
                            style: const TextStyle(
                              color: Colors.cyan, 
                              fontSize: 9, 
                              fontWeight: FontWeight.bold
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return "--/--/--";
    }
  }
}