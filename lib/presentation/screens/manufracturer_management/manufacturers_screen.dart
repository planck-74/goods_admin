import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/manufacturer_cubit/manufacturer_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/manufacturer_cubit/manufacturer_state.dart';
import 'package:goods_admin/business%20logic/cubits/product_assignment_cubit/product_assignment_cubit.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/data/models/manufacturer_model.dart';
import 'package:goods_admin/repos/manufacturer_repository.dart';
import 'package:goods_admin/repos/product_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'product_assignment_screen.dart';

class ManufacturersScreen extends StatelessWidget {
  const ManufacturersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ManufacturerCubit(ManufacturerRepository())..loadManufacturers(),
      child: const ManufacturersView(),
    );
  }
}

class ManufacturersView extends StatelessWidget {
  const ManufacturersView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('إدارة المصنعين',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold),
      ),
      body: BlocBuilder<ManufacturerCubit, ManufacturerState>(
        builder: (context, state) {
          if (state is ManufacturerLoading ||
              state is ManufacturerOperationInProgress) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ManufacturerError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<ManufacturerCubit>().loadManufacturers(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is ManufacturerLoaded) {
            if (state.manufacturers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(height: 16),
                    const Text('No manufacturers yet'),
                    const SizedBox(height: 8),
                    const Text('Add your first manufacturer',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            return ReorderableListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: state.manufacturers.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                final manufacturers =
                    List<Manufacturer>.from(state.manufacturers);
                final item = manufacturers.removeAt(oldIndex);
                manufacturers.insert(newIndex, item);
                context
                    .read<ManufacturerCubit>()
                    .reorderManufacturers(manufacturers);
              },
              itemBuilder: (context, index) {
                final manufacturer = state.manufacturers[index];
                return ManufacturerCard(
                  key: ValueKey(manufacturer.name),
                  manufacturer: manufacturer,
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () => _showAddManufacturerDialog(context),
        icon: const Icon(
          Icons.add,
          color: whiteColor,
        ),
        label: const Text(
          'إضافة مصنع',
          style: TextStyle(color: whiteColor),
        ),
      ),
    );
  }

  void _showAddManufacturerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ManufacturerCubit>(),
        child: const AddManufacturerDialog(),
      ),
    );
  }
}

class ManufacturerCard extends StatelessWidget {
  final Manufacturer manufacturer;

  const ManufacturerCard({Key? key, required this.manufacturer})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          backgroundImage: manufacturer.imageUrl.isNotEmpty
              ? NetworkImage(manufacturer.imageUrl)
              : null,
          child: manufacturer.imageUrl.isEmpty
              ? Icon(Icons.factory,
                  size: 30, color: Theme.of(context).primaryColor)
              : null,
        ),
        title: Text(
          manufacturer.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('عدد المنتجات: ${manufacturer.productsIds.length}',
                style:
                    TextStyle(color: Theme.of(context).secondaryHeaderColor)),
            Row(
              children: [
                const Text('الترتيب: ', style: TextStyle(fontFamily: 'Cairo')),
                InkWell(
                  onTap: () => _showEditNumberDialog(context, manufacturer),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${manufacturer.number}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditManufacturerDialog(context, manufacturer);
                break;
              case 'delete':
                _confirmDelete(context, manufacturer);
                break;
              case 'assign':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProductAssignmentScreen(manufacturer: manufacturer),
                  ),
                );
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(
                value: 'assign', child: Text('Assign Products')),
            PopupMenuItem(
              value: 'delete',
              child: Text('Delete',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNumberDialog(BuildContext context, Manufacturer manufacturer) {
    final controller =
        TextEditingController(text: manufacturer.number.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Order Number'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Order Number',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newNumber = int.tryParse(controller.text);
              if (newNumber != null) {
                context
                    .read<ManufacturerCubit>()
                    .updateManufacturerNumber(manufacturer, newNumber);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditManufacturerDialog(
      BuildContext context, Manufacturer manufacturer) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ManufacturerCubit>(),
        child: EditManufacturerDialog(manufacturer: manufacturer),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Manufacturer manufacturer) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Manufacturer'),
        content:
            Text('Are you sure you want to delete "${manufacturer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context
                  .read<ManufacturerCubit>()
                  .deleteManufacturer(manufacturer);
              Navigator.pop(dialogContext);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class AddManufacturerDialog extends StatefulWidget {
  const AddManufacturerDialog({Key? key}) : super(key: key);

  @override
  State<AddManufacturerDialog> createState() => _AddManufacturerDialogState();
}

class _AddManufacturerDialogState extends State<AddManufacturerDialog> {
  final _nameController = TextEditingController();
  final _numberController = TextEditingController(text: '0');
  File? _imageFile;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة مصنع',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المصنع',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال اسم المصنع';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _numberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الترتيب',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || int.tryParse(value) == null) {
                    return 'يرجى إدخال رقم صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate,
                                size: 48,
                                color: Theme.of(context).colorScheme.secondary),
                            const SizedBox(height: 8),
                            const Text('اضغط لإضافة صورة',
                                style: TextStyle(fontFamily: 'Cairo')),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
        ),
        FilledButton(
          onPressed: _saveManufacturer,
          style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor),
          child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _saveManufacturer() {
    if (_formKey.currentState!.validate()) {
      context.read<ManufacturerCubit>().addManufacturer(
            name: _nameController.text,
            imageFile: _imageFile,
            number: int.parse(_numberController.text),
          );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }
}

class EditManufacturerDialog extends StatefulWidget {
  final Manufacturer manufacturer;

  const EditManufacturerDialog({Key? key, required this.manufacturer})
      : super(key: key);

  @override
  State<EditManufacturerDialog> createState() => _EditManufacturerDialogState();
}

class _EditManufacturerDialogState extends State<EditManufacturerDialog> {
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  File? _newImageFile;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.manufacturer.name);
    _numberController =
        TextEditingController(text: widget.manufacturer.number.toString());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل المصنع',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المصنع',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال اسم المصنع';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _numberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الترتيب',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || int.tryParse(value) == null) {
                    return 'يرجى إدخال رقم صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _newImageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_newImageFile!, fit: BoxFit.cover),
                        )
                      : widget.manufacturer.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(widget.manufacturer.imageUrl,
                                  fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate,
                                    size: 48,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary),
                                const SizedBox(height: 8),
                                const Text('اضغط لتغيير الصورة',
                                    style: TextStyle(fontFamily: 'Cairo')),
                              ],
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
        ),
        FilledButton(
          onPressed: _updateManufacturer,
          style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor),
          child: const Text('تحديث', style: TextStyle(fontFamily: 'Cairo')),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _newImageFile = File(pickedFile.path);
      });
    }
  }

  void _updateManufacturer() {
    if (_formKey.currentState!.validate()) {
      final updatedManufacturer = widget.manufacturer.copyWith(
        name: _nameController.text,
        number: int.parse(_numberController.text),
      );

      context.read<ManufacturerCubit>().updateManufacturer(
            manufacturer: updatedManufacturer,
            newImageFile: _newImageFile,
          );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }
}

// lib/screens/product_assignment_screen.dart
