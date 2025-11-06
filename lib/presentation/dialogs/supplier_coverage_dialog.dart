// lib/presentation/screens/supplier_coverage_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/supplier_coverage/supplier_coverage_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/supplier_coverage/supplier_coverage_state.dart';
import 'package:goods_admin/data/models/location_model.dart';
import '../../data/repositories/supplier_repository.dart';

class SupplierCoverageDialog extends StatelessWidget {
  final String supplierId;
  final String supplierName;

  const SupplierCoverageDialog({
    super.key,
    required this.supplierId,
    required this.supplierName,
  });

  static Future<void> show(
    BuildContext context, {
    required String supplierId,
    required String supplierName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => BlocProvider(
        create: (_) => SupplierCoverageCubit(
          supplierRepo: SupplierRepository(),
          locationRepo: LocationRepository(),
        )..loadSupplierCoverage(supplierId),
        child: SupplierCoverageDialog(
          supplierId: supplierId,
          supplierName: supplierName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildDragHandle(),
          _buildHeader(context),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.map_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مناطق التغطية',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  supplierName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<SupplierCoverageCubit, SupplierCoverageState>(
      builder: (context, state) {
        if (state is SupplierCoverageLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جاري التحميل...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        if (state is SupplierCoverageLoaded) {
          return _buildContent(context, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContent(BuildContext context, SupplierCoverageLoaded state) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // قسم الإضافة
            SliverToBoxAdapter(
              child: _AddCoverageSection(
                state: state,
                onSuccess: (message) => _showSuccessToast(context, message),
              ),
            ),

            // الإحصائيات
            if (state.supplier.coverageAreas.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildStats(context, state),
              ),

            // القائمة
            if (state.supplier.coverageAreas.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: _buildCoverageList(context, state),
              ),
          ],
        ),
      ],
    );
  }

  void _showSuccessToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: 20,
        right: 20,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  Widget _buildStats(BuildContext context, SupplierCoverageLoaded state) {
    final fullGovs =
        state.supplier.coverageAreas.where((c) => c.isFullGovernment).length;
    final cities =
        state.supplier.coverageAreas.where((c) => !c.isFullGovernment).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.location_city,
              label: 'محافظات',
              value: fullGovs.toString(),
              color: Colors.blue,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.location_on,
              label: 'مدن',
              value: cities.toString(),
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCoverageList(
      BuildContext context, SupplierCoverageLoaded state) {
    // تنظيم حسب المحافظة
    final groupedByGov = <String, List<CoverageAreaModel>>{};
    for (final coverage in state.supplier.coverageAreas) {
      groupedByGov.putIfAbsent(coverage.government, () => []).add(coverage);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final government = groupedByGov.keys.elementAt(index);
          final coverages = groupedByGov[government]!;

          return _GovernmentCoverageCard(
            government: government,
            coverages: coverages,
          );
        },
        childCount: groupedByGov.length,
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
              Icons.location_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد مناطق تغطية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة محافظة أو مدينة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

// قسم الإضافة المحسّن
class _AddCoverageSection extends StatefulWidget {
  final SupplierCoverageLoaded state;
  final Function(String) onSuccess;

  const _AddCoverageSection({
    required this.state,
    required this.onSuccess,
  });

  @override
  State<_AddCoverageSection> createState() => _AddCoverageSectionState();
}

class _AddCoverageSectionState extends State<_AddCoverageSection> {
  String? selectedGovernment;
  bool isFullGovernment = true;
  String? selectedCity;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add_location_alt,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'إضافة تغطية جديدة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildGovernmentDropdown(),
          const SizedBox(height: 16),
          _buildCoverageTypeToggle(),
          if (!isFullGovernment && selectedGovernment != null) ...[
            const SizedBox(height: 16),
            _buildCityDropdown(),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildGovernmentDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: selectedGovernment,
        decoration: const InputDecoration(
          labelText: 'المحافظة',
          prefixIcon: Icon(Icons.location_city),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: widget.state.governments
            .map((gov) => DropdownMenuItem(
                  value: gov,
                  child: Text(gov),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            selectedGovernment = value;
            selectedCity = null;
          });
          if (value != null && !isFullGovernment) {
            context
                .read<SupplierCoverageCubit>()
                .loadCitiesForGovernment(value);
          }
        },
      ),
    );
  }

  Widget _buildCoverageTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleOption(
              label: 'المحافظة كاملة',
              icon: Icons.public,
              isSelected: isFullGovernment,
              onTap: () => setState(() {
                isFullGovernment = true;
                selectedCity = null;
              }),
            ),
          ),
          Expanded(
            child: _buildToggleOption(
              label: 'مدينة محددة',
              icon: Icons.location_on,
              isSelected: !isFullGovernment,
              onTap: () {
                setState(() => isFullGovernment = false);
                if (selectedGovernment != null) {
                  context
                      .read<SupplierCoverageCubit>()
                      .loadCitiesForGovernment(selectedGovernment!);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityDropdown() {
    final cities = widget.state.getCitiesForGovernment(selectedGovernment!);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: selectedCity,
        decoration: const InputDecoration(
          labelText: 'المدينة',
          prefixIcon: Icon(Icons.location_on_outlined),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: cities
            .map((city) => DropdownMenuItem(
                  value: city,
                  child: Text(city),
                ))
            .toList(),
        onChanged: (value) => setState(() => selectedCity = value),
      ),
    );
  }

  Widget _buildAddButton() {
    final canAdd = selectedGovernment != null &&
        (isFullGovernment || selectedCity != null);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canAdd ? _addCoverage : null,
        icon: const Icon(Icons.add),
        label: const Text(
          'إضافة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: canAdd ? 2 : 0,
        ),
      ),
    );
  }

  void _addCoverage() {
    if (selectedGovernment == null) return;

    final cubit = context.read<SupplierCoverageCubit>();
    final currentState = cubit.state as SupplierCoverageLoaded;

    if (isFullGovernment) {
      // تحقق من عدم وجودها مسبقاً
      final alreadyExists = currentState.supplier.coverageAreas.any(
        (c) => c.government == selectedGovernment && c.isFullGovernment,
      );

      if (alreadyExists) {
        _showInlineError('محافظة $selectedGovernment مضافة بالفعل');
        return;
      }

      cubit.addFullGovernment(selectedGovernment!);
      widget.onSuccess('تمت إضافة $selectedGovernment بالكامل ✓');
    } else {
      if (selectedCity == null) return;

      // تحقق من وجود المحافظة كاملة
      final hasFullGovernment = currentState.supplier.coverageAreas.any(
        (c) => c.government == selectedGovernment && c.isFullGovernment,
      );

      if (hasFullGovernment) {
        _showInlineError(
            'محافظة $selectedGovernment مضافة بالفعل كاملة\nلا يمكن إضافة مدن منفصلة');
        return;
      }

      // تحقق من وجود المدينة
      final alreadyExists = currentState.supplier.coverageAreas.any(
        (c) => c.government == selectedGovernment && c.city == selectedCity,
      );

      if (alreadyExists) {
        _showInlineError('مدينة $selectedCity مضافة بالفعل');
        return;
      }

      cubit.addSpecificCity(selectedGovernment!, selectedCity!);
      widget.onSuccess('تمت إضافة $selectedCity ✓');
    }

    setState(() {
      selectedGovernment = null;
      selectedCity = null;
      isFullGovernment = true;
      _errorMessage = null;
    });
  }

  String? _errorMessage;

  void _showInlineError(String message) {
    setState(() => _errorMessage = message);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _errorMessage = null);
      }
    });
  }
}

