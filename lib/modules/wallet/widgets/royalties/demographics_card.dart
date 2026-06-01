import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:versin/app/locator.dart';
import '../../controllers/royalties_controller.dart';

class DemographicsCard extends StatelessWidget {
  const DemographicsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = sl<RoyaltiesController>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: controller.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Age Range", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: controller.isLoading 
              ? Center(child: CircularProgressIndicator(color: controller.primaryPurple))
              : (controller.ageGroup1 == 0 && controller.ageGroup2 == 0) // Verifica se está vazio
                  ? const Center(child: Text("Sem dados", style: TextStyle(color: Colors.white24)))
                  : PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            value: controller.ageGroup1,
                            color: controller.primaryPurple,
                            title: '${controller.ageGroup1.toInt()}%',
                            radius: 20,
                            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          PieChartSectionData(
                            value: controller.ageGroup2,
                            color: Colors.amber,
                            title: '${controller.ageGroup2.toInt()}%',
                            radius: 20,
                            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          PieChartSectionData(
                            value: controller.ageGroup3,
                            color: Colors.cyan,
                            title: '${controller.ageGroup3.toInt()}%',
                            radius: 20,
                            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}