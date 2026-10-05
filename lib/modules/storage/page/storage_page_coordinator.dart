import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/app/locator.dart';
import 'package:versin/modules/storage/controllers/storage_controller.dart';
import 'package:versin/modules/storage/data/models/stored_work_model.dart';
import 'package:versin/modules/storage/page/dialogs/storage_delete_work_dialog.dart';
import 'package:versin/modules/storage/page/widgets/storage_register_work_sheet.dart';
import 'package:versin/modules/storage/page/widgets/storage_work_actions_sheet.dart';
import 'package:versin/modules/storage/views/beats/register_beats_page.dart';
import 'package:versin/modules/storage/views/lyrics/register_lyrics_page.dart';
import 'package:versin/modules/storage/views/storage_details_page.dart';
import 'package:versin/modules/storage/views/transfer_authorship_page.dart';

class StoragePageCoordinator extends ChangeNotifier {
  static const Color accentColor = Color(0xFFE100FF);

  static const Color backgroundColor = Color(0xFF0D0B1F);

  static const Color surfaceColor = Color(0xFF17132D);

  final StorageController controller = sl<StorageController>();

  final SupabaseClient _supabase;

  late final TabController tabController;

  bool isInitializingStorage = true;
  String? initializationError;

  bool _disposed = false;
  bool _initializing = false;

  StoragePageCoordinator({
    required TickerProvider vsync,
    SupabaseClient? supabase,
  }) : _supabase = supabase ?? Supabase.instance.client {
    tabController = TabController(length: 2, vsync: vsync);

    controller.addListener(_relayControllerState);
  }

  Future<void> initialize() async {
    if (_disposed || _initializing) {
      return;
    }

    _initializing = true;
    isInitializingStorage = true;
    initializationError = null;
    notifyListeners();

    try {
      final authUser = _supabase.auth.currentUser;

      final authenticatedUserId = authUser?.id.trim();

      if (authenticatedUserId == null || authenticatedUserId.isEmpty) {
        throw StateError(
          'Nenhum usuário autenticado. '
          'Faça login novamente para acessar suas obras.',
        );
      }

      final controllerUserId = controller.currentUserId?.trim();

      if (controllerUserId == null ||
          controllerUserId.isEmpty ||
          controllerUserId != authenticatedUserId) {
        await controller.init(userId: authenticatedUserId);
      } else {
        await controller.refresh();
      }

      if (_disposed) {
        return;
      }

      final controllerError = controller.errorMessage?.trim();

      if (controllerError != null && controllerError.isNotEmpty) {
        initializationError = controllerError;
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[STORAGE PAGE] '
        'Não foi possível inicializar o armazenamento.',
      );

      debugPrint(
        '[STORAGE PAGE] '
        'Erro: $error',
      );

      debugPrint(
        '[STORAGE PAGE] '
        'StackTrace: $stackTrace',
      );

      initializationError = error is StateError
          ? error.message
          : 'Não foi possível carregar suas obras.';
    } finally {
      _initializing = false;

      if (!_disposed) {
        isInitializingStorage = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh() {
    return controller.refresh();
  }

  List<StoredWorkModel> worksFor(StoredWorkType type) {
    return type == StoredWorkType.beat ? controller.beats : controller.lyrics;
  }

  Future<void> openRegisterLyrics(BuildContext context) async {
    final registered = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          return const RegisterLyricsPage();
        },
      ),
    );

    if (_disposed || !context.mounted || registered != true) {
      return;
    }

    await controller.refresh();

    if (_disposed) {
      return;
    }

    tabController.animateTo(1);
  }

  Future<void> openRegisterBeat(BuildContext context) async {
    final registered = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          return const RegisterBeatsPage();
        },
      ),
    );

    if (_disposed || !context.mounted || registered != true) {
      return;
    }

    await controller.refresh();

    if (_disposed) {
      return;
    }

    tabController.animateTo(0);
  }

  Future<void> openDetails(BuildContext context, StoredWorkModel work) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) {
          return StorageDetailsPage(work: work, accentColor: accentColor);
        },
      ),
    );
  }

  Future<void> openTransferAuthorship(
    BuildContext context,
    StoredWorkModel work,
  ) async {
    final transferred = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          return TransferAuthorshipPage(
            work: work,
            controller: controller,
            accentColor: accentColor,
          );
        },
      ),
    );

    if (_disposed || !context.mounted || transferred != true) {
      return;
    }

    await controller.refresh();

    if (!context.mounted) {
      return;
    }

    showMessage(context, 'Autoria transferida com sucesso.');
  }

  Future<void> confirmDelete(BuildContext context, StoredWorkModel work) async {
    final confirmed = await StorageDeleteWorkDialog.show(
      context: context,
      work: work,
      surfaceColor: surfaceColor,
    );

    if (!confirmed || _disposed || !context.mounted) {
      return;
    }

    final deleted = await controller.deleteWork(work.id);

    if (_disposed || !context.mounted) {
      return;
    }

    final isBeat = work.type == StoredWorkType.beat;

    showMessage(
      context,
      deleted
          ? '${isBeat ? 'Beat' : 'Letra'} apagado com sucesso.'
          : controller.errorMessage ?? 'Não foi possível apagar a obra.',
      error: !deleted,
    );
  }

  Future<void> showRegisterWorkOptions(BuildContext context) {
    return StorageRegisterWorkSheet.show(
      context: context,
      accentColor: accentColor,
      surfaceColor: surfaceColor,
      onRegisterLyrics: () {
        return openRegisterLyrics(context);
      },
      onRegisterBeat: () {
        return openRegisterBeat(context);
      },
    );
  }

  Future<void> showWorkActions(BuildContext context, StoredWorkModel work) {
    return StorageWorkActionsSheet.show(
      context: context,
      work: work,
      accentColor: accentColor,
      surfaceColor: surfaceColor,
      onOpenDetails: () {
        openDetails(context, work);
      },
      onVerifyHash: () {
        showMessage(
          context,
          'A verificação de integridade será conectada na próxima etapa.',
        );
      },
      onTransferAuthorship: () {
        return openTransferAuthorship(context, work);
      },
      onDelete: () {
        return confirmDelete(context, work);
      },
    );
  }

  void showMessage(BuildContext context, String message, {bool error = false}) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? const Color(0xFF8B1E3F) : surfaceColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _relayControllerState() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    controller.removeListener(_relayControllerState);

    tabController.dispose();

    super.dispose();
  }
}
