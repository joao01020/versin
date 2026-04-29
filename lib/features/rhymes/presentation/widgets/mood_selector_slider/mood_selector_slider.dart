import 'package:flutter/material.dart';

class MoodSelectorSlider extends StatefulWidget {
  final Function(double) onMoodChanged;
  const MoodSelectorSlider({super.key, required this.onMoodChanged});

  @override
  State<MoodSelectorSlider> createState() => _MoodSelectorSliderState();
}

class _MoodSelectorSliderState extends State<MoodSelectorSlider> {
  double _currentValue = 0;
  final List<String> _moods = [
    'Calmo', 
    'Contemplativo', 
    'Melancólico', 
    'Romance', 
    'Energético', 
    'Agressivo'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Vibe: ${_moods[_currentValue.toInt()]}",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: const Color(0xFF9130FF), // Roxo da referência
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0, elevation: 5),
            overlayColor: const Color(0xFF9130FF).withAlpha(32),
            // Estilo dos "pontinhos" da referência
            tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2),
            activeTickMarkColor: Colors.white54,
          ),
          child: Slider(
            value: _currentValue,
            min: 0,
            max: 5,
            divisions: 5,
            onChanged: (value) {
              setState(() {
                _currentValue = value;
              });
              widget.onMoodChanged(value);
            },
          ),
        ),
      ],
    );
  }
}