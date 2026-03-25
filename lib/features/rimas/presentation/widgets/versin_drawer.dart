import 'package:flutter/material.dart';
import 'package:versin/features/rimas/presentation/controller/rimas_controller.dart';
import 'package:versin/features/rimas/presentation/pages/drawer/vocabulario_page.dart';
import 'package:versin/features/rimas/presentation/pages/drawer/settings/settings_page.dart';
import 'package:versin/features/rimas/presentation/pages/drawer/how_to_use_page.dart'; // Importação atualizada

class VersinDrawer extends StatelessWidget {
  final VoidCallback onNewChat;
  final RimasController rimasController;

  const VersinDrawer({
    super.key,
    required this.onNewChat,
    required this.rimasController,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0F0F0F),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER: GENESIS V1.0.2
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 30.0, 20.0, 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Genesis V1.0.2",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 1.5,
                    width: double.infinity,
                    color: Colors.purpleAccent,
                  ),
                ],
              ),
            ),
          ),

          // CAMPO DE PESQUISAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Pesquisar projetos...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.purpleAccent, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // SEÇÃO DE AÇÕES
          ListTile(
            leading: const Icon(Icons.add_box_outlined, color: Colors.white70),
            title: const Text("Novo Projeto", style: TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () {
              onNewChat();
              Navigator.pop(context);
            },
          ),

          // HOW TO USE (Título atualizado, conteúdo em PT-BR)
          ListTile(
            leading: const Icon(Icons.help_outline_rounded, color: Colors.blueAccent),
            title: const Text("Como usar?", style: TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HowToUsePage(), // Classe atualizada
                ),
              );
            },
          ),

          // DICIONÁRIO / VOCABULÁRIO
          ListTile(
            leading: const Icon(Icons.terminal_rounded, color: Colors.purpleAccent),
            title: const Text(
              "Dicionário / Vocabulário",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VocabularioPage(controller: rimasController),
                ),
              );
            },
          ),

          // CONFIGURAÇÕES
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: Colors.white70),
            title: const Text("Configurações", style: TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(controller: rimasController),
                ),
              );
            },
          ),

          const Spacer(),

          // RODAPÉ TÉCNICO
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Colors.purpleAccent, thickness: 1), 
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Versin V1.0.2 Genesis",
                      style: TextStyle(
                        color: Colors.grey, 
                        fontSize: 10, 
                        fontFamily: 'monospace'
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}