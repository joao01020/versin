import 'package:flutter/foundation.dart';

import '../models/creative_production_month.dart';
import '../services/creative_activity_service.dart';
import '../services/creative_production_service.dart';

// ============================================================
// CREATIVE PRODUCTION CONTROLLER
// ============================================================
//
// Responsável por orquestrar o estado da produção criativa.
//
// Fluxo:
//
// Supabase
//   ↓
// CreativeActivityService
//   ↓
// dados mensais brutos
//   ↓
// CreativeProductionService
//   ↓
// score + comparação mensal
//   ↓
// CreativeProductionController
//   ↓
// Dashboard / gráfico
//
// RESPONSABILIDADES:
//
// - carregar os últimos meses;
// - controlar loading;
// - controlar erro;
// - armazenar os dados processados;
// - expor mês atual;
// - expor mês anterior;
// - expor melhor mês;
// - expor médias e totais;
// - recarregar os dados.
//
// NÃO:
//
// - acessa Supabase diretamente;
// - calcula pesos por conta própria;
// - conhece widgets;
// - usa BuildContext.
//
// ============================================================

class CreativeProductionController extends ChangeNotifier {
  // ==========================================================
  // SERVICES
  // ==========================================================

  final CreativeActivityService _activityService;

  final CreativeProductionService _productionService;

  // ==========================================================
  // ESTADO
  // ==========================================================

  List<CreativeProductionMonth> _months = const <CreativeProductionMonth>[];

  bool _isLoading = false;

  bool _hasLoaded = false;

  String? _errorMessage;

  Object? _lastError;

  DateTime? _lastLoadedAt;

  bool _disposed = false;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  CreativeProductionController({
    CreativeActivityService? activityService,
    CreativeProductionService? productionService,
  }) : _activityService = activityService ?? CreativeActivityService(),
       _productionService = productionService ?? CreativeProductionService();

  // ==========================================================
  // GETTERS
  // ==========================================================

  List<CreativeProductionMonth> get months {
    return _months;
  }

  bool get isLoading {
    return _isLoading;
  }

  bool get hasLoaded {
    return _hasLoaded;
  }

  bool get hasError {
    return _errorMessage != null;
  }

  String? get errorMessage {
    return _errorMessage;
  }

  Object? get lastError {
    return _lastError;
  }

  DateTime? get lastLoadedAt {
    return _lastLoadedAt;
  }

  bool get isEmpty {
    return _months.isEmpty;
  }

  bool get hasData {
    return _months.isNotEmpty;
  }

  bool get isAuthenticated {
    return _activityService.isAuthenticated;
  }

  String? get currentUserId {
    return _activityService.currentUserId;
  }

  // ==========================================================
  // MÊS ATUAL
  // ==========================================================

  CreativeProductionMonth? get currentMonth {
    return _productionService.currentMonth(_months);
  }

  // ==========================================================
  // MÊS ANTERIOR
  // ==========================================================

  CreativeProductionMonth? get previousMonth {
    return _productionService.previousMonth(_months);
  }

  // ==========================================================
  // MELHOR MÊS
  // ==========================================================

  CreativeProductionMonth? get bestMonth {
    return _productionService.bestMonth(_months);
  }

  // ==========================================================
  // SCORE ATUAL
  // ==========================================================

  double get currentScore {
    return currentMonth?.score ?? 0;
  }

  // ==========================================================
  // VARIAÇÃO ATUAL
  // ==========================================================

  double get currentChangePercentage {
    return currentMonth?.changeFromPreviousMonth ?? 0;
  }

  // ==========================================================
  // SCORE FORMATADO
  // ==========================================================

  String get currentScoreLabel {
    return _productionService.formatScore(currentScore);
  }

  // ==========================================================
  // VARIAÇÃO FORMATADA
  // ==========================================================

  String get currentChangeLabel {
    return _productionService.formatChangePercentage(currentChangePercentage);
  }

  // ==========================================================
  // TEXTO DE COMPARAÇÃO
  // ==========================================================

  String get comparisonText {
    final current = currentMonth;

    if (current == null) {
      return 'Sem dados de produção';
    }

    return _productionService.buildComparisonText(
      current: current,
      previous: previousMonth,
    );
  }

  // ==========================================================
  // MÉDIA
  // ==========================================================

  double get averageScore {
    return _productionService.averageScore(_months);
  }

  // ==========================================================
  // TOTAIS
  // ==========================================================

  int get totalProjectsCreated {
    return _productionService.totalProjectsCreated(_months);
  }

  int get totalCompositionSessions {
    return _productionService.totalCompositionSessions(_months);
  }

  int get totalTasksCompleted {
    return _productionService.totalTasksCompleted(_months);
  }

  int get totalCollaborationsStarted {
    return _productionService.totalCollaborationsStarted(_months);
  }

  int get totalFilesAdded {
    return _productionService.totalFilesAdded(_months);
  }

  int get totalActivities {
    return _productionService.totalActivities(_months);
  }

  // ==========================================================
  // CARREGAR
  // ==========================================================

