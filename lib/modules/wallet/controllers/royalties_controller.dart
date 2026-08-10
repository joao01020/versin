import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class RoyaltiesController
    extends
        ChangeNotifier {
  // CORES
  final Color primaryPurple = const Color(
    0xFF6A1B9A,
  );
  final Color accentNeon = const Color(
    0xFF0E10E6,
  );
  final Color cardBg = const Color(
    0xFF161427,
  );
  final Color deepBg = const Color(
    0xFF0D0B1F,
  );

  // ESTADOS
  bool _isLoading = true;
  double _totalRevenue = 0.0;

  final double _monthlyRevenue = 0.0;
  final int _totalStreams = 0;
  final double _ageGroup1 = 0.0;
  final double _ageGroup2 = 0.0;
  final double _ageGroup3 = 0.0;

  List<
    FlSpot
  >
  _revenueHistory = [];

  final List<
    Map<
      String,
      dynamic
    >
  >
  _topTracks = [];

  // GETTERS
  bool get isLoading => _isLoading;
  double get totalRevenue => _totalRevenue;
  double get monthlyRevenue => _monthlyRevenue;
  int get totalStreams => _totalStreams;
  double get ageGroup1 => _ageGroup1;
  double get ageGroup2 => _ageGroup2;
  double get ageGroup3 => _ageGroup3;
  List<
    FlSpot
  >
  get revenueHistory => _revenueHistory;
  List<
    Map<
      String,
      dynamic
    >
  >
  get topTracks => _topTracks;

  RoyaltiesController() {
    loadData();
  }

  Future<
    void
  >
  loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _totalRevenue = 0.0;
      _revenueHistory = [];
    } catch (
      e
    ) {
      debugPrint(
        'Erro ao carregar royalties: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<
    void
  >
  refresh() => loadData();
}
