import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart'; // Importado para o logout
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/features/rhymes/presentation/pages/drawer/ai_memory/ai_memory_page.dart';
import 'package:versin/features/rhymes/presentation/pages/drawer/rhyme_level/rhyme_level_page.dart';

class SettingsPage extends StatefulWidget {
  final RhymesController controller; 
  const SettingsPage({super.key, required this.controller});

  @override
  State<SettingsPage> createState() => PageSettings();
}

class PageSettings extends State<SettingsPage> {
  final _keyController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  // Função para deslogar do Supabase
  Future<void> _handleSignOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        // Remove todas as telas e volta para a raiz (onde o listener do main.dart vai agir)
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao sair: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openGoogleStudio() async {
    final Uri url = Uri.parse('https://aistudio.google.com/');
    if (!await launchUrl(url)) {
      throw Exception('Não foi possível abrir o link');
    }
  }

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
          _buildSectionTitle("Versin Pro & Autonomia"),
          _buildProCard(), 
          
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextField(
              controller: _keyController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Cole sua API Key aqui...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.purpleAccent),
                  onPressed: () {
                    widget.controller.setApiKey(_keyController.text.trim());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Chave salva! Modo Pro Ativado. 🚀")),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),
          _buildSectionTitle("AI & Flow"),
          _settingsTile(
            Icons.auto_awesome_outlined, 
            "Nível de Rima", 
            "Configurar gênero, BPM e tom", 
            () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const RhymeLevelPage()));
            }
          ),
          _settingsTile(
            Icons.memory_outlined, 
            "Memória da IA", 
            "Gerenciar uso de contexto e cache", 
            () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AIMemoryPage()));
            }
          ),
          
          const SizedBox(height: 20),
          _buildSectionTitle("Aplicativo"),
          _settingsTile(Icons.dark_mode_outlined, "Tema", "Escuro (Padrão)", () {}),
          _settingsTile(Icons.notifications_none, "Notificações", "Gerenciar alertas", () {}),
          
          const SizedBox(height: 40),
          Center(
            child: TextButton(
              onPressed: _handleSignOut, // BOTÃO AGORA FUNCIONAL
              child: const Text("Sair da Conta", style: TextStyle(color: Colors.redAccent)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("🚀 O Próximo Nível do seu Flow", 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          const Text(
            "Cansou do limite diário? Use sua própria API Key para ter mensagens ilimitadas, "
            "mais velocidade e segurança total.",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          const Text("🎁 Teste Grátis (Copie e Cole):", 
            style: TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold)),
          const SelectableText("VERSIN-PRO-TRIAL-2026-FREE", 
            style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13)),
          const SizedBox(height: 15),
          const Text("🛠️ Como conseguir minha chave?", 
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          _stepText("1. Acesse o Google AI Studio"),
          _stepText("2. Gere sua Key em 'Get API Key'"),
          _stepText("3. O Versin não lucra nada com isso, é sua ponte direta com a IA."),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _openGoogleStudio,
            child: const Text("👉 Abrir Google AI Studio", 
              style: TextStyle(color: Colors.blueAccent, fontSize: 12, decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }

  Widget _stepText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text("• $text", style: const TextStyle(color: Colors.grey, fontSize: 11)),
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