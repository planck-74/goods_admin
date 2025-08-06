import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/batch_operation/batch_operations_cubit.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/data/models/product_model.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';

class AdvancedBatchEditScreen extends StatefulWidget {
  final List<Product> selectedProducts;

  const AdvancedBatchEditScreen({
    super.key,
    required this.selectedProducts,
  });

  @override
  State<AdvancedBatchEditScreen> createState() =>
      _AdvancedBatchEditScreenState();
}

class _AdvancedBatchEditScreenState extends State<AdvancedBatchEditScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _manufacturerController = TextEditingController();
  final TextEditingController _classificationController =
      TextEditingController();
  final TextEditingController _packageController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final TextEditingController _salesIncrementController =
      TextEditingController();
  final TextEditingController _duplicateSuffixController =
      TextEditingController();

  bool _updateManufacturer = false;
  bool _updateClassification = false;
  bool _updatePackage = false;
  bool _updateSize = false;
  bool _updateNote = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _generateStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _manufacturerController.dispose();
    _classificationController.dispose();
    _packageController.dispose();
    _sizeController.dispose();
    _noteController.dispose();
    _salesIncrementController.dispose();
    _duplicateSuffixController.dispose();
    super.dispose();
  }

  void _generateStatistics() {
    context.read<BatchOperationsCubit>().getProductsStatistics(
          products: widget.selectedProducts,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        context,
        Text(
          'تعديل مجمع (${widget.selectedProducts.length} منتج)',
          style: const TextStyle(color: whiteColor),
        ),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryColor,
            tabs: const [
              Tab(text: 'تعديل أساسي', icon: Icon(Icons.edit)),
              Tab(text: 'عمليات متقدمة', icon: Icon(Icons.settings)),
              Tab(text: 'إحصائيات', icon: Icon(Icons.analytics)),
              Tab(text: 'أدوات أخرى', icon: Icon(Icons.build)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicEditTab(),
                _buildAdvancedOperationsTab(),
                _buildStatisticsTab(),
                _buildToolsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicEditTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'التحديث الأساسي للحقول',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFieldUpdateCard(
            'الشركة المصنعة',
            _manufacturerController,
            _updateManufacturer,
            (value) => setState(() => _updateManufacturer = value ?? false),
            icon: Icons.business,
          ),
          _buildFieldUpdateCard(
            'التصنيف',
            _classificationController,
            _updateClassification,
            (value) => setState(() => _updateClassification = value ?? false),
            icon: Icons.category,
          ),
          _buildFieldUpdateCard(
            'العبوة',
            _packageController,
            _updatePackage,
            (value) => setState(() => _updatePackage = value ?? false),
            icon: Icons.inventory,
          ),
          _buildFieldUpdateCard(
            'الحجم',
            _sizeController,
            _updateSize,
            (value) => setState(() => _updateSize = value ?? false),
            icon: Icons.straighten,
          ),
          _buildFieldUpdateCard(
            'ملاحظات',
            _noteController,
            _updateNote,
            (value) => setState(() => _updateNote = value ?? false),
            icon: Icons.note,
          ),
          const SizedBox(height: 24),
          BlocConsumer<BatchOperationsCubit, BatchOperationsState>(
            listener: (context, state) {
              if (state is BatchOperationsSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop(true);
              } else if (state is BatchOperationsError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: state is BatchOperationsLoading
                      ? null
                      : _performBasicUpdate,
                  child: state is BatchOperationsLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'تطبيق التحديثات',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedOperationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'العمليات المتقدمة',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildOperationCard(
            'تصفير عدد المبيعات',
            'إعادة تعيين عدد المبيعات لجميع المنتجات المحددة إلى صفر',
            Icons.refresh,
            Colors.orange,
            () => _showConfirmationDialog(
              'تصفير المبيعات',
              'هل أنت متأكد من تصفير عدد المبيعات لجميع المنتجات المحددة؟',
              () => _resetSalesCount(),
            ),
          ),
          _buildOperationCard(
            'زيادة عدد المبيعات',
            'إضافة قيمة محددة لعدد المبيعات',
            Icons.add,
            Colors.green,
            () => _showIncrementSalesDialog(),
          ),
          _buildOperationCard(
            'نسخ المنتجات',
            'إنشاء نسخ من المنتجات المحددة مع تعديل الأسماء',
            Icons.copy,
            Colors.blue,
            () => _showDuplicateDialog(),
          ),
          _buildOperationCard(
            'حذف جميع المنتجات',
            'حذف جميع المنتجات المحددة نهائياً',
            Icons.delete_forever,
            Colors.red,
            () => _showConfirmationDialog(
              'حذف المنتجات',
              'هل أنت متأكد من حذف جميع المنتجات المحددة؟ هذا الإجراء لا يمكن التراجع عنه!',
              () => _deleteAllProducts(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return BlocBuilder<BatchOperationsCubit, BatchOperationsState>(
      builder: (context, state) {
        if (state is BatchOperationsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is BatchOperationsStatistics) {
          return _buildStatisticsContent(state.statistics);
        }
        return const Center(child: Text('لا توجد إحصائيات متاحة'));
      },
    );
  }

  Widget _buildStatisticsContent(Map<String, dynamic> stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إحصائيات المنتجات المحددة',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildStatCard(
              'إجمالي المنتجات', '${stats['totalProducts']}', Icons.inventory),
          _buildStatCard(
              'إجمالي المبيعات', '${stats['totalSales']}', Icons.sell),
          _buildStatCard(
              'متوسط المبيعات',
              (stats['averageSales'] as double).toStringAsFixed(1),
              Icons.trending_up),
          const SizedBox(height: 16),
          const Text('التصنيفات:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          _buildChipList(stats['classifications'] as Set<String>),
          const SizedBox(height: 16),
          const Text('الشركات المصنعة:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          _buildChipList(stats['manufacturers'] as Set<String>),
          const SizedBox(height: 16),
          const Text('أنواع العبوات:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          _buildChipList(stats['packages'] as Set<String>),
        ],
      ),
    );
  }

  Widget _buildToolsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'أدوات إضافية',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildOperationCard(
            'تصدير البيانات',
            'تصدير بيانات المنتجات المحددة كملف JSON',
            Icons.download,
            Colors.teal,
            () => _exportData(),
          ),
          _buildOperationCard(
            'إنشاء تقرير',
            'إنشاء تقرير مفصل عن المنتجات المحددة',
            Icons.assessment,
            Colors.purple,
            () => _generateReport(),
          ),
          _buildOperationCard(
            'مشاركة قائمة المنتجات',
            'إنشاء رابط لمشاركة قائمة المنتجات',
            Icons.share,
            Colors.indigo,
            () => _shareProductList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldUpdateCard(
    String label,
    TextEditingController controller,
    bool isEnabled,
    Function(bool?) onChanged, {
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: isEnabled,
                        onChanged: onChanged,
                        activeColor: primaryColor,
                      ),
                      Text(label,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  TextField(
                    controller: controller,
                    enabled: isEnabled,
                    decoration: InputDecoration(
                      hintText: 'أدخل $label الجديد',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: primaryColor),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildChipList(Set<String> items) {
    if (items.isEmpty) {
      return const Text('لا توجد بيانات', style: TextStyle(color: Colors.grey));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: items
          .map((item) => Chip(
                label: Text(item),
                backgroundColor: primaryColor.withOpacity(0.1),
              ))
          .toList(),
    );
  }

  void _performBasicUpdate() {
    Map<String, dynamic> updates = {};

    if (_updateManufacturer && _manufacturerController.text.isNotEmpty) {
      updates['manufacturer'] = _manufacturerController.text;
    }
    if (_updateClassification && _classificationController.text.isNotEmpty) {
      updates['classification'] = _classificationController.text;
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

    if (updates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار حقل واحد على الأقل للتحديث'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.read<BatchOperationsCubit>().batchUpdateProducts(
          products: widget.selectedProducts,
          updates: updates,
          context: context,
        );
  }

  void _resetSalesCount() {
    context.read<BatchOperationsCubit>().resetFieldForProducts(
          products: widget.selectedProducts,
          fieldName: 'salesCount',
          resetValue: 0,
          context: context,
        );
  }

  void _deleteAllProducts() {
    context.read<BatchOperationsCubit>().batchDeleteProducts(
          products: widget.selectedProducts,
          context: context,
        );
  }

  void _exportData() {
    context.read<BatchOperationsCubit>().exportProductsData(
          products: widget.selectedProducts,
          context: context,
        );
  }

  void _showConfirmationDialog(
      String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تأكيد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showIncrementSalesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('زيادة عدد المبيعات'),
        content: TextField(
          controller: _salesIncrementController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'القيمة المراد إضافتها',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final increment =
                  int.tryParse(_salesIncrementController.text) ?? 0;
              if (increment > 0) {
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم زيادة المبيعات بـ $increment')),
                );
              }
            },
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  void _showDuplicateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نسخ المنتجات'),
        content: TextField(
          controller: _duplicateSuffixController,
          decoration: const InputDecoration(
            labelText: 'النص المراد إضافته للاسم',
            hintText: 'مثال: - نسخة',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_duplicateSuffixController.text.isNotEmpty) {
                Navigator.of(context).pop();
                context.read<BatchOperationsCubit>().duplicateProducts(
                      products: widget.selectedProducts,
                      nameSuffix: _duplicateSuffixController.text,
                      context: context,
                    );
              }
            },
            child: const Text('نسخ'),
          ),
        ],
      ),
    );
  }

  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري إنشاء التقرير...')),
    );
  }

  void _shareProductList() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري إنشاء رابط المشاركة...')),
    );
  }
}
