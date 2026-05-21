import 'package:flutter/material.dart';
import 'package:versin/app/locator.dart'; // Importação do locator
import 'package:versin/app/routes/app_routes.dart'; // Importação do sistema de rotas
import 'package:versin/modules/dashboard/controllers/dashboard_controller.dart';

class ShowcasePage extends StatefulWidget {
  // Rota estática definida para referência centralizada
  static const String routeName = AppRoutes.showcase;

  const ShowcasePage({super.key});

  @override
  State<ShowcasePage> createState() => _ShowcasePageState();
}

class _ShowcasePageState extends State<ShowcasePage> with SingleTickerProviderStateMixin {
  // Buscamos a instância única do controller via GetIt
  final DashboardController controller = sl<DashboardController>();
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1F), // Fundo unificado
      body: Column(
        children: [
          // HEADER COM BOTÃO DE UPLOAD
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sua Vitrine",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Gerencie seus itens à venda",
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.accentNeon,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: const Text("NOVO ITEM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),

          // TABS (BEATS / LYRICS)
          TabBar(
            controller: _tabController,
            indicatorColor: controller.accentNeon,
            labelColor: controller.accentNeon,
            unselectedLabelColor: Colors.white38,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: "BEATS"),
              Tab(text: "LYRICS"),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItemsList("beats"),
                _buildItemsList("lyrics"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(String type) {
    // MOCK DE DADOS
    final items = type == "beats" 
      ? [
          {"title": "Dark Travis Type", "price": "R\$ 150,00", "sales": "12", "bpm": "140"},
          {"title": "Melodic Drill", "price": "R\$ 200,00", "sales": "5", "bpm": "144"},
        ]
      : [
          {"title": "Midnight Thoughts", "price": "R\$ 50,00", "sales": "3", "tag": "Trap"},
          {"title": "Street Vision", "price": "R\$ 80,00", "sales": "8", "tag": "Boombap"},
        ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              // THUMBNAIL PLACEHOLDER
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [controller.primaryPurple, Colors.black]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  type == "beats" ? Icons.audiotrack : Icons.description,
                  color: controller.accentNeon,
                ),
              ),
              const SizedBox(width: 16),
              // INFO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item["title"]!,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type == "beats" ? "${item["bpm"]} BPM" : "Gênero: ${item["tag"]}",
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // PREÇO E VENDAS
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item["price"]!,
                    style: TextStyle(color: controller.accentNeon, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${item["sales"]} vendas",
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.more_vert, color: Colors.white38, size: 18),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}