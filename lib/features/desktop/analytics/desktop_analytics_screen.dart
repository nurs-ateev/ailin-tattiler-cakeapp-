import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ailin_tattileri_app/core/models/order_model.dart';
import 'package:ailin_tattileri_app/core/utils/currency_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DesktopAnalyticsScreen extends StatelessWidget {
  const DesktopAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Отчеты и аналитика')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Нет данных'));
          }

          final orders = snapshot.data!.docs
              .map(
                (doc) => OrderModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

          // Calculate statistics
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);
          final weekStart = todayStart.subtract(
            Duration(days: now.weekday - 1),
          );
          final monthStart = DateTime(now.year, now.month, 1);

          final todayOrders = orders
              .where((o) => o.createdAt.isAfter(todayStart))
              .toList();
          final weekOrders = orders
              .where((o) => o.createdAt.isAfter(weekStart))
              .toList();
          final monthOrders = orders
              .where((o) => o.createdAt.isAfter(monthStart))
              .toList();

          final todayRevenue = todayOrders
              .where((o) => o.status == 'completed')
              .fold<double>(0, (sum, o) => sum + o.totalAmount);
          final weekRevenue = weekOrders
              .where((o) => o.status == 'completed')
              .fold<double>(0, (sum, o) => sum + o.totalAmount);
          final monthRevenue = monthOrders
              .where((o) => o.status == 'completed')
              .fold<double>(0, (sum, o) => sum + o.totalAmount);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Revenue Cards
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Сегодня',
                        value: '${CurrencyFormatter.format(todayRevenue)} ₸',
                        subtitle: '${todayOrders.length} заказов',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'За неделю',
                        value: '${CurrencyFormatter.format(weekRevenue)} ₸',
                        subtitle: '${weekOrders.length} заказов',
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'За месяц',
                        value: '${CurrencyFormatter.format(monthRevenue)} ₸',
                        subtitle: '${monthOrders.length} заказов',
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Chart
                const Text(
                  'Продажи за последние 7 дней',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(height: 300, child: _buildChart(orders)),
                  ),
                ),

                const SizedBox(height: 32),

                // Top Products
                const Text(
                  'Популярные товары',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildTopProducts(orders),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChart(List<OrderModel> orders) {
    final now = DateTime.now();
    final last7Days = List.generate(7, (index) {
      return DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - index));
    });

    final data = last7Days.map((day) {
      final dayOrders = orders.where((o) {
        return o.createdAt.year == day.year &&
            o.createdAt.month == day.month &&
            o.createdAt.day == day.day &&
            o.status == 'completed';
      });
      final revenue = dayOrders.fold<double>(
        0,
        (sum, o) => sum + o.totalAmount,
      );
      return revenue;
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < last7Days.length) {
                  return Text(
                    DateFormat('dd/MM').format(last7Days[value.toInt()]),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 60),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value);
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(List<OrderModel> orders) {
    final productCounts = <String, int>{};

    for (final order in orders) {
      for (final item in order.items) {
        final name = item['name'] as String;
        productCounts[name] =
            (productCounts[name] ?? 0) + (item['quantity'] as int);
      }
    }

    final sortedProducts = productCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedProducts.take(10).map((entry) {
        return ListTile(
          title: Text(entry.key),
          trailing: Text(
            '${entry.value} шт',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
