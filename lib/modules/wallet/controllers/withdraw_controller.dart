import 'package:flutter/foundation.dart';

// ============================================================
// WITHDRAW CONTROLLER
// ============================================================
//
// Controla o estado do fluxo de saque.
//
// Não conhece Widgets.
//
// Responsabilidades:
//
// - armazenar valor;
// - validar saque;
// - controlar loading;
// - armazenar erro;
// - executar callback de envio.
//
// O backend real poderá ser conectado futuramente através de
// WithdrawService.
//
// ============================================================

class WithdrawController
    extends
        ChangeNotifier {
  // ============================================================
  // ESTADO
  // ============================================================

  double _amount = 0;

  double _availableBalance = 0;

  bool _isSubmitting = false;

  String? _errorMessage;

  // ============================================================
  // GETTERS
  // ============================================================

  double get amount => _amount;

  double get availableBalance => _availableBalance;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  bool get hasError =>
      _errorMessage !=
      null;

  bool get hasAmount =>
      _amount >
      0;

  bool get exceedsBalance =>
      _amount >
      _availableBalance;

  bool get canSubmit {
    return !_isSubmitting &&
        _amount >
            0 &&
        _amount <=
            _availableBalance;
  }

  // ============================================================
  // CONFIGURAR SALDO
  // ============================================================

  void setAvailableBalance(
    double value,
  ) {
    final normalized =
        value <
            0
        ? 0.0
        : value;

    if (_availableBalance ==
        normalized) {
      return;
    }

    _availableBalance = normalized;

    _validate();

    notifyListeners();
  }

  // ============================================================
  // ALTERAR VALOR
  // ============================================================

  void setAmount(
    double value,
  ) {
    _amount =
        value <
            0
        ? 0
        : value;

    _validate();

    notifyListeners();
  }

  // ============================================================
  // ALTERAR VALOR POR TEXTO
  // ============================================================

  void setAmountFromText(
    String value,
  ) {
    var normalized = value
        .trim()
        .replaceAll(
          'R\$',
          '',
        )
        .replaceAll(
          ' ',
          '',
        );

    // ==========================================================
    // FORMATO BRASILEIRO
    // ==========================================================
    //
    // Exemplo:
    //
    // 1.500,50
    //
    // vira:
    //
    // 1500.50
    //
    // ==========================================================

    if (normalized.contains(
      ',',
    )) {
      normalized = normalized
          .replaceAll(
            '.',
            '',
          )
          .replaceAll(
            ',',
            '.',
          );
    }

    final parsed =
        double.tryParse(
          normalized,
        ) ??
        0;

    setAmount(
      parsed,
    );
  }

  // ============================================================
  // USAR SALDO TOTAL
  // ============================================================

  void useFullBalance() {
    _amount = _availableBalance;

    _clearErrorInternal();

    notifyListeners();
  }

  // ============================================================
  // VALIDAR
  // ============================================================

  bool validate() {
    return _validate();
  }

  bool _validate() {
    if (_amount <=
        0) {
      _errorMessage = 'Informe um valor para o saque.';

      return false;
    }

    if (_amount >
        _availableBalance) {
      _errorMessage = 'O valor informado é maior que o saldo disponível.';

      return false;
    }

    _errorMessage = null;

    return true;
  }

  // ============================================================
  // ENVIAR
  // ============================================================
  //
  // O callback mantém este controller independente do backend.
  //
  // Futuramente:
  //
  // WithdrawController
  //        ↓
  // WithdrawService
  //        ↓
  // API / Supabase / Gateway
  //
  // ============================================================

  Future<
    bool
  >
  submit({
    Future<
      void
    >
    Function(
      double amount,
    )?
    onSubmit,
  }) async {
    if (_isSubmitting) {
      return false;
    }

    if (!_validate()) {
      notifyListeners();

      return false;
    }

    _isSubmitting = true;

    _errorMessage = null;

    notifyListeners();

    try {
      if (onSubmit !=
          null) {
        await onSubmit(
          _amount,
        );
      }

      return true;
    } catch (
      error,
      stackTrace
    ) {
      _errorMessage = 'Não foi possível solicitar o saque.';

      debugPrint(
        '[WITHDRAW CONTROLLER] '
        'Erro: $error',
      );

      debugPrint(
        '[WITHDRAW CONTROLLER] '
        'Stack trace: $stackTrace',
      );

      return false;
    } finally {
      _isSubmitting = false;

      notifyListeners();
    }
  }

  // ============================================================
  // LIMPAR ERRO
  // ============================================================

  void clearError() {
    if (_errorMessage ==
        null) {
      return;
    }

    _clearErrorInternal();

    notifyListeners();
  }

  void _clearErrorInternal() {
    _errorMessage = null;
  }

  // ============================================================
  // RESET
  // ============================================================

  void reset({
    double? availableBalance,
  }) {
    _amount = 0;

    _isSubmitting = false;

    _errorMessage = null;

    if (availableBalance !=
        null) {
      _availableBalance =
          availableBalance <
              0
          ? 0
          : availableBalance;
    }

    notifyListeners();
  }
}
