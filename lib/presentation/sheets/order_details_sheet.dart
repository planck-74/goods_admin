import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/orders_cubit/orders_cubit.dart';
import 'package:goods_admin/data/models/order_model.dart';
import 'package:goods_admin/presentation/cards/product_card.dart';
import 'package:intl/intl.dart';

class OrderDetailsSheet extends StatefulWidget {
  final Order order;
  final Map<String, dynamic>? clientData;
  final Map<String, dynamic>? supplierData;

  const OrderDetailsSheet({
    super.key,
    required this.order,
    this.clientData,
    this.supplierData,
  });

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
    final dateFormat = DateFormat('dd/MM/yyyy - HH:mm');
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'طلب #${widget.order.orderCode}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            dateFormat.format(widget.order.date),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
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
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Client Information Card
                    _buildUserInfoCard(
                      context,
                      title: 'معلومات العميل',
                      icon: Icons.person,
                      iconColor: Colors.blue,
                      userData: widget.clientData,
                      userId: widget.order.clientId,
                    ),

                    const SizedBox(height: 12),

                    // Supplier Information Card
                    _buildUserInfoCard(
                      context,
                      title: 'معلومات المورد',
                      icon: Icons.store,
                      iconColor: Colors.orange,
                      userData: widget.supplierData,
                      userId: widget.order.supplierId,
                    ),

                    const SizedBox(height: 12),

                    // Order Summary Card
                    _buildOrderSummaryCard(context),

                    const SizedBox(height: 12),

                    // Order Status Update Card
                    _buildStatusUpdateCard(context),

                    const SizedBox(height: 16),

                    // Products Section Header
                    Text(
                      'المنتجات (${widget.order.products.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Products List
                    ...widget.order.products.map(
                      (orderProduct) => ProductCard(orderProduct: orderProduct),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required Map<String, dynamic>? userData,
    required String userId,
  }) {
    final theme = Theme.of(context);
    final name = userData?['name'] ?? 'غير متوفر';
    final phone = userData?['phone'] ?? '';
    final email = userData?['email'] ?? '';
    final address = userData?['address'] ?? '';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.badge_outlined,
              label: 'الاسم',
              value: name,
            ),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                icon: Icons.phone_outlined,
                label: 'الهاتف',
                value: phone,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: phone));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم نسخ رقم الهاتف'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
            if (email.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                icon: Icons.email_outlined,
                label: 'البريد',
                value: email,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: email));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم نسخ البريد الإلكتروني'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
            if (address.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                icon: Icons.location_on_outlined,
                label: 'العنوان',
                value: address,
              ),
            ],
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.tag_outlined,
              label: 'المعرف',
              value: userId.substring(0, 12) + '...',
              valueStyle: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey[600],
              ),
              onTap: () {
                Clipboard.setData(ClipboardData(text: userId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ المعرف'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy - HH:mm');
    final hasDiscount = widget.order.total != widget.order.totalWithOffer;
    final discount = widget.order.total - widget.order.totalWithOffer;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shopping_cart,
                      color: Colors.purple, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'ملخص الطلب',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildSummaryRow('عدد المنتجات', '${widget.order.itemCount} منتج'),
            const SizedBox(height: 12),
            _buildSummaryRow(
                'إجمالي الطلب', '${widget.order.total.toStringAsFixed(2)} ج.م'),
            if (hasDiscount) ...[
              const SizedBox(height: 12),
              _buildSummaryRow(
                'الخصم',
                '- ${discount.toStringAsFixed(2)} ج.م',
                valueColor: Colors.green,
              ),
            ],
            const Divider(height: 24),
            _buildSummaryRow(
              'المجموع النهائي',
              '${widget.order.totalWithOffer.toStringAsFixed(2)} ج.م',
              isTotal: true,
            ),
            if (widget.order.doneAt != null) ...[
              const SizedBox(height: 12),
              _buildSummaryRow(
                'تم التوصيل في',
                dateFormat.format(widget.order.doneAt!),
              ),
            ],
            if (widget.order.note != null && widget.order.note!.isNotEmpty) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                icon: Icons.note_outlined,
                label: 'ملاحظة',
                value: widget.order.note!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusUpdateCard(BuildContext context) {
    final theme = Theme.of(context);
    final canUpdate = _selectedState != widget.order.state;

    return Card(
      elevation: 0,
      color: theme.colorScheme.primary.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.update, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'تحديث حالة الطلب',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedState,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                labelText: 'الحالة',
                prefixIcon: const Icon(Icons.circle),
              ),
              items: ['قيد التجهيز', 'في الطريق', 'تم التوصيل', 'ملغي']
                  .map((state) => DropdownMenuItem(
                        value: state,
                        child: Text(state),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedState = value!),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: canUpdate
                    ? () async {
                        await context.read<OrdersCubit>().updateOrderState(
                              widget.order.orderCode.toString(),
                              _selectedState,
                            );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم تحديث حالة الطلب بنجاح'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    : null,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('تحديث الحالة'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    TextStyle? valueStyle,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: Text(
                '$label:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: valueStyle ?? theme.textTheme.bodyMedium,
              ),
            ),
            if (onTap != null)
              Icon(Icons.copy, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            fontSize: isTotal ? 18 : 14,
            color: valueColor ?? (isTotal ? theme.colorScheme.primary : null),
          ),
        ),
      ],
    );
  }
}
