// lib/screens/product_assignment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/product_assignment_cubit/product_assignment_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/product_assignment_cubit/product_assignment_state.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/data/models/manufacturer_model.dart';
import 'package:goods_admin/data/models/product_model.dart';
import 'package:goods_admin/repos/manufacturer_repository.dart';
import 'package:goods_admin/repos/product_repository.dart';

class ProductAssignmentScreen extends StatelessWidget {
  final Manufacturer manufacturer;

  const ProductAssignmentScreen({Key? key, required this.manufacturer})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductAssignmentCubit(
        ManufacturerRepository(),
        ProductRepository(),
      )..loadProductsForManufacturer(manufacturer),
      child: ProductAssignmentView(manufacturer: manufacturer),
    );
  }
}

class ProductAssignmentView extends StatefulWidget {
  final Manufacturer manufacturer;

  const ProductAssignmentView({Key? key, required this.manufacturer})
      : super(key: key);

  @override
  State<ProductAssignmentView> createState() => _ProductAssignmentViewState();
}

class _ProductAssignmentViewState extends State<ProductAssignmentView> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تعيين المنتجات',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.manufacturer.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Cairo',
                    color: Colors.white70,
                  ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
      ),
      body: BlocConsumer<ProductAssignmentCubit, ProductAssignmentState>(
        listener: (context, state) {
          if (state is ProductAssignmentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          } else if (state is ProductAssignmentSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تعيين المنتجات بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        },
        builder: (context, state) {
          if (state is ProductAssignmentLoading ||
              state is ProductAssignmentSaving) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProductAssignmentLoaded) {
            if (state.products.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('لا توجد منتجات متاحة',
                        style: TextStyle(fontFamily: 'Cairo')),
                  ],
                ),
              );
            }

            // Filter products based on search
            final filteredProducts = _searchQuery.isEmpty
                ? state.products
                : state.products
                    .where((product) => product.name
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList();

            return Column(
              children: [
                // Info header
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: widget.manufacturer.imageUrl.isNotEmpty
                            ? NetworkImage(widget.manufacturer.imageUrl)
                            : null,
                        child: widget.manufacturer.imageUrl.isEmpty
                            ? const Icon(Icons.factory,
                                color: Colors.white, size: 24)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.manufacturer.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${state.selectedProductIds.length} منتج محدد',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontFamily: 'Cairo',
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'ابحث عن منتج...',
                      hintStyle: const TextStyle(fontFamily: 'Cairo'),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Quick actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Select all filtered products
                            for (var product in filteredProducts) {
                              if (!state.selectedProductIds
                                  .contains(product.productId)) {
                                context
                                    .read<ProductAssignmentCubit>()
                                    .toggleProductSelection(product.productId);
                              }
                            }
                          },
                          icon: const Icon(Icons.select_all),
                          label: const Text(
                            'تحديد الكل',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            side: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Deselect all filtered products
                            for (var product in filteredProducts) {
                              if (state.selectedProductIds
                                  .contains(product.productId)) {
                                context
                                    .read<ProductAssignmentCubit>()
                                    .toggleProductSelection(product.productId);
                              }
                            }
                          },
                          icon: const Icon(Icons.deselect),
                          label: const Text(
                            'إلغاء الكل',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            side: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Products count
                if (filteredProducts.length != state.products.length)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'عرض ${filteredProducts.length} من ${state.products.length} منتج',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontFamily: 'Cairo',
                        fontSize: 13,
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Products list
                Expanded(
                  child: filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'لا توجد منتجات مطابقة',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            final isSelected = state.selectedProductIds
                                .contains(product.productId);

                            return ProductSelectionCard(
                              product: product,
                              isSelected: isSelected,
                              onToggle: () {
                                context
                                    .read<ProductAssignmentCubit>()
                                    .toggleProductSelection(product.productId);
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
          if (state is ProductAssignmentLoaded) {
            return FloatingActionButton.extended(
              backgroundColor: Theme.of(context).primaryColor,
              onPressed: () {
                context.read<ProductAssignmentCubit>().save();
              },
              icon: const Icon(Icons.save, color: whiteColor),
              label: const Text(
                'حفظ التعيين',
                style: TextStyle(fontFamily: 'Cairo', color: whiteColor),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class ProductSelectionCard extends StatelessWidget {
  final Product product;
  final bool isSelected;
  final VoidCallback onToggle;

  const ProductSelectionCard({
    Key? key,
    required this.product,
    required this.isSelected,
    required this.onToggle,
  }) : super(key: key);

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
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).primaryColor.withOpacity(0.08),
                ),
                child: product.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image_not_supported,
                              color: Theme.of(context).primaryColor,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.inventory_2,
                        color: Theme.of(context).primaryColor,
                      ),
              ),
              const SizedBox(width: 16),

              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).secondaryHeaderColor,
                            fontFamily: 'Cairo',
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${product.price?.toStringAsFixed(2)} جنيه',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).secondaryHeaderColor,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Cairo',
                              ),
                        ),
                        if (product.size != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.size!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).primaryColor,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Checkbox
              Checkbox(
                value: isSelected,
                onChanged: (_) => onToggle(),
                activeColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
