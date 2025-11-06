import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/orders_cubit/orders_cubit.dart';
import 'package:goods_admin/data/models/order_model.dart';
import 'package:goods_admin/presentation/cards/product_card.dart';
import 'package:intl/intl.dart';

class OrderDetailsSheet extends StatefulWidget {
  final Order order;

  const OrderDetailsSheet({super.key, required this.order});

  @override
  State<OrderDetailsSheet> createState() => _OrderDetailsSheetState();
}

class _OrderDetailsSheetState extends State<OrderDetailsSheet> {
  late String _selectedState;

  @override
  void initState() {
    super.initState();
    _selectedState = widget.order.state;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تفاصيل الطلب #${widget.order.orderCode}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('معرف العميل', widget.order.clientId),
                            _buildInfoRow(
                                'معرف المورد', widget.order.supplierId),
                            _buildInfoRow('التاريخ',
                                dateFormat.format(widget.order.date)),
                            if (widget.order.doneAt != null)
                              _buildInfoRow('تم التوصيل',
                                  dateFormat.format(widget.order.doneAt!)),
                            _buildInfoRow(
                                'عدد المنتجات', '${widget.order.itemCount}'),
                            _buildInfoRow('المجموع',
                                '${widget.order.total.toStringAsFixed(2)} ج.م'),
                            _buildInfoRow('المجموع بعد العرض',
                                '${widget.order.totalWithOffer.toStringAsFixed(2)} ج.م'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تحديث حالة الطلب',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedState,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'الحالة',
                              ),
                              items: [
                                'قيد التجهيز',
                                'في الطريق',
                                'تم التوصيل',
                                'ملغي'
                              ]
                                  .map((state) => DropdownMenuItem(
                                        value: state,
                                        child: Text(state),
                                      ))
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedState = value!),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _selectedState != widget.order.state
                                    ? () async {
                                        await context
                                            .read<OrdersCubit>()
                                            .updateOrderState(
                                              widget.order.id,
                                              _selectedState,
                                            );
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'تم تحديث حالة الطلب')),
                                          );
                                        }
                                      }
                                    : null,
                                child: const Text('تحديث الحالة'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'المنتجات',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...widget.order.products.map((orderProduct) => ProductCard(
                          orderProduct: orderProduct,
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