  Future<void> load({int months = 12, bool force = false}) async {
    if (_disposed) {
      return;
    }

    // ========================================================
    // EVITAR REQUISIÇÃO DUPLICADA
    // ========================================================

    if (_isLoading) {
      return;
    }

    // ========================================================
    // CACHE EM MEMÓRIA
    // ========================================================
    //
    // Se já carregou e force == false, mantemos os dados atuais.
    //
    // ========================================================

    if (_hasLoaded && !force) {
      return;
    }

    // ========================================================
    // AUTH
    // ========================================================

    if (!_activityService.isAuthenticated) {
      _months = const <CreativeProductionMonth>[];

      _hasLoaded = true;

      _errorMessage = 'Usuário não autenticado.';

      _lastError = null;

      _safeNotify();

      return;
    }

    // ========================================================
    // LOADING
    // ========================================================

    _isLoading = true;

    _errorMessage = null;

    _lastError = null;

    _safeNotify();

    debugPrint(
      '[CREATIVE PRODUCTION] '
      'Carregando produção criativa.',
    );

    debugPrint(
      '[CREATIVE PRODUCTION] '
      'User ID: ${_activityService.currentUserId}',
    );

    try {
      // ======================================================
      // BUSCAR DADOS
      // ======================================================

      final rawMonths = await _activityService.fetchMonthlyActivity(
        months: months,
      );

      if (_disposed) {
        return;
      }

      // ======================================================
      // PROCESSAR
      // ======================================================

      final processedMonths = _productionService.processMonths(rawMonths);

      // ======================================================
      // ESTADO
      // ======================================================

      _months = List<CreativeProductionMonth>.unmodifiable(processedMonths);

      _hasLoaded = true;

      _lastLoadedAt = DateTime.now();

      _errorMessage = null;

      _lastError = null;

      debugPrint(
        '[CREATIVE PRODUCTION] '
        '${_months.length} mês(es) carregado(s).',
      );

      final current = currentMonth;

      if (current != null) {
        debugPrint(
          '[CREATIVE PRODUCTION] '
          'Mês atual: ${current.monthKey}',
        );

        debugPrint(
          '[CREATIVE PRODUCTION] '
          'Score atual: ${current.score}',
        );

        debugPrint(
          '[CREATIVE PRODUCTION] '
          'Variação: '
          '${current.changeFromPreviousMonth}%',
        );
      }
    } catch (error, stackTrace) {
      if (_disposed) {
        return;
      }

      _hasLoaded = true;

      _lastError = error;

      _errorMessage = _friendlyErrorMessage(error);

      debugPrint(
        '[CREATIVE PRODUCTION] '
        'Erro ao carregar produção: '
        '$error',
      );

      debugPrint('$stackTrace');
    } finally {
      if (_disposed) {
        return;
      }

      _isLoading = false;

      _safeNotify();
    }
  }

  // ==========================================================
  // RECARREGAR
  // ==========================================================

  Future<void> reload({int months = 12}) {
    return load(months: months, force: true);
  }

  // ==========================================================
  // ATUALIZAR APÓS EVENTO
  // ==========================================================
  //
  // Pode ser chamado depois de:
  //
  // - criar projeto;
  // - concluir tarefa;
  // - adicionar arquivo;
  // - iniciar colaboração;
  // - finalizar sessão de composição.
  //
  // ==========================================================

  Future<void> refreshAfterActivity({int months = 12}) {
    return reload(months: months);
  }

  // ==========================================================
  // ENCONTRAR MÊS
  // ==========================================================

  CreativeProductionMonth? monthByDate(DateTime date) {
    for (final month in _months) {
      if (month.month.year == date.year && month.month.month == date.month) {
        return month;
      }
    }

    return null;
  }

  // ==========================================================
  // ENCONTRAR MÊS POR ÍNDICE
  // ==========================================================

  CreativeProductionMonth? monthAt(int index) {
    if (index < 0 || index >= _months.length) {
      return null;
    }

    return _months[index];
  }

  // ==========================================================
  // SCORE EM 0..100
  // ==========================================================

  double scoreAt(int index) {
    final month = monthAt(index);

    if (month == null) {
      return 0;
    }

    return month.score.clamp(0.0, 100.0);
  }

  // ==========================================================
  // LIMPAR ERRO
  // ==========================================================

  void clearError() {
    if (_disposed) {
      return;
    }

    if (_errorMessage == null && _lastError == null) {
      return;
    }

    _errorMessage = null;

    _lastError = null;

    _safeNotify();
  }

  // ==========================================================
  // RESET
  // ==========================================================
  //
  // Útil quando:
  //
  // - usuário faz logout;
  // - conta muda;
  // - sessão é encerrada.
  //
  // ==========================================================

  void reset() {
    if (_disposed) {
      return;
    }

    _months = const <CreativeProductionMonth>[];

    _isLoading = false;

    _hasLoaded = false;

    _errorMessage = null;

    _lastError = null;

    _lastLoadedAt = null;

    _safeNotify();
  }

  // ==========================================================
  // MENSAGEM DE ERRO AMIGÁVEL
  // ==========================================================

  String _friendlyErrorMessage(Object error) {
    final text = error.toString().toLowerCase();

    if (text.contains('authenticated') ||
        text.contains('autenticado') ||
        text.contains('jwt')) {
      return 'Sua sessão expirou. Entre novamente.';
    }

    if (text.contains('network') ||
        text.contains('socket') ||
        text.contains('connection') ||
        text.contains('failed to fetch')) {
      return 'Não foi possível conectar ao servidor.';
    }

    if (text.contains('permission') ||
        text.contains('policy') ||
        text.contains('42501')) {
      return 'Você não possui permissão para acessar esses dados.';
    }

    return 'Não foi possível carregar sua produção criativa.';
  }

  // ==========================================================
  // NOTIFY
  // ==========================================================

  void _safeNotify() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    _months = const <CreativeProductionMonth>[];

    super.dispose();
  }
}
