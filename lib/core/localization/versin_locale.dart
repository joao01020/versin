import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Configuração única de idioma para todos os MaterialApps do Versin.
abstract final class VersinLocale {
  static const Locale locale = Locale('pt', 'BR');

  static const List<Locale> supportedLocales = <Locale>[locale];

  static const localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];
}
