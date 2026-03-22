import 'package:flutter/material.dart';
import '../pages/settings_page.dart';

class VersinDrawer extends StatelessWidget {
  final VoidCallback? onNewChat; // Função para limpar o chat

  const VersinDrawer({super.key, this.onNewChat});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF121212),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: Colors.purpleAccent.withOpacity(0.3), 
              width: 2,
            ),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 10),
              child: OutlinedButton.icon(
                onPressed: () {
                  if (onNewChat != null) onNewChat!(); // Executa a limpeza
                  Navigator.pop(context); // Fecha o menu
                },
                icon: const Icon(Icons.add, color: Colors.purpleAccent),
                label: const Text("Nova conversa", style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.purpleAccent.withOpacity(0.4)),
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),

            _drawerTile(Icons.book_outlined, "Dicionário", () {}),
            _drawerTile(Icons.star_border, "Favoritos", () {}),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Pesquisar rimas...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  prefixIcon: const Icon(Icons.search, color: Colors.purpleAccent, size: 20),
                  filled: true,
                  fillColor: Colors.purpleAccent.withOpacity(0.05),
                  contentPadding: const EdgeInsets.all(0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), 
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const Divider(color: Colors.white10),

            const Padding(
              padding: EdgeInsets.only(left: 20, top: 10, bottom: 5),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Conversas", 
                  style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerTile(Icons.chat_bubble_outline, "Beat Trap 140bpm - Agressivo", () {}),
                  _drawerTile(Icons.chat_bubble_outline, "Emo trap 90bpm - Melancolico ", () {}),
                ],
              ),
            ),

            const Divider(color: Colors.white10),

            _drawerTile(Icons.settings_outlined, "Configuração", () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            }),
            
            _drawerTile(Icons.help_outline, "Ajuda", () {}),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.purpleAccent, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}