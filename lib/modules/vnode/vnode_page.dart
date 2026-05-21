import 'package:flutter/material.dart';
import 'package:versin/app/routes/app_routes.dart'; // Importação do sistema de rotas

class VNodePage extends StatefulWidget {
  // Rota estática definida para referência centralizada
  static const String routeName = AppRoutes.vnode;

  const VNodePage({super.key});

  @override
  State<VNodePage> createState() => _VNodePageState();
}

class _VNodePageState extends State<VNodePage> {
  // CONFIGURAÇÃO DE CORES DO ECOSSISTEMA VERSIN
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color accentNeon = const Color(0xFFE040FB);
  final Color deepBg = const Color(0xFF0D0B1F);

  // MOCK DE POSTAGENS DE MÚSICAS DOS USUÁRIOS
  final List<Map<String, dynamic>> _posts = [
    {
      "id": "post-1",
      "username": "Pedro_Beats",
      "userAvatar": null,
      "trackTitle": "Ragnarok (Prod. Pedro)",
      "duration": "02:45",
      "currentProgress": 0.35,
      "isPlaying": false,
      "likes": 142,
      "isLiked": false,
      "shares": 28,
      "comments": [
        {"author": "Joao_Vitor", "text": "Esse drop no começo ficou absurdo!", "timestamp": "00:15"},
        {"author": "Yuki_Trap", "text": "O 808 tá batendo limpo demais aqui", "timestamp": "01:02"},
        {"author": "Rhymer_01", "text": "Mandei uma rima nessa parte e encaixou certinho", "timestamp": "01:45"}
      ]
    },
    {
      "id": "post-2",
      "username": "Lucas_Verso",
      "userAvatar": null,
      "trackTitle": "Corte Neon (Demo)",
      "duration": "03:12",
      "currentProgress": 0.0,
      "isPlaying": false,
      "likes": 89,
      "isLiked": true,
      "shares": 12,
      "comments": [
        {"author": "Pedro_Beats", "text": "Gostei da ambição desse refrão", "timestamp": "00:48"}
      ]
    }
  ];

  // CONTROLADORES PARA NOVOS COMENTÁRIOS
  final Map<String, TextEditingController> _commentControllers = {};
  final Map<String, String> _selectedTimestamps = {}; // Armazena o trecho selecionado para comentar

  @override
  void initState() {
    super.initState();
    for (var post in _posts) {
      _commentControllers[post["id"]] = TextEditingController();
      _selectedTimestamps[post["id"]] = "00:00"; // Padrão
    }
  }

  @override
  void dispose() {
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // INTERAÇÃO: CURTIR
  void _toggleLike(int index) {
    setState(() {
      _posts[index]["isLiked"] = !_posts[index]["isLiked"];
      if (_posts[index]["isLiked"]) {
        _posts[index]["likes"]++;
      } else {
        _posts[index]["likes"]--;
      }
    });
  }

  // INTERAÇÃO: ADICIONAR COMENTÁRIO
  void _addComment(String postId, int postIndex) {
    final text = _commentControllers[postId]!.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _posts[postIndex]["comments"].add({
        "author": "Você",
        "text": text,
        "timestamp": _selectedTimestamps[postId]
      });
      _commentControllers[postId]!.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildSectionTitle("Compartilhar nova track"),
            _buildUploadTrackCard(),
            const SizedBox(height: 24),
            _buildSectionTitle("Feed VNode • Últimos Lançamentos"),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _posts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                return _buildMusicPostCard(_posts[index], index);
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // COMPONENTE: CARD PARA POSTAR NOVA MÚSICA
  Widget _buildUploadTrackCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: accentNeon.withOpacity(0.4)),
            ),
            child: Icon(Icons.cloud_upload_outlined, color: accentNeon, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Exportou do estúdio?", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text("Suba seu arquivo .mp3 ou .wav na rede VNode", style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentNeon,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () {},
            child: const Text("Postar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // COMPONENTE: CARD DA MÚSICA NO FEED
  Widget _buildMusicPostCard(Map<String, dynamic> post, int postIndex) {
    String postId = post["id"];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: primaryPurple.withOpacity(0.4),
                child: const Icon(Icons.person, color: Colors.white70, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                post["username"],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, color: Colors.white30),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.03)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() => post["isPlaying"] = !post["isPlaying"]);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: accentNeon, shape: BoxShape.circle),
                    child: Icon(post["isPlaying"] ? Icons.pause : Icons.play_arrow, color: Colors.black, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post["trackTitle"], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          activeTrackColor: accentNeon,
                          inactiveTrackColor: Colors.white12,
                          thumbColor: accentNeon,
                        ),
                        child: Slider(
                          value: post["currentProgress"],
                          onChanged: (val) {
                            setState(() => post["currentProgress"] = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(post["duration"], style: const TextStyle(color: Colors.white30, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              _buildActionButton(
                icon: post["isLiked"] ? Icons.favorite : Icons.favorite_border,
                label: "${post["likes"]}",
                iconColor: post["isLiked"] ? Colors.redAccent : Colors.white54,
                onTap: () => _toggleLike(postIndex),
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: "${post["comments"].length}",
                iconColor: Colors.white54,
                onTap: () {},
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: "${post["shares"]}",
                iconColor: Colors.white54,
                onTap: () {
                  setState(() => post["shares"]++);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, thickness: 1, color: Colors.white.withOpacity(0.04)),
          const SizedBox(height: 14),

          const Text("Comentários", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: post["comments"].length,
            itemBuilder: (context, cIndex) {
              final comment = post["comments"][cIndex];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${comment["author"]}: ", style: TextStyle(color: accentNeon, fontSize: 13, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(comment["text"], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: primaryPurple.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          comment["timestamp"],
                          style: TextStyle(color: accentNeon, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              PopupMenuButton<String>(
                color: deepBg,
                onSelected: (String value) {
                  setState(() => _selectedTimestamps[postId] = value);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, color: accentNeon, size: 14),
                      const SizedBox(width: 4),
                      Text(_selectedTimestamps[postId] ?? "00:00", style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(value: "00:15", child: Text("00:15", style: TextStyle(color: Colors.white))),
                  const PopupMenuItem<String>(value: "00:45", child: Text("00:45", style: TextStyle(color: Colors.white))),
                  const PopupMenuItem<String>(value: "01:10", child: Text("01:10", style: TextStyle(color: Colors.white))),
                  const PopupMenuItem<String>(value: "02:00", child: Text("02:00", style: TextStyle(color: Colors.white))),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _commentControllers[postId],
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Comente sobre este trecho...",
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.03),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentNeon.withOpacity(0.3)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.send, color: accentNeon, size: 20),
                onPressed: () => _addComment(postId, postIndex),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color iconColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: accentNeon.withOpacity(0.8),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}