import 'package:flutter/material.dart';
import 'package:goods_admin/data/models/order_model.dart';
import 'package:goods_admin/presentation/sheets/order_details_sheet.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

class OrderCard extends StatefulWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  Map<String, dynamic>? _clientData;
  Map<String, dynamic>? _supplierData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Load client details
      final clientDoc =
          await firestore.collection('users').doc(widget.order.clientId).get();

      // Load supplier details
      final supplierDoc = await firestore
          .collection('users')
          .doc(widget.order.supplierId)
          .get();

      if (mounted) {
        setState(() {
          _clientData = clientDoc.exists ? clientDoc.data() : null;
          _supplierData = supplierDoc.exists ? supplierDoc.data() : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy - HH:mm');
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showOrderDetails(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with order code and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.receipt_long,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'طلب #${widget.order.orderCode}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            dateFormat.format(widget.order.date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _buildStateChip(context),
                ],
              ),

              const Divider(height: 24),

              // Client Section
              _buildUserSection(
                context,
                icon: Icons.person_outline,
                label: 'العميل',
                userData: _clientData,
                userId: widget.order.clientId,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 12),

              // Supplier Section
              _buildUserSection(
                context,
                icon: Icons.store_outlined,
                label: 'المورد',
                userData: _supplierData,
                userId: widget.order.supplierId,
                isLoading: _isLoading,
              ),

              const Divider(height: 24),

              // Order Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Items count
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.order.itemCount} منتج',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),

                  // Total with discount indicator
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (widget.order.total != widget.order.totalWithOffer)
                        Text(
                          '${widget.order.total.toStringAsFixed(0)} ج.م',
                          style: theme.textTheme.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey[600],
                          ),
                        ),
                      Row(
                        children: [
                          if (widget.order.total != widget.order.totalWithOffer)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${((1 - widget.order.totalWithOffer / widget.order.total) * 100).toStringAsFixed(0)}%-',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.order.totalWithOffer.toStringAsFixed(0)} ج.م',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }

  Widget _buildUserSection(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Map<String, dynamic>? userData,
    required String userId,
    required bool isLoading,
  }) {
    final theme = Theme.of(context);

    if (isLoading) {
      return Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 8),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      );
    }

    final name = userData?['name'] ?? 'غير متوفر';
    final phone = userData?['phone'] ?? '';
    final email = userData?['email'] ?? '';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.grey[700]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$label: ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (phone.isNotEmpty)
                Text(
                  phone,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        if (phone.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.phone, size: 18),
            color: theme.colorScheme.primary,
            onPressed: () {
              // Implement phone call or copy to clipboard
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('رقم الهاتف: $phone')),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildStateChip(BuildContext context) {
    Color color;
    IconData icon;

    switch (widget.order.state) {
      case 'تم التوصيل':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'جاري التوصيل':
        color = Colors.orange;
        icon = Icons.local_shipping;
        break;
      case 'جاري التحضير':
        color = Colors.blue;
        icon = Icons.hourglass_empty;
        break;
      case 'مؤكد':
        color = Colors.tealAccent;
        icon = Icons.hourglass_empty;
        break;
      case 'ملغي':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            widget.order.state,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderDetailsSheet(
        order: widget.order,
        clientData: _clientData,
        supplierData: _supplierData,
      ),
    );
  }
}
