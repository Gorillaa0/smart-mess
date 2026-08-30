import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/h4_students_data.dart';

class ManagerAnalyticsScreen extends StatelessWidget {
  const ManagerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B5E20),
        elevation: 0.5,
        title: const Text('Mess Analytics & Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. KPI Metric Highlights
          Row(
            children: [
              _buildKpiCard('AI Accuracy', '98.2%', Icons.auto_awesome, const Color(0xFF1B5E20), const Color(0xFFE8F5E9)),
              const SizedBox(width: 8),
              _buildKpiCard('Avg Wastage', '2.8 kg', Icons.delete_outline, const Color(0xFFE65100), const Color(0xFFFFF3E0)),
              const SizedBox(width: 8),
              _buildKpiCard('Rebates Saved', '₹4,850', Icons.currency_rupee, const Color(0xFF1565C0), const Color(0xFFE3F2FD)),
            ],
          ),
          const SizedBox(height: 18),

          // 2. Attendance Predicted vs Actual Chart Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFA5D6A7), width: 1.2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Daily Attendance: Predicted vs Actual',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF1B5E20)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _legendDot('Pred', Colors.grey),
                        const SizedBox(width: 8),
                        _legendDot('Actual', const Color(0xFF1B5E20)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              if (val.toInt() >= 0 && val.toInt() < days.length) {
                                return Text(days[val.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey));
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        // Predicted Line
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 106),
                            FlSpot(1, 108),
                            FlSpot(2, 105),
                            FlSpot(3, 109),
                            FlSpot(4, 98),
                            FlSpot(5, 78),
                            FlSpot(6, 85),
                          ],
                          isCurved: true,
                          color: Colors.grey.shade400,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                        ),
                        // Actual Line
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 104),
                            FlSpot(1, 107),
                            FlSpot(2, 106),
                            FlSpot(3, 108),
                            FlSpot(4, 95),
                            FlSpot(5, 76),
                            FlSpot(6, 82),
                          ],
                          isCurved: true,
                          color: const Color(0xFF1B5E20),
                          barWidth: 3.5,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 3. Daily Food Wastage Trends Bar Chart Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFCDD2), width: 1.2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Wastage Trends (kg)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFFC62828))),
                const SizedBox(height: 20),
                SizedBox(
                  height: 160,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 10,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              if (val.toInt() >= 0 && val.toInt() < days.length) {
                                return Text(days[val.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey));
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        _makeBarGroup(0, 3.2),
                        _makeBarGroup(1, 2.5),
                        _makeBarGroup(2, 4.0),
                        _makeBarGroup(3, 1.8),
                        _makeBarGroup(4, 2.9),
                        _makeBarGroup(5, 1.2),
                        _makeBarGroup(6, 2.1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: const Color(0xFFE53935),
          width: 14,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(String text, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
