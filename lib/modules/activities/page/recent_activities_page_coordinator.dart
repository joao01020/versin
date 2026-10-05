import 'package:flutter/foundation.dart';

import 'package:versin/app/locator.dart';
import 'package:versin/modules/activities/controllers/recent_activity_controller.dart';
import 'package:versin/modules/activities/models/recent_activity_model.dart';

class RecentActivitiesPageCoordinator extends ChangeNotifier {
  final RecentActivityController controller = sl<RecentActivityController>();

  List<RecentActivityModel> monthlyActivities = <RecentActivityModel>[];

  bool isLoading = false;
  String? errorMessage;

  bool _disposed = false;

  RecentActivitiesPageCoordinator() {
    controller.addListener(_onControllerUpdate);
  }

  Future<void> initialize() {
    return loadMonthlyActivities();
  }

  Future<void> loadMonthlyActivities() async {
    if (_disposed || isLoading) {
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final activities = await controller.getAllActivities();

      if (_disposed) {
        return;
      }

      _applyMonthlyFilter(activities);
    } catch (error, stackTrace) {
      debugPrint(
        '[RECENT ACTIVITIES] '
        'Erro ao carregar atividades: $error',
      );

      debugPrint('$stackTrace');

      if (!_disposed) {
        errorMessage = 'Não foi possível carregar as atividades.';
        notifyListeners();
      }
    } finally {
      if (!_disposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> deleteActivity(String activityId) async {
    final success = await controller.deleteActivity(activityId);

    if (_disposed) {
      return success;
    }

    if (success) {
      monthlyActivities = monthlyActivities.where((item) {
        return item.id != activityId;
      }).toList();

      notifyListeners();
    }

    return success;
  }

  void _onControllerUpdate() {
    if (_disposed) {
      return;
    }

    _applyMonthlyFilter(controller.activities);
  }

  void _applyMonthlyFilter(Iterable<RecentActivityModel> activities) {
    final now = DateTime.now();

    final filtered = activities.where((activity) {
      final date = activity.createdAt.toLocal();

      return date.year == now.year && date.month == now.month;
    }).toList();

    filtered.sort((a, b) {
      return b.createdAt.compareTo(a.createdAt);
    });

    monthlyActivities = filtered;

    if (!_disposed) {
      notifyListeners();
    }
  }

  String get currentMonthLabel {
    final now = DateTime.now();

    return '${_monthName(now.month)} ${now.year}';
  }

  String _monthName(int month) {
    const months = <String>[
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    if (month < 1 || month > 12) {
      return '';
    }

    return months[month - 1];
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    controller.removeListener(_onControllerUpdate);

    super.dispose();
  }
}
