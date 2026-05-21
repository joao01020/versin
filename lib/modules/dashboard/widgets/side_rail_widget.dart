import 'package:flutter/material.dart';
import '../controllers/dashboard_controller.dart';

/// [SideRailWidget] renders the vertical navigation bar for tablet/desktop layouts.
/// [SideRailWidget] renderiza a barra de navegação vertical para layouts de tablet/desktop.
class SideRailWidget extends StatelessWidget {
  final DashboardController controller;

  const SideRailWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      color: Colors.black.withOpacity(0.4),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildRailItem(Icons.dashboard_outlined, 0),
            _buildRailItem(Icons.share_outlined, 1),
            _buildRailItem(Icons.local_mall_outlined, 2), 
            _buildRailItem(Icons.account_balance_wallet_outlined, 3),
            _buildRailItem(Icons.mic_external_on_outlined, 4),
            _buildRailItem(Icons.storefront_outlined, 5),
            _buildRailItem(Icons.settings_input_component, 6), 
            _buildRailItem(Icons.lan_outlined, 7), 
            _buildRailItem(Icons.settings_outlined, 8), 
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRailItem(IconData icon, int index) {
    bool isSelected = controller.currentIndex == index;
    return GestureDetector(
      onTap: () => controller.navigationTap(index),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: isSelected ? Border(left: BorderSide(color: controller.accentNeon, width: 3)) : null,
        ),
        child: Icon(icon, color: isSelected ? controller.accentNeon : Colors.white24, size: 28),
      ),
    );
  }
}