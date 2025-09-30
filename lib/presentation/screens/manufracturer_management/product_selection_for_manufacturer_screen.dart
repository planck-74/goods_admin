// lib/screens/product_selection_for_manufacturer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/fetch_products/fetch_products_cubit.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/data/models/product_model.dart';
import 'package:goods_admin/test.dart';

class ProductSelectionForManufacturerScreen extends StatefulWidget {
  const ProductSelectionForManufacturerScreen({Key? key}) : super(key: key);

  @override
  State<ProductSelectionForManufacturerScreen> createState() =>
      _ProductSelectionForManufacturerScreenState();
}

class _ProductSelectionForManufacturerScreenState
    extends State<ProductSelectionForManufacturerScreen> {
  final Set<String> _selectedProductIds = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<FetchProductsCubit>().fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleProductSelection(String productId) {
    setState(() {
      if (_selectedProductIds.contains(productId)) {
        _selectedProductIds.remove(productId);
      } else {
        _selectedProductIds.add(productId);
      }
    });
  }

  void _navigateToManufacturerSelection(List<Product> allProducts) {
    if (_selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى اختيار منتج واحد على الأقل',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedProducts = allProducts
        .where((p) => _selectedProductIds.contains(p.productId))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManufacturerSelectionScreen(
          selectedProducts: selectedProducts,
        ),
      ),
    ).then((result) {
      if (result == true) {
        Navigator.pop(context, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اختر المنتجات',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'الخطوة 1 من 2',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
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
      body: BlocBuilder<FetchProductsCubit, FetchProductsState>(
        builder: (context, state) {
          if (state is FetchProductsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is FetchProductsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text('خطأ: ${state.message}',
                      style: const TextStyle(fontFamily: 'Cairo')),
                ],
              ),
            );
          } else if (state is FetchProductsLoaded) {
            final allProducts = state.products;

            if (allProducts.isEmpty) {
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

            final filteredProducts = _searchQuery.isEmpty
                ? allProducts
                : allProducts
                    .where((product) => product.name
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList();

            return Column(
              children: [
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
                      const Icon(Icons.checklist,
                          color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'المنتجات المحددة',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_selectedProductIds.length} منتج محدد',
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
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              for (var product in filteredProducts) {
                                _selectedProductIds.add(product.productId);
                              }
                            });
                          },
                          icon: const Icon(Icons.select_all),
                          label: const Text('تحديد الكل',
                              style: TextStyle(fontFamily: 'Cairo')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            side: BorderSide(
                                color: Theme.of(context).primaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedProductIds.clear();
                            });
                          },
                          icon: const Icon(Icons.deselect),
                          label: const Text('إلغاء الكل',
                              style: TextStyle(fontFamily: 'Cairo')),
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
                Expanded(
                  child: filteredProducts.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('لا توجد منتجات مطابقة',
                                  style: TextStyle(fontFamily: 'Cairo')),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            final isSelected =
                                _selectedProductIds.contains(product.productId);

                            return _ProductCard(
                              product: product,
                              isSelected: isSelected,
                              onToggle: () =>
                                  _toggleProductSelection(product.productId),
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
      floatingActionButton: _selectedProductIds.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: Theme.of(context).primaryColor,
              onPressed: () {
                final state = context.read<FetchProductsCubit>().state;
                if (state is FetchProductsLoaded) {
                  _navigateToManufacturerSelection(state.products);
                }
              },
              icon: const Icon(Icons.arrow_forward, color: whiteColor),
              label: Text(
                'التالي (${_selectedProductIds.length})',
                style: const TextStyle(fontFamily: 'Cairo', color: whiteColor),
              ),
            )
          : null,
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final bool isSelected;
  final VoidCallback onToggle;

  const _ProductCard({
    required this.product,
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
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
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
                        child:
                            Image.network(product.imageUrl, fit: BoxFit.cover),
                      )
                    : Icon(Icons.inventory_2,
                        color: Theme.of(context).primaryColor),
              ),
              const SizedBox(width: 16),
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
                                : null,
                            fontFamily: 'Cairo',
                          ),
                    ),
                    if (product.price != null)
                      Text(
                        '${product.price!.toStringAsFixed(2)} جنيه',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: Colors.grey,
                        ),
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
