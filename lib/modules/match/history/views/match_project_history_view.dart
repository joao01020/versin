import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/match_project_history_service.dart';

const _background = Color(0xFF08080B);
const _surface = Color(0xFF17171E);
const _border = Color(0xFF34303E);
const _purple = Color(0xFFA78BFA);

String _date(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return 'Data não disponível';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} '
      '${two(date.hour)}:${two(date.minute)}';
}

String _historyError(Object error) =>
    error is PostgrestException ? error.message : error.toString();

class MatchProjectHistoryView extends StatefulWidget {
  const MatchProjectHistoryView({super.key});

  @override
  State<MatchProjectHistoryView> createState() =>
      _MatchProjectHistoryViewState();
}

class _MatchProjectHistoryViewState extends State<MatchProjectHistoryView> {
  final _service = MatchProjectHistoryService();
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.listHistory();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _errorMessage(error);
        _loading = false;
      });
    }
  }

  String _errorMessage(Object error) => _historyError(error);

  Future<void> _open(Map<String, dynamic> item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            MatchProjectHistoryDetailView(projectId: item['id'].toString()),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Histórico de Match', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading && _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _items.isEmpty
          ? Center(child: Text(_error!, textAlign: TextAlign.center))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Colaborações preservadas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Projetos arquivados e projetos dos quais você saiu. '
                    'O histórico é somente leitura.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 18),
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(30),
                      child: Center(
                        child: Text(
                          'Nenhum histórico disponível.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),
                  for (final item in _items)
                    _HistoryProjectCard(item: item, onTap: () => _open(item)),
                ],
              ),
            ),
    );
  }
}

class _HistoryProjectCard extends StatelessWidget {
  const _HistoryProjectCard({required this.item, required this.onTap});
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final closed = item['status'] == 'closed';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, color: _purple),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']?.toString() ?? 'Studio Session',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Hash: #${item['hash']}',
                        style: const TextStyle(color: _purple, fontSize: 11),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        closed
                            ? 'Arquivado · ${_date(item['closed_at'] ?? item['left_at'])}'
                            : 'Você saiu · ${_date(item['left_at'])}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white38),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MatchProjectHistoryDetailView extends StatefulWidget {
  const MatchProjectHistoryDetailView({super.key, required this.projectId});
  final String projectId;

  @override
  State<MatchProjectHistoryDetailView> createState() =>
      _MatchProjectHistoryDetailViewState();
}

class _MatchProjectHistoryDetailViewState
    extends State<MatchProjectHistoryDetailView> {
  final _service = MatchProjectHistoryService();
  Map<String, dynamic>? _detail;
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  static const _pageSize = 40;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _service.detail(widget.projectId);
      final events = await _service.events(widget.projectId, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _events = events;
        _hasMore = events.length == _pageSize;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _errorMessage(error);
        _loading = false;
      });
    }
  }

  String _errorMessage(Object error) => _historyError(error);

  Future<void> _more() async {
    if (_loadingMore || !_hasMore || _events.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final rows = await _service.events(
        widget.projectId,
        before: _events.last,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _events = [..._events, ...rows];
        _hasMore = rows.length == _pageSize;
      });
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Histórico do projeto',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading && detail == null
          ? const Center(child: CircularProgressIndicator())
          : detail == null
          ? Center(child: Text(_error ?? 'Histórico indisponível.'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  detail['title']?.toString() ?? 'Studio Session',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'Hash: #${detail['hash']}',
                  style: const TextStyle(color: _purple, fontSize: 12),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  'ID completo: ${detail['id']}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Clipboard.setData(
                      ClipboardData(text: detail['id'].toString()),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 15),
                    label: const Text('Copiar ID completo'),
                  ),
                ),
                Text(
                  'Criado em: ${_date(detail['created_at'])}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                Text(
                  'Encerrado em: ${_date(detail['closed_at'] ?? detail['left_at'])}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 16),
                if (detail['participants'] is List)
                  _HistorySection(
                    title: 'Participantes registrados',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final person
                            in (detail['participants'] as List)
                                .whereType<Map>())
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Text(
                              person['name']?.toString() ?? 'Participante',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                _HistorySection(
                  title: 'Contrato preservado',
                  child: SelectableText(
                    const JsonEncoder.withIndent(
                      '  ',
                    ).convert(detail['contract_terms']),
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Linha do tempo',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Mensagens, contribuições, entregas e registros disponíveis '
                  'até o período em que você participou.',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 12),
                if (_events.isEmpty)
                  const Text(
                    'Nenhum registro disponível para este período.',
                    style: TextStyle(color: Colors.white54),
                  ),
                for (final event in _events) _HistoryEventCard(event: event),
                if (_hasMore)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Center(
                      child: OutlinedButton(
                        onPressed: _loadingMore ? null : _more,
                        child: Text(
                          _loadingMore ? 'Carregando...' : 'Carregar mais',
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Histórico somente leitura. Anexos e áudio são exibidos '
                  'como metadados; esta tela não substitui o acesso aos arquivos originais.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

class _HistoryEventCard extends StatelessWidget {
  const _HistoryEventCard({required this.event});
  final Map<String, dynamic> event;
  static const labels = {
    'message': 'Mensagem',
    'contribution': 'Contribuição',
    'delivery': 'Entrega',
    'production_event': 'Registro de produção',
    'royalty_event': 'Evento de royalties',
    'royalty_agreement': 'Acordo de royalties',
    'membership': 'Participação',
    'call': 'Chamada',
  };

  @override
  Widget build(BuildContext context) {
    final kind = event['kind']?.toString() ?? '';
    final data = event['data'] is Map
        ? Map<String, dynamic>.from(event['data'] as Map)
        : <String, dynamic>{};
    final title = kind == 'message'
        ? (data['message_type'] == 'audio' ? 'Mensagem de áudio' : 'Mensagem')
        : labels[kind] ?? kind;
    final content = kind == 'message'
        ? data['content_unavailable'] == true
              ? 'Conteúdo não disponível nesta versão do histórico.'
              : data['content']?.toString() ?? ''
        : kind == 'contribution'
        ? '${data['title'] ?? 'Contribuição'}\n${data['description'] ?? ''}'
        : kind == 'delivery'
        ? data['file_name']?.toString() ?? 'Arquivo'
        : data['event_type']?.toString() ?? '';
    return _HistorySection(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _date(event['at']),
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 7),
            SelectableText(content, style: const TextStyle(fontSize: 12)),
          ],
          if (kind != 'message')
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Detalhes do registro',
                style: TextStyle(fontSize: 11),
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert(data),
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
