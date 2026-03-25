import 'package:flutter/material.dart';

class RhymeLevelPage extends StatefulWidget {
  const RhymeLevelPage({super.key});

  @override
  State<RhymeLevelPage> createState() => _RhymeLevelPageState();
}

class _RhymeLevelPageState extends State<RhymeLevelPage> {
  // Valores principais
  String selectedGenre = 'Automático';
  String selectedSubGenre = 'Padrão';
  String selectedBpm = 'Automático';
  String selectedKey = 'Automático';
  String selectedVocalStyle = 'Automático';
  
  // Variável para o Checkbox do Dicionário
  bool allowDataSharing = false;

  // Mapa de subcategorias focado em Trap, Rap e Funk
  final Map<String, List<String>> subGenres = {
    'Trap': ['Padrão', 'Emo Trap', 'Drill', 'Agressivo', 'Melódico', 'Dark Trap'],
    'Rap': ['Padrão', 'Boom Bap', 'Old School', 'Hardcore', 'Consciente', 'Lofi'],
    'Funk': ['Padrão', 'Mandelão', 'Consciente', 'MTG', 'Proibidão', 'Ostentação'],
    'Automático': ['Padrão'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('NÍVEL DE RIMA', 
          style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w300, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.purpleAccent),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Configurações de Estilo",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),

          // Seleção de Gênero Principal (Apenas vertentes urbanas)
          _buildDropdown(
            label: "Gênero Musical",
            value: selectedGenre,
            items: ['Automático', 'Trap', 'Rap', 'Funk'],
            onChanged: (val) {
              setState(() {
                selectedGenre = val!;
                selectedSubGenre = 'Padrão'; // Reseta a subcategoria ao mudar o gênero
              });
            },
          ),

          // Subcategoria Dinâmica
          if (subGenres.containsKey(selectedGenre))
            _buildDropdown(
              label: "Subgênero / Vibe",
              value: selectedSubGenre,
              items: subGenres[selectedGenre]!,
              onChanged: (val) => setState(() => selectedSubGenre = val!),
            ),

          _buildDropdown(
            label: "BPM",
            value: selectedBpm,
            items: ['Automático', '60-80', '90-110', '120-140', '150-180'],
            onChanged: (val) => setState(() => selectedBpm = val!),
          ),

          _buildDropdown(
            label: "Tom da Voz / Beat",
            value: selectedKey,
            items: ['Automático', 'C Maior', 'A Menor', 'G Maior', 'E Menor', 'F# Menor'],
            onChanged: (val) => setState(() => selectedKey = val!),
          ),

          _buildDropdown(
            label: "Dinâmica Vocal",
            value: selectedVocalStyle,
            items: ['Automático', 'Direto', 'Melisma', 'Extensões'],
            onChanged: (val) => setState(() => selectedVocalStyle = val!),
          ),

          const Divider(color: Colors.white10, height: 40),

          // SEÇÃO DE COLABORAÇÃO E RECOMPENSAS
          const Text(
            "Comunidade & Dicionário",
            style: TextStyle(color: Colors.purpleAccent, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.purpleAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purpleAccent.withOpacity(0.2)),
            ),
            child: CheckboxListTile(
              title: const Text(
                "Compartilhar meu dicionário",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              subtitle: const Text(
                "Ganhe recompensas e tokens quando outros usuários curtirem sua lista.",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              value: allowDataSharing,
              activeColor: Colors.purpleAccent,
              checkColor: Colors.black,
              onChanged: (bool? value) {
                setState(() {
                  allowDataSharing = value!;
                });
              },
              controlAffinity: ListTileControlAffinity.trailing,
            ),
          ),

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("SALVAR SETUP", 
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label, 
    required String value, 
    required List<String> items, 
    required ValueChanged<String?> onChanged
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            dropdownColor: const Color(0xFF1E1E1E),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}