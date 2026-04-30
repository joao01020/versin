import 'package:flutter/material.dart';

class MoodSelectorSlider extends StatefulWidget {
  final Function(double, String, bool) onSelectionChanged; // Valor, Nome, isFinalStep
  
  const MoodSelectorSlider({super.key, required this.onSelectionChanged});

  @override
  State<MoodSelectorSlider> createState() => _MoodSelectorSliderState();
}

class _MoodSelectorSliderState extends State<MoodSelectorSlider> {
  double _currentValue = 0;
  int _currentStep = 0; // 0 para Vibe, 1 para Técnica Vocal (Performance)

  // Lista de Humores (Vibe Emocional para composição)
  final List<String> _moods = [
    'Calmo',
    'Contemplativo',
    'Melancólico',
    'Romance',
    'Energético',
    'Agressivo',
  ];

  // Lista de Técnicas com foco em Trap/Rap e performance vocal
  final List<Map<String, String>> _techniques = [
    {'name': 'Melódico', 'desc': 'Canto afinado e suave, focado na harmonia.'},
    {'name': 'Seco', 'desc': 'Voz direta, sem ornamentos, estilo "falado".'},
    {'name': 'Canto Lírico', 'desc': 'Projeção ampla e vibrato controlado.'},
    {'name': 'Belting', 'desc': 'Voz de peito levada ao agudo com potência.'},
    {'name': 'Falsete', 'desc': 'Voz de cabeça para notas super agudas.'},
    {'name': 'Canto Nasal', 'desc': 'Som direcionado ao nariz, essencial no Trap.'},
    {'name': 'Drive', 'desc': 'Voz "rasgada" com distorção natural.'},
    {'name': 'Sussurrado', 'desc': 'Canto com excesso de ar, íntimo e suave.'},
    {'name': 'Rap / Rítmico', 'desc': 'Foco total na métrica e cadência rítmica.'},
  ];

  @override
  Widget build(BuildContext context) {
    // Cálculo do Gradiente Visual: Transição suave do Cinza para o Vermelho/Magenta Versin
    double intensity = _currentValue / (_currentStep == 0 ? 5 : 8);
    Color dynamicColor = Color.lerp(Colors.grey, const Color(0xFFE100FF), intensity)!;

    String currentTitle = _currentStep == 0 
        ? "Vibe: ${_moods[_currentValue.toInt()]}" 
        : "Técnica: ${_techniques[_currentValue.toInt()]['name']}";

    String? currentDesc = _currentStep == 1 
        ? _techniques[_currentValue.toInt()]['desc'] 
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instrução de Fluxo de configuração
          Text(
            _currentStep == 0 
                ? "Defina a energia emocional da letra:" 
                : "Como será a performance vocal no estúdio?",
            style: const TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          
          // Nome da Seleção Atual (Animado pela cor dinâmica da marca)
          Text(
            currentTitle,
            style: TextStyle(
              color: dynamicColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
          
          // Descrição da Técnica Vocal selecionada
          if (currentDesc != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                currentDesc,
                style: const TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),

          const SizedBox(height: 10),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: dynamicColor,
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayColor: dynamicColor.withAlpha(40),
              tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 1.5),
              activeTickMarkColor: Colors.white30,
            ),
            child: Slider(
              value: _currentValue,
              min: 0,
              max: _currentStep == 0 ? 5 : 8,
              divisions: _currentStep == 0 ? 5 : 8,
              onChanged: (value) {
                setState(() {
                  _currentValue = value;
                });
                // Feedback em tempo real para a ChatPage atualizar o estado interno
                if (_currentStep == 0) {
                  widget.onSelectionChanged(_currentValue, _moods[_currentValue.toInt()], false);
                }
              },
            ),
          ),

          const SizedBox(height: 15),

          // Botão de Ação: Avançar entre Vibe e Técnica ou Finalizar para salvar no Supabase
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep == 0 ? Colors.white10 : dynamicColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (_currentStep == 0) {
                  // Confirma a Vibe selecionada e alterna para Técnica Vocal
                  widget.onSelectionChanged(_currentValue, _moods[_currentValue.toInt()], false);
                  setState(() {
                    _currentStep = 1;
                    _currentValue = 0; // Reinicia o slider para a nova lista de técnicas
                  });
                } else {
                  // Dispara o isFinalStep: true, iniciando o registro da sessão no Supabase
                  widget.onSelectionChanged(
                    _currentValue, 
                    _techniques[_currentValue.toInt()]['name']!, 
                    true
                  );
                }
              },
              child: Text(
                _currentStep == 0 ? "PRÓXIMO: TÉCNICA VOCAL" : "INICIAR SESSÃO NO ESTÚDIO",
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}