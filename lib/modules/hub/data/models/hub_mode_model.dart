import 'package:flutter/material.dart';

/// [HubModeModel] tipifica os canais de barramento injetados no hardware físico.
class HubModeModel {
  final String title;
  final String subtitle;
  final IconData icon;
  final String modeKey;
  final String command;

  const HubModeModel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.modeKey,
    required this.command,
  });
}