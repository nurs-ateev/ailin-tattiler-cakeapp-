import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:ailin_tattileri_app/core/services/analytics_service.dart';
import 'package:ailin_tattileri_app/core/utils/currency_formatter.dart';
import 'package:go_router/go_router.dart';
import 'package:ailin_tattileri_app/core/models/product_model.dart';
import 'package:ailin_tattileri_app/l10n/app_localizations.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _service = AnalyticsService();

  // Default range: This Month
  late DateTime _startDate;
  late DateTime _endDate;
  String _rangeLabel = "";

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _rangeLabel = "Сегодня";
  }

  void _setDateRange(String label) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (label == AppLocalizations.of(context)!.today) {
      start = DateTime(now.year, now.month, now.day);
    } else if (label == AppLocalizations.of(context)!.thisWeek) {
      start = now.subtract(Duration(days: now.weekday - 1));
      start = DateTime(start.year, start.month, start.day);
    } else if (label == AppLocalizations.of(context)!.thisMonth) {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else {
      // Default
      start = DateTime(now.year, now.month, 1);
    }

    setState(() {
      _rangeLabel = label;
      _startDate = start;
      _endDate = end;
    });
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ), // Allow future? No, just analytics up to now mostly.
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _rangeLabel =
            "${DateFormat('dd.MM').format(picked.start)} - ${DateFormat('dd.MM').format(picked.end)}";
        _startDate = picked.start;
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.analyticsTitle,
          style: theme.textTheme.titleLarge,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: theme.iconTheme,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.calendar_today, color: AppColors.primary),
              onPressed: () => _pickDateRange(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar with premium styling
          Container(
            height: 60,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              children: [
                _buildFilterChip(AppLocalizations.of(context)!.today),
                const SizedBox(width: 8),
                _buildFilterChip(AppLocalizations.of(context)!.thisWeek),
                const SizedBox(width: 8),
                _buildFilterChip(AppLocalizations.of(context)!.thisMonth),
                const SizedBox(width: 8),
                _buildFilterChip(
                  AppLocalizations.of(context)!.pickPeriod,
                  isPicker: true,
                ),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<AnalyticsData>(
              future: _service.getAnalytics(
                startDate: _startDate,
                endDate: _endDate,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SelectableText(
                        "Ошибка: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                final data = snapshot.data!;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary Section Header
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 16),
                      child: Text(
                        "${AppLocalizations.of(context)!.finance}: $_rangeLabel",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    // Summary Cards Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildGradientSummaryCard(
                            label: AppLocalizations.of(context)!.revenue,
                            value: data.totalRevenue,
                            icon: Icons.trending_up,
                            colors: [
                              const Color(0xFF11998e),
                              const Color(0xFF38ef7d),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildGradientSummaryCard(
                            label: AppLocalizations.of(context)!.netProfit,
                            value: data.netProfit,
                            icon: Icons.account_balance_wallet,
                            colors: data.netProfit >= 0
                                ? [
                                    const Color(0xFF56CCF2),
                                    const Color(0xFF2F80ED),
                                  ]
                                : [
                                    const Color(0xFFFF416C),
                                    const Color(0xFFFF4B2B),
                                  ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPremiumSummaryCardLink(
                            label: AppLocalizations.of(
                              context,
                            )!.totalExpensesLabel,
                            value: data.totalExpenses,
                            icon: Icons.money_off,
                            colors: const [
                              Color(0xFFEF4444),
                              Color(0xFFF87171),
                            ],
                            onTap: () => context.push('/admin/expenses'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPremiumSummaryCardLink(
                            label: AppLocalizations.of(
                              context,
                            )!.totalSalariesLabel,
                            value: data.totalSalaries,
                            icon: Icons.payments,
                            colors: const [
                              Color(0xFF8B5CF6),
                              Color(0xFFA78BFA),
                            ],
                            onTap: () => context.push('/admin/payments'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Avg Check Card (Bank Card Style)
                    _buildBankCardStat(
                      title: AppLocalizations.of(context)!.averageCheck,
                      value: data.averageCheck,
                      orderCount: data.totalOrders,
                    ),

                    const SizedBox(height: 32),

                    // Chart Section
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.show_chart,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.revenueDynamics,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 280,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: data.salesGraphData.isEmpty
                          ? Center(
                              child: Text(
                                AppLocalizations.of(context)!.noDataForPeriod,
                                style: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            )
                          : LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  drawHorizontalLine: true,
                                  horizontalInterval: _calculateInterval(
                                    data.salesGraphData,
                                  ),
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey[200],
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipColor: (_) => Colors.blueGrey,
                                    getTooltipItems: (touchedSpots) {
                                      return touchedSpots.map((spot) {
                                        final date =
                                            DateTime.fromMillisecondsSinceEpoch(
                                              spot.x.toInt(),
                                            );
                                        // Smart formatting: if single day, show time
                                        final isSingleDay =
                                            _rangeLabel ==
                                            AppLocalizations.of(context)!.today;
                                        final formattedDate = isSingleDay
                                            ? DateFormat(
                                                'dd MMM HH:mm',
                                              ).format(date)
                                            : DateFormat('dd MMM').format(date);
                                        return LineTooltipItem(
                                          '$formattedDate\n',
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          children: [
                                            TextSpan(
                                              text:
                                                  '${CurrencyFormatter.format(spot.y)} ₸',
                                              style: TextStyle(
                                                color: Colors.yellow[200],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final date =
                                            DateTime.fromMillisecondsSinceEpoch(
                                              value.toInt(),
                                            );
                                        // Smart formatting: if single day, show time
                                        final isSingleDay =
                                            _rangeLabel ==
                                            AppLocalizations.of(context)!.today;
                                        final label = isSingleDay
                                            ? DateFormat('HH:mm').format(date)
                                            : DateFormat('dd.MM').format(date);
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8.0,
                                          ),
                                          child: Text(
                                            label,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        );
                                      },
                                      reservedSize: 30,
                                      interval: _calculateDateInterval(
                                        data.salesGraphData,
                                      ),
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 45,
                                      getTitlesWidget: (value, meta) {
                                        if (value == 0) {
                                          return const SizedBox.shrink();
                                        }
                                        return Text(
                                          _compactCurrency(value),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 10,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: data.salesGraphData.map((e) {
                                      return FlSpot(
                                        e.date.millisecondsSinceEpoch
                                            .toDouble(),
                                        e.amount,
                                      );
                                    }).toList(),
                                    isCurved: true,
                                    gradient: LinearGradient(
                                      colors: _getGradientColors(
                                        data.salesGraphData,
                                      ),
                                    ),
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(
                                      show:
                                          _rangeLabel ==
                                          AppLocalizations.of(context)!.today,
                                      getDotPainter:
                                          (spot, percent, barData, index) {
                                            return FlDotCirclePainter(
                                              radius: 4,
                                              color: _getColorForValue(
                                                spot.y,
                                                data.salesGraphData,
                                              ),
                                              strokeWidth: 2,
                                              strokeColor: Colors.white,
                                            );
                                          },
                                    ),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        colors:
                                            _getGradientColors(
                                                  data.salesGraphData,
                                                )
                                                .map((c) => c.withOpacity(0.2))
                                                .toList(),
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Top Products Section
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.topProducts,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: data.topProducts.isEmpty
                            ? [
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    "Нет продаж",
                                    style: TextStyle(color: Color(0xFF9CA3AF)),
                                  ),
                                ),
                              ]
                            : data.topProducts
                                  .asMap() // Add index for ranking
                                  .entries
                                  .map((entry) {
                                    final index = entry.key;
                                    final p = entry.value;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme.cardTheme.color,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.04,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        onTap: () async {
                                          if (p.id != null) {
                                            // Show loading
                                            showDialog(
                                              context: context,
                                              builder: (_) => const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            );

                                            try {
                                              final doc =
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('products')
                                                      .doc(p.id)
                                                      .get();
                                              Navigator.pop(
                                                context,
                                              ); // Hide loading

                                              if (doc.exists) {
                                                final product = Product.fromMap(
                                                  doc.data()!,
                                                  doc.id,
                                                );
                                                context.push(
                                                  '/product/details',
                                                  extra: product,
                                                );
                                              } else {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Товар не найден (возможно удален)',
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text('Ошибка: $e'),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        leading: _buildRankBadge(index + 1),
                                        title: Text(
                                          p.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: theme
                                                .textTheme
                                                .bodyLarge
                                                ?.color,
                                            fontSize: 15,
                                          ),
                                        ),
                                        trailing: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "${p.count} шт.",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: theme.primaryColor,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              "${CurrencyFormatter.format(p.revenue)} ₸",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: theme
                                                    .textTheme
                                                    .bodySmall
                                                    ?.color,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {bool isPicker = false}) {
    final theme = Theme.of(context);
    final isSelected = _rangeLabel == label;
    return GestureDetector(
      onTap: isPicker
          ? () => _pickDateRange(context)
          : () => _setDateRange(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                )
              : null,
          color: isSelected ? null : theme.cardTheme.color?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.5)
                : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientSummaryCard({
    required String label,
    required double value,
    required IconData icon,
    required List<Color> colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${CurrencyFormatter.format(value)} ₸",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color bgColor;
    Color textColor;

    switch (rank) {
      case 1:
        bgColor = const Color(0xFFFFD700); // Gold
        textColor = Colors.black;
        break;
      case 2:
        bgColor = const Color(0xFFC0C0C0); // Silver
        textColor = Colors.black;
        break;
      case 3:
        bgColor = const Color(0xFFCD7F32); // Bronze
        textColor = Colors.white;
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
    }

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: rank <= 3
            ? [
                BoxShadow(
                  color: bgColor.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Text(
        "#$rank",
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildPremiumSummaryCardLink({
    required String label,
    required double value,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${CurrencyFormatter.format(value)} ₸",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankCardStat({
    required String title,
    required double value,
    required int orderCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)], // Dark Slate/Black
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            right: -40,
            bottom: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Chip icon and Contactless icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.nfc, // Contactless symbol
                    color: Colors.white.withOpacity(0.7),
                    size: 28,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      "PREMIUM",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Value (like card number)
              Text(
                "${CurrencyFormatter.format(value)} ₸",
                style: const TextStyle(
                  fontFamily: 'Monospace', // Or user preferred font
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Footer: Title and Subtext (like Card Holder and Expiry)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "AILIN TATTILERI", // Card Holder Name Placeholder
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "ORDERS",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        orderCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateInterval(List<SalesPoint> data) {
    if (data.isEmpty) return 1000;
    double maxVal = data.fold(
      0,
      (prev, e) => e.amount > prev ? e.amount : prev,
    );
    if (maxVal == 0) return 1000;

    // Detailed interval logic: aimed for ~4-5 horizontal lines
    // Round up to nice number
    return maxVal / 4;
  }

  double _calculateDateInterval(List<SalesPoint> data) {
    if (data.isEmpty) return 86400000; // 1 day
    final duration = data.last.date.difference(data.first.date);

    // Attempt to show ~5 labels
    final interval = duration.inMilliseconds / 5;

    // If interval is less than a day, force 12 hours or something reasomable
    if (interval < 43200000) return 43200000;

    return interval;
  }

  String _compactCurrency(double value) {
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}M";
    }
    if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(0)}K";
    }
    return value.toStringAsFixed(0);
  }

  List<Color> _getGradientColors(List<SalesPoint> data) {
    if (data.isEmpty) return [Colors.grey, Colors.grey];

    // Create gradient from red (low) to green (high)
    return [
      Colors.red.shade400,
      Colors.orange.shade400,
      Colors.yellow.shade600,
      Colors.lightGreen.shade400,
      Colors.green.shade500,
    ];
  }

  Color _getColorForValue(double value, List<SalesPoint> data) {
    if (data.isEmpty) return Colors.grey;

    final maxVal = data.fold<double>(
      0,
      (prev, e) => e.amount > prev ? e.amount : prev,
    );
    final minVal = data.fold<double>(
      double.infinity,
      (prev, e) => e.amount < prev ? e.amount : prev,
    );

    if (maxVal == minVal) return Colors.green;

    // Calculate percentage (0.0 to 1.0)
    final percentage = (value - minVal) / (maxVal - minVal);

    // Map to color: red (0%) to green (100%)
    if (percentage < 0.25) return Colors.red.shade400;
    if (percentage < 0.5) return Colors.orange.shade400;
    if (percentage < 0.75) return Colors.yellow.shade600;
    return Colors.green.shade500;
  }
}