// كارت المحافظة المحسّن
class _GovernmentCoverageCard extends StatelessWidget {
  final String government;
  final List<CoverageAreaModel> coverages;

  const _GovernmentCoverageCard({
    required this.government,
    required this.coverages,
  });

  @override
  Widget build(BuildContext context) {
    final hasFullGov = coverages.any((c) => c.isFullGovernment);
    final cities = coverages.where((c) => !c.isFullGovernment).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFullGov
              ? Theme.of(context).primaryColor.withOpacity(0.5)
              : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasFullGov
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasFullGov
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasFullGov ? Icons.public : Icons.location_city,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        government,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasFullGov ? 'تغطية كاملة' : '${cities.length} مدن',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasFullGov)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'كاملة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Cities or delete button
          if (hasFullGov)
            _buildDeleteButton(context, coverages.first)
          else
            ..._buildCitiesList(context, cities),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context, CoverageAreaModel coverage) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: OutlinedButton.icon(
        onPressed: () => _confirmDelete(context, coverage),
        icon: const Icon(Icons.delete_outline, size: 18),
        label: const Text('إلغاء التغطية الكاملة'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCitiesList(
      BuildContext context, List<CoverageAreaModel> cities) {
    return cities.map((city) => _buildCityItem(context, city)).toList();
  }

  Widget _buildCityItem(BuildContext context, CoverageAreaModel coverage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              coverage.city!,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: Colors.red,
            onPressed: () => _confirmDelete(context, coverage),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, CoverageAreaModel coverage) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('تأكيد الحذف'),
          ],
        ),
        content: Text(
          'هل تريد حذف "${coverage.fullDisplayName}" من مناطق التغطية؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              context
                  .read<SupplierCoverageCubit>()
                  .removeCoverageArea(coverage);
              Navigator.pop(dialogContext);

              // إظهار toast للحذف
              final overlay = Overlay.of(context);
              late OverlayEntry overlayEntry;

              overlayEntry = OverlayEntry(
                builder: (context) => Positioned(
                  bottom: 100,
                  left: 20,
                  right: 20,
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline,
                              color: Colors.white, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'تم حذف ${coverage.displayName}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              overlay.insert(overlayEntry);
              Future.delayed(const Duration(seconds: 2), () {
                overlayEntry.remove();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
