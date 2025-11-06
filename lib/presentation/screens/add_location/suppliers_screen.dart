// lib/presentation/screens/suppliers_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/suppliers/suppliers_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/suppliers/suppliers_state.dart';
import 'package:goods_admin/data/models/location_model.dart';
import 'package:goods_admin/data/repositories/supplier_repository.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';
import 'package:goods_admin/presentation/dialogs/supplier_coverage_dialog.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SuppliersCubit(
        repository: SupplierRepository(),
      )..loadSuppliers(),
      child: const _SuppliersScreenContent(),
    );
  }
}

class _SuppliersScreenContent extends StatefulWidget {
  const _SuppliersScreenContent();

  @override
  State<_SuppliersScreenContent> createState() =>
      _SuppliersScreenContentState();
}

class _SuppliersScreenContentState extends State<_SuppliersScreenContent> {
  String? selectedSupplierId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: customAppBar(
        context,
        const Row(
          children: [
            Text(
              "قائمة التجار",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<SuppliersCubit, SuppliersState>(
        builder: (context, state) {
          if (state is SuppliersLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SuppliersError) {
            return _buildErrorState(context, state.message);
          }

          if (state is SuppliersLoaded) {
            if (state.suppliers.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () =>
                  context.read<SuppliersCubit>().refreshSuppliers(),
              child: _buildSuppliersList(state.suppliers),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'حدث خطأ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<SuppliersCubit>().refreshSuppliers(),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.store_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'لا يوجد موردين',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم يتم العثور على موردين متاحين حالياً',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuppliersList(List<SupplierModel> suppliers) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: suppliers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final supplier = suppliers[index];
        return _SupplierCard(
          supplier: supplier,
          isSelected: supplier.id == selectedSupplierId,
          onTap: () {
            setState(() {
              selectedSupplierId =
                  selectedSupplierId == supplier.id ? null : supplier.id;
            });
          },
          onManageCoverage: () => _openCoverageManagement(context, supplier),
        );
      },
    );
  }

  Future<void> _openCoverageManagement(
      BuildContext context, SupplierModel supplier) async {
    await SupplierCoverageDialog.show(
      context,
      supplierId: supplier.id,
      supplierName: supplier.businessName,
    );
    if (mounted) {
      context.read<SuppliersCubit>().refreshSuppliers();
    }
  }
}

class _SupplierCard extends StatelessWidget {
  final SupplierModel supplier;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onManageCoverage;

  const _SupplierCard({
    required this.supplier,
    required this.isSelected,
    required this.onTap,
    required this.onManageCoverage,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.2)
                  : Colors.black.withOpacity(0.06),
              blurRadius: isSelected ? 16 : 12,
              offset: Offset(0, isSelected ? 6 : 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInfo(context)),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected) ...[
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.grey.shade200,
              ),
              _buildExpandedSection(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Hero(
      tag: 'supplier_${supplier.id}',
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 32,
          backgroundImage: NetworkImage(
            supplier.imageUrl.isNotEmpty
                ? supplier.imageUrl
                : 'https://via.placeholder.com/150',
          ),
          backgroundColor: Colors.grey.shade100,
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          supplier.businessName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.payments, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              'الحد الأدنى: ${supplier.minOrderPrice} ج.م',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              supplier.coverageAreas.isEmpty
                  ? Icons.location_off
                  : Icons.location_on,
              size: 14,
              color: supplier.coverageAreas.isEmpty
                  ? Colors.red.shade400
                  : Colors.green.shade600,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                supplier.coverageSummary,
                style: TextStyle(
                  fontSize: 13,
                  color: supplier.coverageAreas.isEmpty
                      ? Colors.red.shade600
                      : Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // معلومات إضافية
          _buildInfoRow(
            icon: Icons.phone,
            label: 'الهاتف',
            value: supplier.phoneNumber,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.inventory_2,
            label: 'الحد الأدنى للمنتجات',
            value: '${supplier.minOrderProducts} منتج',
          ),
          const SizedBox(height: 16),
          // زر إدارة التغطية
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onManageCoverage,
              icon: const Icon(Icons.map_outlined),
              label: const Text(
                'إدارة مناطق التغطية',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
