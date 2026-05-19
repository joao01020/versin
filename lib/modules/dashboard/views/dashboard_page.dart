import 'dart:ui';
import 'package:flutter/material.dart';

// CONTROLLER & WIDGETS IMPORTS
import '../controllers/dashboard_controller.dart';
import '../widgets/side_rail_widget.dart';
import '../widgets/dashboard_header_widget.dart';
import '../widgets/account_activities_card_widget.dart';
import '../widgets/hub_status_card_widget.dart';
import '../widgets/main_chart_card_widget.dart';
import '../widgets/calendar_card_widget.dart'; // <-- Novo Widget Importado!

// ECOSYSTEM MODULES IMPORTS
import 'package:versin/features/rhymes/presentation/pages/chat_page.dart';
import 'package:versin/modules/hub/hub_page.dart';
import 'package:versin/modules/match/match_page.dart';
import 'package:versin/modules/wallet/wallet_page.dart';
import 'package:versin/modules/market/market_page.dart'; 
import 'package:versin/modules/showcase/showcase_page.dart';
import 'package:versin/modules/vnode/vnode_page.dart'; 
import 'package:versin/modules/settings/settings_page.dart'; 

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardController _controller = DashboardController();

  @override
  void initState() {
    super.initState();
    _controller.init(); 
  }

  @override
  void dispose() {
    _controller.disposeController(); 
    super.dispose();
  }

  void _showAddAppointmentSheet({String? fixedTime}) {
    final TextEditingController titleController = TextEditingController();
    final now = DateTime.now();
    final String defaultTime = fixedTime ?? "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final TextEditingController timeController = TextEditingController(text: defaultTime);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: const Color(0xFF15122C), 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)), 
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24, 
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "NOVO COMPROMISSO - DIA ${_controller.selectedDay}/${_controller.focusedDay.month}",
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.pop(context), 
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  hintText: "Descrição do compromisso (ex: Gravar Vocais)",
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  hintText: "Horário (HH:MM)",
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                  prefixIcon: const Icon(Icons.access_time, color: Colors.white38, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _controller.accentNeon,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (titleController.text.isNotEmpty && timeController.text.isNotEmpty) {
                      setState(() {
                        _controller.addAppointment(
                          title: titleController.text,
                          time: timeController.text,
                        );
                      });
                      Navigator.pop(context); 
                    }
                  },
                  child: const Text("AGENDAR NO CHASSI", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth < 800;

      return Scaffold(
        backgroundColor: Colors.black, 
        bottomNavigationBar: isMobile 
          ? Theme(
              data: Theme.of(context).copyWith(canvasColor: Colors.black), 
              child: BottomNavigationBar(
                currentIndex: _controller.currentIndex,
                onTap: (index) {
                  setState(() => _controller.navigationTap(index));
                }, 
                selectedItemColor: _controller.accentNeon,
                unselectedItemColor: Colors.white24,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                type: BottomNavigationBarType.fixed, 
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: "Dash"),
                  BottomNavigationBarItem(icon: Icon(Icons.share_outlined), label: "Match"),
                  BottomNavigationBarItem(icon: Icon(Icons.local_mall_outlined), label: "Market"), 
                  BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: "Wallet"),
                  BottomNavigationBarItem(icon: Icon(Icons.mic_external_on_outlined), label: "Studio"),
                  BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: "Showcase"),
                  BottomNavigationBarItem(icon: Icon(Icons.settings_input_component), label: "Hub"), 
                  BottomNavigationBarItem(icon: Icon(Icons.lan_outlined), label: "VNode"), 
                  BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "Settings"), 
                ],
              ),
            ) 
          : null, 
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF2E1A47), _controller.deepBg, Colors.black], 
            ),
          ),
          child: Row(
            children: [
              if (!isMobile) SideRailWidget(controller: _controller),
              Expanded(
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DashboardHeaderWidget(controller: _controller), 
                      Expanded(
                        child: PageView(
                          controller: _controller.pageController,
                          onPageChanged: (index) {
                            setState(() => _controller.handlePageChange(index));
                          }, 
                          children: [
                            _buildLabModule(isMobile), 
                            const MatchPage(),         
                            const MarketPage(),        
                            const WalletPage(),        
                            const ChatPage(),          
                            const ShowcasePage(),      
                            const HubPage(),           
                            const VNodePage(),         
                            const SettingsPage(),      
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLabModule(bool isMobile) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(), 
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          isMobile 
          ? Column(
              children: [
                AccountActivitiesCardWidget(controller: _controller, onStateChanged: () => setState(() {})),
                const SizedBox(height: 16),
                HubStatusCardWidget(controller: _controller),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: AccountActivitiesCardWidget(controller: _controller, onStateChanged: () => setState(() {}))),
                const SizedBox(width: 16),
                Expanded(child: HubStatusCardWidget(controller: _controller)),
              ],
            ),
          const SizedBox(height: 20),
          MainChartCardWidget(controller: _controller), 
          const SizedBox(height: 20),
          // CALLING INTERACTIVE CALENDAR / CHAMANDO O CALENDÁRIO INTERATIVO ISOLADO
          CalendarCardWidget(
            controller: _controller,
            onStateChanged: () => setState(() {}),
            onAddAppointmentTap: () => _showAddAppointmentSheet(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}