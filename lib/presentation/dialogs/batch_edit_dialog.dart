import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  @override
  void initState() {
    super.initState();
    // Load classifications data when dialog opens
    context.read<GetClassificationsCubit>().getProductsClassifications();
  }

  Future<void> _performBatchUpdate() async {
    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (final product in widget.products) {
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
        }
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث ${widget.products.length} منتج بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
        widget.onComplete();
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
              : const Text('تحديث', style: TextStyle(color: Colors.white)),
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
    // Find the initial selection that matches an entry
    String? validInitialSelection;
    if (selectedValue != null) {
      // Check if selectedValue exists in entries
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
            onChanged: onChanged,
            activeColor: primaryColor,
          ),
          Expanded(
            child: DropdownMenu(
              enabled: isEnabled,
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
    Function(bool?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Checkbox(
            value: isEnabled,
            onChanged: onChanged,
            activeColor: primaryColor,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: isEnabled,
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
