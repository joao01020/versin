import 'package:flutter/material.dart';
import 'ai_memory_page.dart';
import 'rhyme_level_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('CONFIGURAÇÕES', 
          style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w300, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.purpleAccent),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle("Perfil"),
          _settingsTile(Icons.person_outline, "Editar Perfil", "Mude seu nome e avatar", () {}),
          
          const SizedBox(height: 20),
          _buildSectionTitle("Aplicativo"),
          _settingsTile(Icons.dark_mode_outlined, "Tema", "Escuro (Padrão)", () {}),
          _settingsTile(Icons.notifications_none, "Notificações", "Gerenciar alertas", () {}),
          
          const SizedBox(height: 20),
          _buildSectionTitle("AI & Flow"),
          
          // CORRIGIDO: Removido o 'const' antes de RhymeLevelPage()
          _settingsTile(
            Icons.auto_awesome_outlined, 
            "Nível de Rima", 
            "Configurar gênero, BPM e tom", 
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RhymeLevelPage()), 
              );
            }
          ),
          
          _settingsTile(
            Icons.memory_outlined, 
            "Memória da IA", 
            "Gerenciar uso de contexto e cache", 
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AIMemoryPage()),
              );
            }
          ),
          
          const SizedBox(height: 40),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text("Sair da Conta", style: TextStyle(color: Colors.redAccent)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Text(title, 
        style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _settingsTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
      onTap: onTap,
    );
  }
}