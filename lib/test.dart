// lib/screens/manufacturer_selection_screen.dart
// Updated version that works with product-first flow
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/product_assignment_cubit/product_assignment_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/product_assignment_cubit/product_assignment_state.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/data/models/manufacturer_model.dart';
import 'package:goods_admin/data/models/product_model.dart';
import 'package:goods_admin/repos/manufacturer_repository.dart';
import 'package:goods_admin/repos/product_repository.dart';

class ManufacturerSelectionScreen extends StatelessWidget {
  final List<Product> selectedProducts;

  const ManufacturerSelectionScreen({
    Key? key,
    required this.selectedProducts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductAssignmentCubit(
        ManufacturerRepository(),
        ProductRepository(),
      )..loadManufacturersForProducts(selectedProducts),
      child: ManufacturerSelectionView(selectedProducts: selectedProducts),
    );
  }
}

class ManufacturerSelectionView extends StatelessWidget {
  final List<Product> selectedProducts;

  const ManufacturerSelectionView({
    Key? key,
    required this.selectedProducts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر المصنعين',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'الخطوة 2 من 2 • ${selectedProducts.length} منتج',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocConsumer<ProductAssignmentCubit, ProductAssignmentState>(
        listener: (context, state) {
          if (state is ProductAssignmentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is ProductAssignmentSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'تم تعيين المنتجات بنجاح ✓',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            Navigator.pop(context, true);
          }
        },
        builder: (context, state) {
          if (state is ProductAssignmentLoading ||
              state is ProductAssignmentSaving) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ManufacturerSelectionLoaded) {
            if (state.manufacturers.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.factory_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('لا يوجد مصنعون متاحون',
                        style: TextStyle(fontFamily: 'Cairo')),
                    SizedBox(height: 8),
                    Text('يجب إضافة مصنع أولاً',
                        style:
                            TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Selected products preview
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.inventory_2, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'المنتجات التي سيتم تعيينها',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedProducts.take(3).map((product) {
                          return Chip(
                            avatar: product.imageUrl.isNotEmpty
                                ? CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(product.imageUrl),
                                  )
                                : null,
                            label: Text(
                              product.name,
                              style: const TextStyle(
                                  fontFamily: 'Cairo', fontSize: 12),
                            ),
                            backgroundColor: Colors.white.withOpacity(0.9),
                          );
                        }).toList(),
                      ),
                      if (selectedProducts.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '+${selectedProducts.length - 3} منتج آخر',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontFamily: 'Cairo',
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Info banner
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: state.selectedManufacturerIds.isEmpty
                        ? Colors.orange.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: state.selectedManufacturerIds.isEmpty
                          ? Colors.orange.shade200
                          : Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state.selectedManufacturerIds.isEmpty
                            ? Icons.warning_amber_rounded
                            : Icons.info_outline,
                        color: state.selectedManufacturerIds.isEmpty
                            ? Colors.orange.shade700
                            : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.selectedManufacturerIds.isEmpty
                              ? 'اختر مصنع واحد على الأقل'
                              : '${state.selectedManufacturerIds.length} مصنع محدد',
                          style: TextStyle(
                            color: state.selectedManufacturerIds.isEmpty
                                ? Colors.orange.shade900
                                : Colors.blue.shade900,
                            fontFamily: 'Cairo',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Manufacturers list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.manufacturers.length,
                    itemBuilder: (context, index) {
                      final manufacturer = state.manufacturers[index];
                      final isSelected = state.selectedManufacturerIds
                          .contains(manufacturer.name);

                      return _ManufacturerCard(
                        manufacturer: manufacturer,
                        isSelected: isSelected,
                        onToggle: () {
                          context
                              .read<ProductAssignmentCubit>()
                              .toggleManufacturerSelection(manufacturer.name);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton:
          BlocBuilder<ProductAssignmentCubit, ProductAssignmentState>(
        builder: (context, state) {
          if (state is ManufacturerSelectionLoaded &&
              state.selectedManufacturerIds.isNotEmpty) {
            return FloatingActionButton.extended(
              backgroundColor: Theme.of(context).primaryColor,
              onPressed: () {
                context.read<ProductAssignmentCubit>().save();
              },
              icon: const Icon(Icons.save, color: whiteColor),
              label: Text(
                'حفظ التعيين (${state.selectedManufacturerIds.length})',
                style: const TextStyle(fontFamily: 'Cairo', color: whiteColor),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ManufacturerCard extends StatelessWidget {
  final Manufacturer manufacturer;
  final bool isSelected;
  final VoidCallback onToggle;

  const _ManufacturerCard({
    required this.manufacturer,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? Theme.of(context).primaryColor.withOpacity(0.12)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).primaryColor.withOpacity(0.08),
                ),
                child: manufacturer.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          manufacturer.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.factory,
                                size: 36,
                                color: Theme.of(context).primaryColor);
                          },
                        ),
                      )
                    : Icon(Icons.factory,
                        size: 36, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manufacturer.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : null,
                            fontFamily: 'Cairo',
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${manufacturer.productsIds.length} منتج حالي',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontFamily: 'Cairo',
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: isSelected,
                onChanged: (_) => onToggle(),
                activeColor: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
