import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/fetch_products/fetch_products_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/firestore_services_cubit/firestore_services_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/get_classifications/get_classifications_cubit.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/data/models/product_model.dart';

class BatchEditDialog extends StatefulWidget {
  final List<Product> products;
  final VoidCallback onComplete;

  const BatchEditDialog({
    super.key,
    required this.products,
    required this.onComplete,
  });

  @override
  State<BatchEditDialog> createState() => _BatchEditDialogState();
}

class _BatchEditDialogState extends State<BatchEditDialog> {
  final TextEditingController _packageController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _selectedManufacturer;
  String? _selectedClassification;

  bool _updateManufacturer = false;
  bool _updateClassification = false;
  bool _updatePackage = false;
  bool _updateSize = false;
  bool _updateNote = false;
  bool _isLoading = false;
  int _processedCount = 0;

  @override
  void initState() {
    super.initState();
    context.read<GetClassificationsCubit>().getProductsClassifications();
  }

  Future<void> _performBatchUpdate() async {
    // Check if at least one field is selected
    if (!_updateManufacturer &&
        !_updateClassification &&
        !_updatePackage &&
        !_updateSize &&
        !_updateNote) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد حقل واحد على الأقل للتعديل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _processedCount = 0;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      WriteBatch batch = firestore.batch();
      int batchCount = 0;
      const int batchLimit = 500;

      // Prepare static data for sync
      Map<String, Map<String, dynamic>> productsStaticData = {};

      // Update products in main collection
      for (var product in widget.products) {
        final docRef = firestore.collection('products').doc(product.productId);

        Map<String, dynamic> updates = {};

        if (_updateManufacturer && _selectedManufacturer != null) {
          updates['manufacturer'] = _selectedManufacturer;
        }
        if (_updateClassification && _selectedClassification != null) {
          updates['classification'] = _selectedClassification;
        }
        if (_updatePackage && _packageController.text.isNotEmpty) {
          updates['package'] = _packageController.text;
        }
        if (_updateSize && _sizeController.text.isNotEmpty) {
          updates['size'] = _sizeController.text;
        }
        if (_updateNote && _noteController.text.isNotEmpty) {
          updates['note'] = _noteController.text;
        }

        if (updates.isNotEmpty) {
          batch.update(docRef, updates);
          batchCount++;

          // Prepare full static data for store sync
          productsStaticData[product.productId] = {
            'name': product.name,
            'classification':
                _updateClassification && _selectedClassification != null
                    ? _selectedClassification
                    : product.classification,
            'imageUrl': product.imageUrl,
            'manufacturer': _updateManufacturer && _selectedManufacturer != null
                ? _selectedManufacturer
                : product.manufacturer,
            'size': _updateSize && _sizeController.text.isNotEmpty
                ? _sizeController.text
                : product.size,
            'package': _updatePackage && _packageController.text.isNotEmpty
                ? _packageController.text
                : product.package,
            'note': _updateNote && _noteController.text.isNotEmpty
                ? _noteController.text
                : (product.note ?? ''),
          };

          // Update local cache
          Product updatedProduct = Product(
            name: product.name,
            manufacturer: _updateManufacturer && _selectedManufacturer != null
                ? _selectedManufacturer!
                : product.manufacturer,
            size: _updateSize && _sizeController.text.isNotEmpty
                ? _sizeController.text
                : product.size,
            package: _updatePackage && _packageController.text.isNotEmpty
                ? _packageController.text
                : product.package,
            classification:
                _updateClassification && _selectedClassification != null
                    ? _selectedClassification!
                    : product.classification,
            note: _updateNote && _noteController.text.isNotEmpty
                ? _noteController.text
                : product.note,
            salesCount: product.salesCount,
            imageUrl: product.imageUrl,
            productId: product.productId,
          );

          if (mounted) {
            context
                .read<FetchProductsCubit>()
                .updateProductInList(updatedProduct);
          }

          if (batchCount >= batchLimit) {
            await batch.commit();
            batch = firestore.batch();
            batchCount = 0;
          }

          setState(() {
            _processedCount++;
          });
        }
      }

      // Commit remaining batch
      if (batchCount > 0) {
        await batch.commit();
      }

      // Close current dialog and show syncing dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show syncing dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => BatchSyncProgressDialog(
            totalProducts: widget.products.length,
          ),
        );
      }

      // Sync to all stores
      if (mounted) {
        final cubit = context.read<FirestoreServicesCubit>();
        final syncResult = await cubit.syncMultipleProductsToAllStores(
          widget.products.map((p) => p.productId).toList(),
          productsStaticData,
        );

        // Close syncing dialog
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Show result
        if (mounted) {
          if (syncResult.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تم تحديث ${widget.products.length} منتج بنجاح!'),
                    Text(
                      'تم مزامنة ${syncResult.totalUpdates} منتج في المتاجر',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'تفاصيل',
                  textColor: Colors.white,
                  onPressed: () {
                    _showBatchSyncDetails(syncResult);
                  },
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('تم التحديث لكن فشلت المزامنة: ${syncResult.error}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }

          widget.onComplete();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء التحديث: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showBatchSyncDetails(BatchSyncResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفاصيل المزامنة الجماعية'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('إجمالي التحديثات', '${result.totalUpdates}'),
              const Divider(),
              const Text(
                'التحديثات لكل منتج:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...result.productUpdateCounts.entries.map((entry) {
                final product =
                    widget.products.firstWhere((p) => p.productId == entry.key);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${entry.value}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('تعديل مجمع (${widget.products.length} منتج)'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: BlocBuilder<GetClassificationsCubit, GetClassificationsState>(
            builder: (context, state) {
              if (state is GetClassificationsLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: primaryColor),
                );
              }

              if (state is GetClassificationsError) {
                return Center(
                  child: Text('خطأ في تحميل البيانات: ${state.message}'),
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoading) ...[
                    LinearProgressIndicator(
                      value: _processedCount / widget.products.length,
                      backgroundColor: Colors.grey[300],
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'جاري المعالجة... $_processedCount من ${widget.products.length}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                  ],

                  const Text(
                    'اختر الحقول المراد تعديلها:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  // Manufacturer Dropdown
                  _buildDropdownField(
                    'الشركة المصنعة',
                    _updateManufacturer,
                    (value) =>
                        setState(() => _updateManufacturer = value ?? false),
                    _selectedManufacturer,
                    (value) => setState(() => _selectedManufacturer = value),
                    context
                        .read<GetClassificationsCubit>()
                        .manufacturer
                        .entries
                        .map((entry) => DropdownMenuEntry(
                              value: entry.key,
                              label: entry.value,
                            ))
                        .toList(),
                  ),

                  // Classification Dropdown
                  _buildDropdownField(
                    'التصنيف',
                    _updateClassification,
                    (value) =>
                        setState(() => _updateClassification = value ?? false),
                    _selectedClassification,
                    (value) => setState(() => _selectedClassification = value),
                    context
                        .read<GetClassificationsCubit>()
                        .classification
                        .entries
                        .map((entry) => DropdownMenuEntry(
                              value: entry.value,
                              label: entry.value,
                            ))
                        .toList(),
                  ),

                  // Package TextField
                  _buildUpdateField(
                    'العبوة',
                    _packageController,
                    _updatePackage,
                    (value) => setState(() => _updatePackage = value ?? false),
                  ),

                  // Size TextField
                  _buildUpdateField(
                    'الحجم',
                    _sizeController,
                    _updateSize,
                    (value) => setState(() => _updateSize = value ?? false),
                  ),

                  // Note TextField
                  _buildUpdateField(
                    'ملاحظات',
                    _noteController,
                    _updateNote,
                    (value) => setState(() => _updateNote = value ?? false),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 16),

                  // Products Preview
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 16, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'المنتجات المحددة: ${widget.products.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            itemCount: widget.products.length > 5
                                ? 5
                                : widget.products.length,
                            itemBuilder: (context, index) {
                              final product = widget.products[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        color: primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        product.name,
                                        style: const TextStyle(fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        if (widget.products.length > 5)
                          Text(
                            '... و ${widget.products.length - 5} منتج آخر',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _performBatchUpdate,
          style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('تطبيق التعديلات',
                  style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    bool isEnabled,
    Function(bool?) onChanged,
    String? selectedValue,
    Function(String?) onDropdownChanged,
    List<DropdownMenuEntry> entries,
  ) {
    String? validInitialSelection;
    if (selectedValue != null) {
      final matchingEntry =
          entries.cast<DropdownMenuEntry<String>?>().firstWhere(
                (entry) => entry?.value == selectedValue,
                orElse: () => null,
              );

      if (matchingEntry != null) {
        validInitialSelection = selectedValue;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Checkbox(
            value: isEnabled,
            onChanged: _isLoading ? null : onChanged,
            activeColor: primaryColor,
          ),
          Expanded(
            child: DropdownMenu(
              enabled: isEnabled && !_isLoading,
              width: double.infinity,
              initialSelection: validInitialSelection,
              label: Text(label),
              dropdownMenuEntries: entries.cast<DropdownMenuEntry<String>>(),
              onSelected: onDropdownChanged,
              inputDecorationTheme: const InputDecorationTheme(
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateField(
    String label,
    TextEditingController controller,
    bool isEnabled,
    Function(bool?) onChanged, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Checkbox(
            value: isEnabled,
            onChanged: _isLoading ? null : onChanged,
            activeColor: primaryColor,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: isEnabled && !_isLoading,
              maxLines: maxLines,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _packageController.dispose();
    _sizeController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}

class BatchSyncProgressDialog extends StatelessWidget {
  final int totalProducts;

  const BatchSyncProgressDialog({
    super.key,
    required this.totalProducts,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
            const SizedBox(height: 20),
            const Text(
              'جاري مزامنة البيانات في المتاجر...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'يتم تحديث $totalProducts منتج في جميع المتاجر',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'قد تستغرق هذه العملية بعض الوقت...',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
