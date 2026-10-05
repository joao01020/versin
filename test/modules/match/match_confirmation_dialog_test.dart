import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:versin/modules/match/page/dialogs/match_confirmation_dialog.dart';
import 'package:versin/modules/match/page/services/match_confirmation_service.dart';

void main() {
  const confirmation = MatchConfirmation(
    projectId: 'project-test',
    self: MatchConfirmationProfile(id: 'a', name: 'Artista A', username: 'a'),
    other: MatchConfirmationProfile(id: 'b', name: 'Artista B', username: 'b'),
  );

  for (final action in MatchConfirmationAction.values) {
    testWidgets('Modal retorna ${action.name}', (tester) async {
      MatchConfirmationAction? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showDialog<MatchConfirmationAction>(
                    context: context,
                    builder: (_) => const MatchConfirmationDialog(
                      confirmation: confirmation,
                    ),
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Deu Match!'), findsOneWidget);
      expect(find.text('Artista A'), findsOneWidget);
      expect(find.text('Artista B'), findsOneWidget);
      await tester.tap(
        find.text(
          action == MatchConfirmationAction.viewProject
              ? 'Ver projeto'
              : 'Continuar descobrindo',
        ),
      );
      await tester.pumpAndSettle();
      expect(result, action);
    });
  }
}
