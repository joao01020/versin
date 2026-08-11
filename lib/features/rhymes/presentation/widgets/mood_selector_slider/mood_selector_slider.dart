import 'package:flutter/material.dart';

class MoodSelectorSlider
    extends
        StatefulWidget {
  final void Function(
    double value,
    String name,
    bool isFinalStep,
  )
  onSelectionChanged;

  const MoodSelectorSlider({
    super.key,
    required this.onSelectionChanged,
  });

  @override
  State<
    MoodSelectorSlider
  >
  createState() => _MoodSelectorSliderState();
}

class _MoodSelectorSliderState
    extends
        State<
          MoodSelectorSlider
        > {
  double _currentValue = 0;
  int _currentStep = 0;

  final List<
    String
  >
  _moods = [
    'Calmo',
    'Contemplativo',
    'Melancólico',
    'Romance',
    'Energético',
    'Agressivo',
  ];

  final List<
    Map<
      String,
      String
    >
  >
  _techniques = [
    {
      'name': 'Melódico',
      'desc': 'Canto afinado e suave, focado na harmonia.',
    },
    {
      'name': 'Seco',
      'desc': 'Voz direta, sem ornamentos, estilo "falado".',
    },
    {
      'name': 'Canto Lírico',
      'desc': 'Projeção ampla e vibrato controlado.',
    },
    {
      'name': 'Belting',
      'desc': 'Voz de peito levada ao agudo com potência.',
    },
    {
      'name': 'Falsete',
      'desc': 'Voz de cabeça para notas super agudas.',
    },
    {
      'name': 'Canto Nasal',
      'desc': 'Som direcionado ao nariz, essencial no Trap.',
    },
    {
      'name': 'Drive',
      'desc': 'Voz "rasgada" com distorção natural.',
    },
    {
      'name': 'Sussurrado',
      'desc': 'Canto com excesso de ar, íntimo e suave.',
    },
    {
      'name': 'Rap / Rítmico',
      'desc': 'Foco total na métrica e cadência rítmica.',
    },
  ];

  bool get _isMoodStep =>
      _currentStep ==
      0;

  int get _currentIndex => _currentValue.toInt();

  double get _maxValue => _isMoodStep
      ? 5
      : 8;

  String get _currentName => _isMoodStep
      ? _moods[_currentIndex]
      : _techniques[_currentIndex]['name']!;

  String? get _currentDescription => _isMoodStep
      ? null
      : _techniques[_currentIndex]['desc'];

  Color get _dynamicColor {
    final intensity =
        _currentValue /
        _maxValue;

    return Color.lerp(
      Colors.grey,
      const Color(
        0xFFE100FF,
      ),
      intensity,
    )!;
  }

  void _onSliderChanged(
    double value,
  ) {
    setState(
      () {
        _currentValue = value;
      },
    );

    if (_isMoodStep) {
      widget.onSelectionChanged(
        _currentValue,
        _currentName,
        false,
      );
    }
  }

  void _confirmSelection() {
    if (_isMoodStep) {
      widget.onSelectionChanged(
        _currentValue,
        _currentName,
        false,
      );

      setState(
        () {
          _currentStep = 1;
          _currentValue = 0;
        },
      );

      return;
    }

    widget.onSelectionChanged(
      _currentValue,
      _currentName,
      true,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final dynamicColor = _dynamicColor;

    return Container(
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.03,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isMoodStep
                ? 'Defina a energia emocional da letra:'
                : 'Como será a performance vocal no estúdio?',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            _isMoodStep
                ? 'Vibe: $_currentName'
                : 'Técnica: $_currentName',
            style: TextStyle(
              color: dynamicColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),

          if (_currentDescription !=
              null)
            Padding(
              padding: const EdgeInsets.only(
                top: 6,
              ),
              child: Text(
                _currentDescription!,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          const SizedBox(
            height: 10,
          ),

          SliderTheme(
            data:
                SliderTheme.of(
                  context,
                ).copyWith(
                  trackHeight: 4,
                  activeTrackColor: dynamicColor,
                  inactiveTrackColor: Colors.white12,
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  overlayColor: dynamicColor.withAlpha(
                    40,
                  ),
                  tickMarkShape: const RoundSliderTickMarkShape(
                    tickMarkRadius: 1.5,
                  ),
                  activeTickMarkColor: Colors.white30,
                ),
            child: Slider(
              value: _currentValue,
              min: 0,
              max: _maxValue,
              divisions: _maxValue.toInt(),
              onChanged: _onSliderChanged,
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isMoodStep
                    ? Colors.white10
                    : dynamicColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              child: Text(
                _isMoodStep
                    ? 'PRÓXIMO: TÉCNICA VOCAL'
                    : 'INICIAR SESSÃO NO ESTÚDIO',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
