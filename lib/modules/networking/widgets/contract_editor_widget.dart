import 'package:flutter/material.dart';

class ContractEditorWidget
    extends
        StatefulWidget {
  final String initialContent;
  final Function(
    String,
  )
  onSave;

  const ContractEditorWidget({
    super.key,
    required this.initialContent,
    required this.onSave,
  });

  @override
  State<
    ContractEditorWidget
  >
  createState() => _ContractEditorWidgetState();
}

class _ContractEditorWidgetState
    extends
        State<
          ContractEditorWidget
        > {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialContent,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return TextField(
      controller: _controller,
      maxLines: 10,
      decoration: const InputDecoration(
        labelText: "Edite o contrato da equipe",
        border: OutlineInputBorder(),
      ),
      onChanged: widget.onSave, // Salva automaticamente ao digitar
    );
  }
}
