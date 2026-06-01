import 'package:flutter/material.dart';
import 'package:versin/modules/wallet/models/transaction_entity.dart';

// EN: Core controller managing state machine reactions for financial workflows
// PT: Controller core gerenciando as reações da máquina de estado para fluxos financeiros
class WalletController extends ChangeNotifier {
  // PALETA DE CORES DESIGN SYSTEM (VERSIN)
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color accentNeon = const Color(0xFF00E676);
  final Color deepBg = const Color(0xFF0D0B1F);

  // ESTADOS INTERNOS DA UI
  bool _isLoading = true;
  bool _isBalanceVisible = true; // Adicionado para controle de visibilidade do saldo
  double _totalBalance = 0.0;
  String _monthlyGrowthPercentage = "0.0%";
  List<TransactionEntity> _transactions = [];

  // GETTERS PÚBLICOS
  bool get isLoading => _isLoading;
  bool get isBalanceVisible => _isBalanceVisible; // Getter da visibilidade
  double get totalBalance => _totalBalance;
  String get monthlyGrowthPercentage => _monthlyGrowthPercentage;
  List<TransactionEntity> get transactions => _transactions;

  /// EN: Initializes the wallet module state and triggers data pulling simulation
  /// PT: Inicializa o estado do módulo de carteira e dispara a simulação de busca de dados
  void init() {
    fetchWalletData();
  }

  /// Alterna o estado de visibilidade do saldo na carteira
  void toggleBalanceVisibility() {
    _isBalanceVisible = !_isBalanceVisible;
    notifyListeners();
  }

  /// EN: Simulates an infrastructure ledger data call to populate dynamic transactions
  /// PT: Simula uma chamada de dados da ledger de infraestrutura para popular transações dinâmicas
  void fetchWalletData() {
    // Garante que o estado de loading seja notificado apenas se não estivermos em um fluxo de descarte
    _isLoading = true;
    notifyListeners();

    // EN: Mocked dataset following entity model standard to safely validate list builders
    // PT: Dataset mockado seguindo o padrão da entidade para validar os construtores de lista com segurança
    _transactions = [
      TransactionEntity(
        id: "tx_001",
        title: "Venda de Beats - Trap Track 'Hype'",
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        amount: 350.00,
        isPositive: true,
        icon: Icons.music_note,
      ),
      TransactionEntity(
        id: "tx_002",
        title: "Royalties Distribuição Digital (Abril)",
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        amount: 1420.50,
        isPositive: true,
        icon: Icons.album,
      ),
      TransactionEntity(
        id: "tx_003",
        title: "Assinatura Mensal - Plugins Premium",
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        amount: -89.90,
        isPositive: false,
        icon: Icons.extension,
      ),
    ];

    // EN: Calculates metrics based on mock arrays to feedback structural layout cards
    // PT: Calcula métricas baseadas nos arrays mockados para alimentar os cards do layout estrutural
    _totalBalance = 1680.60;
    _monthlyGrowthPercentage = "+12.4%";
    _isLoading = false;
    
    // Notifica os ouvintes após a conclusão da carga dos dados
    notifyListeners();
  }

  /// EN: Hard reset mechanism to test empty state components architecture
  /// PT: Mecanismo de reset forçado para testar a arquitetura de componentes em estado vazio (empty state)
  void setEmptyState() {
    _isLoading = false;
    _totalBalance = 0.0;
    _monthlyGrowthPercentage = "0.0%";
    _transactions = [];
    notifyListeners();
  }
}