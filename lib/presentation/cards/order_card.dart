import 'package:flutter/material.dart';
import 'package:goods_admin/data/models/order_model.dart';
import 'package:goods_admin/presentation/sheets/order_details_sheet.dart';
import 'package:intl/intl.dart';

class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showOrderDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'طلب #${order.orderCode}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  _buildStateChip(context),
                ],
              ),
              const SizedBox(height: 8),
              Text('العميل: ${order.clientId.substring(0, 8)}...'),
              Text('التاريخ: ${dateFormat.format(order.date)}'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المجموع: ${order.totalWithOffer.toStringAsFixed(2)} ج.م',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text('${order.itemCount} منتج'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateChip(BuildContext context) {
    Color color;
    switch (order.state) {
      case 'تم التوصيل':
        color = Colors.green;
        break;
      case 'في الطريق':
        color = Colors.orange;
        break;
      case 'قيد التجهيز':
        color = Colors.blue;
        break;
      case 'ملغي':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        order.state,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  void _showOrderDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => OrderDetailsSheet(order: order),
    );
  }
}
