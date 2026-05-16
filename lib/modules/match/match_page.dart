import 'package:flutter/material.dart';

class MatchPage extends StatefulWidget {
  const MatchPage({super.key});

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  // CORES DO TEMA
  final Color accentNeon = const Color(0xFFE040FB);
  final Color primaryPurple = const Color(0xFF6A1B9A);

  // MOCK DE USUÁRIOS PARA O MATCH
  final List<Map<String, dynamic>> _profiles = [
    {
      "name": "MC Kadu",
      "tags": ["Trap", "Spit"],
      "bio": "Buscando produtores para EP focado em som Dark Trap.",
      "isOnline": true
    },
    {
      "name": "BeatMaker X",
      "tags": ["BoomBap", "Lofi"],
      "bio": "Colabores para rimas conscientes. Tenho 5 beats prontos.",
      "isOnline": false
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CABEÇALHO DA PÁGINA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Novas Conexões",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Encontre artistas com o seu flow",
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.tune, color: accentNeon),
                onPressed: () {}, // Filtros de busca
              )
            ],
          ),
          const SizedBox(height: 24),

          // CARD DE DESTAQUE (MATCH PRINCIPAL)
          _buildDiscoveryCard(),

          const SizedBox(height: 24),

          // SEÇÃO DE RECOMENDADOS
          const Text(
            "Recomendados para você",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // LISTA DE PERFIS
          Column(
            children: _profiles.map((p) => _buildProfileTile(p)).toList(),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildDiscoveryCard() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.bottomRight,
          colors: [primaryPurple.withOpacity(0.8), Colors.black54],
        ),
        image: const DecorationImage(
          image: NetworkImage("https://images.unsplash.com/photo-1514525253361-bee8718a7439?q=80&w=500"),
          fit: BoxFit.cover,
          opacity: 0.4,
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                const Text(
                  "Trap Star",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Icon(Icons.verified, color: accentNeon, size: 18),
              ],
            ),
            const Text(
              "Produtor & Compositor • 2km de você",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildActionButton(Icons.close, Colors.white24),
                const SizedBox(width: 12),
                _buildActionButton(Icons.favorite, accentNeon),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentNeon,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("OUVIR DEMO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildProfileTile(Map<String, dynamic> profile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: primaryPurple,
            child: Text(profile['name'][0], style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile['name'],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  profile['bio'],
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: (profile['tags'] as List).map((t) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text("#$t", style: TextStyle(color: accentNeon, fontSize: 10)),
                  )).toList(),
                )
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.white12, size: 14),
        ],
      ),
    );
  }
}