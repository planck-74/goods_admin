import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/orders_cubit/orders_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/orders_cubit/orders_state.dart';
import 'package:goods_admin/data/models/order_model.dart';
import 'package:goods_admin/presentation/cards/order_card.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _searchController = TextEditingController();
  String? _selectedState;
  String? _selectedSupplier;

  final List<String> _orderStates = [
    'الكل',
    'قيد التجهيز',
    'في الطريق',
    'تم التوصيل',
    'ملغي',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الطلبات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'البحث برقم الطلب أو معرف العميل',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<OrdersCubit>().resetToOrders();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  context.read<OrdersCubit>().resetToOrders();
                } else if (value.length >= 3) {
                  context.read<OrdersCubit>().searchOrders(value);
                }
                setState(() {});
              },
            ),
          ),
          if (_selectedState != null || _selectedSupplier != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedState != null)
                    Chip(
                      label: Text(_selectedState!),
                      onDeleted: () {
                        setState(() => _selectedState = null);
                        context.read<OrdersCubit>().loadOrders();
                      },
                    ),
                  if (_selectedSupplier != null)
                    Chip(
                      label: Text('المورد: $_selectedSupplier'),
                      onDeleted: () {
                        setState(() => _selectedSupplier = null);
                        context.read<OrdersCubit>().loadOrders(
                              stateFilter: _selectedState != 'الكل'
                                  ? _selectedState
                                  : null,
                            );
                      },
                    ),
                ],
              ),
            ),
          Expanded(
            child: BlocBuilder<OrdersCubit, OrdersState>(
              builder: (context, state) {
                if (state is OrdersLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is OrdersError) {
                  return Center(child: Text('خطأ: ${state.message}'));
                }

                final orders = state is OrdersLoaded
                    ? state.orders
                    : state is OrdersSearchResults
                        ? state.results
                        : <Order>[];

                if (orders.isEmpty) {
                  return const Center(child: Text('لا توجد طلبات'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return OrderCard(order: order);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصفية الطلبات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedState,
              decoration: const InputDecoration(labelText: 'حالة الطلب'),
              items: _orderStates.map((state) {
                return DropdownMenuItem(value: state, child: Text(state));
              }).toList(),
              onChanged: (value) => setState(() => _selectedState = value),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'معرف المورد (اختياري)',
                hintText: 'أدخل معرف المورد',
              ),
              onChanged: (value) =>
                  _selectedSupplier = value.isEmpty ? null : value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedState = null;
                _selectedSupplier = null;
              });
              context.read<OrdersCubit>().loadOrders();
              Navigator.pop(context);
            },
            child: const Text('إعادة تعيين'),
          ),
          FilledButton(
            onPressed: () {
              context.read<OrdersCubit>().loadOrders(
                    stateFilter:
                        _selectedState != 'الكل' ? _selectedState : null,
                    supplierFilter: _selectedSupplier,
                  );
              Navigator.pop(context);
            },
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
