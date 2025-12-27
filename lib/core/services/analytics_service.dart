import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnalyticsData {
  final double totalRevenue;
  final double totalExpenses;
  final double totalSalaries;
  final double netProfit;
  final double averageCheck;
  final int totalOrders;
  final List<SalesPoint> salesGraphData;
  final List<TopProduct> topProducts;
  final Map<int, int> peakHours; // Hour -> Count
  final Map<String, double> categoriesShare; // Category -> Revenue

  AnalyticsData({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.totalSalaries,
    required this.netProfit,
    required this.averageCheck,
    required this.totalOrders,
    required this.salesGraphData,
    required this.topProducts,
    required this.peakHours,
    required this.categoriesShare,
  });
}

class SalesPoint {
  final DateTime date;
  final double amount;

  SalesPoint(this.date, this.amount);
}

class TopProduct {
  final String? id;
  final String name;
  final int count;
  final double revenue;

  TopProduct(this.id, this.name, this.count, this.revenue);
}

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AnalyticsData> getAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // 1. Fetch Orders (Completed within range)
    final ordersSnapshot = await _firestore
        .collection('orders')
        .where('status', isEqualTo: 'completed')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    // 2. Fetch Expenses (Within range)
    final expensesSnapshot = await _firestore
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    // 3. Fetch Salaries (Confirmed payments within range)
    // Note: Assuming 'confirmed' status exists. If not, we might check 'pending' too.
    // For safety, let's grab all and filter in memory if needed, or query specifically.
    // Let's assume we want 'confirmed' ones which definitely happened.
    final salariesSnapshot = await _firestore
        .collection('salary_payments')
        .where('status', isEqualTo: 'confirmed')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    // --- Process Orders ---
    double revenue = 0;
    int orderCount = ordersSnapshot.docs.length;

    // Determine if this is a single-day query
    final isSingleDay =
        startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day;

    Map<String, double> salesByDate = {};
    List<SalesPoint> individualOrders = []; // For single-day view
    Map<String, int> productCounts = {};
    Map<String, double> productRevenue = {};
    Map<int, int> hoursMap = {};
    Map<String, double> categoryMap = {};
    Map<String, String> productNameToId = {};

    for (var doc in ordersSnapshot.docs) {
      final data = doc.data();
      final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
      final timestamp = data['createdAt'] as Timestamp;
      final orderDate = timestamp.toDate();

      // Revenue
      revenue += amount;

      // Sales Graph - different logic for single day vs multi-day
      if (isSingleDay) {
        // For single day: add each order as individual point
        individualOrders.add(SalesPoint(orderDate, amount));
      } else {
        // For multi-day: aggregate by date
        final dateKeys = DateFormat('yyyy-MM-dd').format(orderDate);
        salesByDate[dateKeys] = (salesByDate[dateKeys] ?? 0) + amount;
      }

      // Peak Hours
      final hour = orderDate.hour;
      hoursMap[hour] = (hoursMap[hour] ?? 0) + 1;

      // Products & Categories
      final items = (data['items'] as List<dynamic>?);
      if (items != null) {
        for (var item in items) {
          final pName = item['name'] as String? ?? 'Unknown';
          final qty = (item['quantity'] as num?)?.toInt() ?? 1;
          final pPrice =
              (item['price'] as num?)?.toDouble() ??
              0.0; // Assuming price is stored in item
          final pRevenue = pPrice * qty;

          final pId = item['productId'] as String?;

          productCounts[pName] = (productCounts[pName] ?? 0) + qty;
          productRevenue[pName] = (productRevenue[pName] ?? 0) + pRevenue;
          // Store ID if available (naive approach: last seen ID for a name)
          // Ideally we group by ID, but for now name is the display key
          if (pId != null) {
            productNameToId[pName] = pId;
          }

          // Note: Category might not be in order item. If strictly needed, we'd need to fetch products.
          // For MVP, if category isn't in item, we might skip or approximate.
          // Let's assuming order item SHOULD store category or we can't do it easily without N+1 queries.
          // IF category is missing, we'll group by 'Unknown' or try to use product name map if we cached it.
          // Let's assume for now we don't have category in order items (common mistake).
          // We can try to look it up if we fetch all products once, but that's expensive.
          // Let's skip category for now if it's not simple, or just add a TODO.
        }
      }
    }

    // --- Process Expenses ---
    double expenses = 0;
    for (var doc in expensesSnapshot.docs) {
      final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
      expenses += amount;
    }

    // --- Process Salaries ---
    double salaries = 0;
    for (var doc in salariesSnapshot.docs) {
      final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
      salaries += amount;
    }

    // --- Final Calculations ---
    final netProfit = revenue - expenses - salaries;
    final avgCheck = orderCount > 0 ? revenue / orderCount : 0.0;

    // Sales Graph Data
    List<SalesPoint> graphData = [];
    if (isSingleDay) {
      // For single day: use individual orders sorted by time
      graphData = individualOrders;
      graphData.sort((a, b) => a.date.compareTo(b.date));
    } else {
      // For multi-day: use aggregated daily data
      salesByDate.forEach((key, value) {
        graphData.add(SalesPoint(DateFormat('yyyy-MM-dd').parse(key), value));
      });
      graphData.sort((a, b) => a.date.compareTo(b.date));
    }

    // Top Products
    List<TopProduct> topList = [];
    productCounts.forEach((key, value) {
      topList.add(
        TopProduct(productNameToId[key], key, value, productRevenue[key] ?? 0),
      );
    });
    // Sort by count desc
    topList.sort((a, b) => b.count.compareTo(a.count));
    // Take top 5
    if (topList.length > 5) topList = topList.sublist(0, 5);

    return AnalyticsData(
      totalRevenue: revenue,
      totalExpenses: expenses,
      totalSalaries: salaries,
      netProfit: netProfit,
      averageCheck: avgCheck,
      totalOrders: orderCount,
      salesGraphData: graphData,
      topProducts: topList,
      peakHours: hoursMap,
      categoriesShare: categoryMap, // Empty for now
    );
  }
}
