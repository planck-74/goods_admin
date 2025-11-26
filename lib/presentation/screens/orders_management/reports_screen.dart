import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:goods_admin/business%20logic/cubits/reports_cubit/reports_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/reports_cubit/reports_state.dart';
import 'package:goods_admin/presentation/cards/summary_card.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        context,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'التقارير والإحصائيات',
              style: TextStyle(color: Colors.white),
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _showExportDialog(context),
            ),
          ],
        ),
      ),
      body: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          if (state is ReportsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ReportsError) {
            return Center(child: Text('خطأ: ${state.message}'));
          }

          if (state is ReportsLoaded) {
            return _buildReportsContent(context, state.data);
          }

          return const Center(child: Text('اضغط على التقارير لتحميل البيانات'));
        },
      ),
    );
  }

  Widget _buildReportsContent(BuildContext context, ReportsData data) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCards(context, data),
        const SizedBox(height: 24),
        _buildDailySalesChart(context, data),
        const SizedBox(height: 24),
        _buildRevenueBySupplier(context, data),
        const SizedBox(height: 24),
        _buildRevenueByClassification(context, data),
      ],
    );
  }

  Widget _buildSummaryCards(BuildContext context, ReportsData data) {
    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            title: 'إجمالي الطلبات',
            value: '${data.totalOrders}',
            icon: Icons.shopping_cart,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SummaryCard(
            title: 'الطلبات المكتملة',
            value: '${data.completedOrders}',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildDailySalesChart(BuildContext context, ReportsData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المبيعات اليومية (آخر 7 أيام)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${data.totalRevenue.toStringAsFixed(2)} ج.م',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: data.revenueByDate.values.isEmpty
                      ? 1000
                      : data.revenueByDate.values
                              .reduce((a, b) => a > b ? a : b) *
                          1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final date =
                            data.revenueByDate.keys.toList()[group.x.toInt()];
                        return BarTooltipItem(
                          '$date\n${rod.toY.toStringAsFixed(2)} ج.م',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < data.revenueByDate.length) {
                            return Text(
                              data.revenueByDate.keys.toList()[value.toInt()],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: data.revenueByDate.entries
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value,
                          color: Theme.of(context).colorScheme.primary,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueBySupplier(BuildContext context, ReportsData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الإيرادات حسب المورد',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...data.revenueBySupplier.entries.take(5).map((entry) {
              final percentage = (entry.value / data.totalRevenue * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key.substring(0, 8),
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          '${entry.value.toStringAsFixed(2)} ج.م (${percentage.toStringAsFixed(1)}%)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueByClassification(BuildContext context, ReportsData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الإيرادات حسب التصنيف',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...data.revenueByClassification.entries.map((entry) {
              final percentage = (entry.value / data.totalRevenue * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(entry.key)),
                    Text(
                      '${entry.value.toStringAsFixed(2)} ج.م (${percentage.toStringAsFixed(1)}%)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تصدير التقرير'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('تصدير كـ CSV'),
              onTap: () {
                Navigator.pop(dialogContext);
                _exportToCSV(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToCSV(BuildContext context) async {
    final state = context.read<ReportsCubit>().state;
    if (state is! ReportsLoaded) return;

    final data = state.data;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    List<List<dynamic>> rows = [
      [
        'رقم الطلب',
        'العميل',
        'المورد',
        'التاريخ',
        'الحالة',
        'المجموع',
        'المجموع بعد العرض',
        'عدد المنتجات'
      ]
    ];

    for (var order in data.allOrders) {
      rows.add([
        order.orderCode,
        order.clientId,
        order.supplierId,
        dateFormat.format(order.date),
        order.state,
        order.total.toStringAsFixed(2),
        order.totalWithOffer.toStringAsFixed(2),
        order.itemCount,
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    try {
      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/orders_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(path)],
        subject: 'تقرير الطلبات',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تصدير التقرير بنجاح')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التصدير: $e')),
        );
      }
    }
  }
}
