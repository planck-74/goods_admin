import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/selected_clients_notification_cubit/selected_clients_notification_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/selected_clients_notification_cubit/selected_clients_notification_state.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/data/models/client_model.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';
import 'package:image_picker/image_picker.dart';

class SendToSelectedClientsScreen extends StatefulWidget {
  const SendToSelectedClientsScreen({super.key});

  @override
  State<SendToSelectedClientsScreen> createState() =>
      _SendToSelectedClientsScreenState();
}

class _SendToSelectedClientsScreenState
    extends State<SendToSelectedClientsScreen> with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _linkUrlController = TextEditingController();
  final TextEditingController _linkTextController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _selectedImage;
  bool _includeLinkSection = false;
  NotificationType _selectedType = NotificationType.general;
  NotificationPriority _selectedPriority = NotificationPriority.normal;

  late AnimationController _animationController;
  late AnimationController _linkSectionController;
  late TabController _tabController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _linkSectionAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _linkSectionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));
    _linkSectionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _linkSectionController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    // Load clients when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SelectedClientsCubit>().loadClients();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _linkUrlController.dispose();
    _linkTextController.dispose();
    _searchController.dispose();
    _animationController.dispose();
    _linkSectionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _toggleLinkSection(bool value) {
    setState(() {
      _includeLinkSection = value;
    });

    if (value) {
      _linkSectionController.forward();
    } else {
      _linkSectionController.reverse();
      _linkUrlController.clear();
      _linkTextController.clear();
    }
  }

  Future<void> _pickImage() async {
    final ImageSource? source = await _showImageSourceDialog();
    if (source == null) return;

    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ في اختيار الصورة: ${e.toString()}');
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختيار مصدر الصورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: primaryColor),
              title: const Text('معرض الصور'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: primaryColor),
              title: const Text('الكاميرا'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    final cubit = context.read<SelectedClientsCubit>();
    await cubit.sendNotificationToSelectedClients(
      title: _titleController.text,
      body: _bodyController.text,
      imageFile: _selectedImage,
      linkUrl: _includeLinkSection ? _linkUrlController.text : null,
      linkText: _includeLinkSection ? _linkTextController.text : null,
      notificationType: _selectedType,
      priority: _selectedPriority,
    );
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SelectedClientsCubit, SelectedClientsState>(
      listener: (context, state) {
        if (state is SelectedClientsSent) {
          _showSuccessSnackBar(state.message);
          // Clear form
          _titleController.clear();
          _bodyController.clear();
          _linkUrlController.clear();
          _linkTextController.clear();
          _selectedImage = null;
          _includeLinkSection = false;
          _linkSectionController.reset();
          setState(() {});
        } else if (state is SelectedClientsError) {
          _showErrorSnackBar(state.message);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: customAppBar(
            context,
            Row(
              children: [
                const Icon(Icons.people_outline, color: whiteColor, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'إرسال لعملاء محددين',
                  style: TextStyle(
                    color: whiteColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (state is SelectedClientsLoaded && state.selectedCount > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${state.selectedCount}',
                      style: const TextStyle(
                        color: whiteColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          body: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // Tab Bar
                      Container(
                        color: Colors.white,
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: primaryColor,
                          labelColor: primaryColor,
                          unselectedLabelColor: Colors.grey[600],
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.people, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('اختيار العملاء'),
                                  if (state is SelectedClientsLoaded &&
                                      state.selectedCount > 0)
                                    Container(
                                      margin: const EdgeInsets.only(right: 4),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${state.selectedCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_notifications, size: 20),
                                  SizedBox(width: 8),
                                  Text('كتابة الإشعار'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildClientsSelectionTab(state),
                            _buildNotificationFormTab(state),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildClientsSelectionTab(SelectedClientsState state) {
    if (state is SelectedClientsLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            SizedBox(height: 16),
            Text(
              'جاري تحميل العملاء...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (state is SelectedClientsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[600], fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<SelectedClientsCubit>().loadClients(),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            ),
          ],
        ),
      );
    }

    if (state is SelectedClientsLoaded) {
      return Column(
        children: [
          // Search and filters
          _buildSearchAndFilters(state),
          // Clients list
          Expanded(child: _buildClientsList(state)),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSearchAndFilters(SelectedClientsLoaded state) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search bar
          TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'البحث في اسم المحل، الفئة، المنطقة، الهاتف...',
              prefixIcon: const Icon(Icons.search, color: primaryColor),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<SelectedClientsCubit>().searchClients('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryColor, width: 2),
              ),
            ),
            onChanged: (value) {
              context.read<SelectedClientsCubit>().searchClients(value);
            },
          ),
          const SizedBox(height: 12),

          // Filter chips
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ClientFilter.values.map((filter) {
                      final isSelected = state.currentFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          label: Text(
                            context
                                .read<SelectedClientsCubit>()
                                .getFilterDisplayName(filter),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              context
                                  .read<SelectedClientsCubit>()
                                  .applyFilter(filter);
                            }
                          },
                          selectedColor: primaryColor.withOpacity(0.2),
                          checkmarkColor: primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? primaryColor : Colors.grey[700],
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Category and Government statistics
          if (state.categoryCounts.isNotEmpty ||
              state.governmentCounts.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.categoryCounts.isNotEmpty) ...[
                    const Text(
                      'الفئات:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: state.categoryCounts.entries
                          .take(5)
                          .map((entry) => InkWell(
                                onTap: () => context
                                    .read<SelectedClientsCubit>()
                                    .filterByCategory(entry.key),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${entry.key} (${entry.value})',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (state.governmentCounts.isNotEmpty) ...[
                    const Text(
                      'المحافظات:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: state.governmentCounts.entries
                          .take(5)
                          .map((entry) => InkWell(
                                onTap: () => context
                                    .read<SelectedClientsCubit>()
                                    .filterByGovernment(entry.key),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${entry.key} (${entry.value})',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Selection controls
          Row(
            children: [
              Text(
                'المختار: ${state.selectedCount} من ${state.filteredClients.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const Spacer(),
              if (state.filteredClients.isNotEmpty) ...[
                TextButton.icon(
                  onPressed: () {
                    context.read<SelectedClientsCubit>().selectAllFiltered();
                  },
                  icon: const Icon(Icons.select_all, size: 16),
                  label: const Text('تحديد الكل'),
                  style: TextButton.styleFrom(foregroundColor: primaryColor),
                ),
                const SizedBox(width: 8),
              ],
              if (state.selectedCount > 0)
                TextButton.icon(
                  onPressed: () {
                    context.read<SelectedClientsCubit>().deselectAll();
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('إلغاء التحديد'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientsList(SelectedClientsLoaded state) {
    if (state.filteredClients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              state.searchQuery.isNotEmpty
                  ? 'لا توجد نتائج للبحث "${state.searchQuery}"'
                  : 'لا يوجد عملاء',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.filteredClients.length,
      itemBuilder: (context, index) {
        final client = state.filteredClients[index];
        return _buildClientCard(client);
      },
    );
  }

  Widget _buildClientCard(ClientModel client) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.read<SelectedClientsCubit>().toggleClientSelection(client.id);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: client.isSelected
                ? Border.all(color: primaryColor, width: 2)
                : null,
            color: client.isSelected
                ? primaryColor.withOpacity(0.05)
                : Colors.white,
          ),
          child: Row(
            children: [
              // Selection checkbox
              Checkbox(
                value: client.isSelected,
                onChanged: (value) {
                  context
                      .read<SelectedClientsCubit>()
                      .toggleClientSelection(client.id);
                },
                activeColor: primaryColor,
              ),
              const SizedBox(width: 12),

              // Client image (if available)
              if (client.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    client.imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.store,
                          color: primaryColor,
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Client info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Business name
                    Text(
                      client.businessName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        client.category,
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Phone number
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          client.phoneNumber,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        if (client.secondPhoneNumber?.isNotEmpty == true) ...[
                          const SizedBox(width: 8),
                          const Text(' • '),
                          Text(
                            client.secondPhoneNumber!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            client.locationSummary,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        // Token status
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: client.hasValidTokens
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            client.hasValidTokens
                                ? 'مفعل (${client.tokensCount})'
                                : 'غير مفعل',
                            style: TextStyle(
                              color: client.hasValidTokens
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),

                        // Total devices count
                        if (client.totalDevices > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${client.totalDevices} جهاز',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),

                        // Last active
                        if (client.lastActive != null)
                          Text(
                            _formatLastActive(client.lastActive!),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastActive(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inDays > 30) {
      return 'أكثر من شهر';
    } else if (difference.inDays > 7) {
      return '${difference.inDays} يوم';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعة';
    } else {
      return 'منذ قليل';
    }
  }

  Widget _buildNotificationFormTab(SelectedClientsState state) {
    final selectedCount =
        state is SelectedClientsLoaded ? state.selectedCount : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected clients summary
            if (selectedCount > 0) ...[
              _buildSelectedClientsSummary(selectedCount),
              const SizedBox(height: 24),
            ] else ...[
              _buildNoClientsSelectedCard(),
              const SizedBox(height: 24),
            ],

            // Notification Type & Priority
            _buildTypeAndPrioritySection(),
            const SizedBox(height: 20),

            // Title Field
            _buildTitleField(),
            const SizedBox(height: 20),

            // Body Field
            _buildBodyField(),
            const SizedBox(height: 24),

            // Link Section Toggle
            _buildLinkToggle(),
            const SizedBox(height: 16),

            // Link Section (Animated)
            AnimatedBuilder(
              animation: _linkSectionAnimation,
              builder: (context, child) {
                return SizeTransition(
                  sizeFactor: _linkSectionAnimation,
                  child: FadeTransition(
                    opacity: _linkSectionAnimation,
                    child: _buildLinkSection(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Image Section
            _buildImageSection(),
            const SizedBox(height: 32),

            // Send Button
            _buildSendButton(state, selectedCount),

            // Loading/Status Indicator
            if (state is SelectedClientsSending) ...[
              const SizedBox(height: 20),
              _buildLoadingIndicator(state),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedClientsSummary(int selectedCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.1),
            primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$selectedCount',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'جاهز للإرسال',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'سيتم إرسال الإشعار إلى $selectedCount عميل محدد',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _tabController.animateTo(0),
            icon: const Icon(Icons.edit, color: primaryColor),
            tooltip: 'تعديل الاختيار',
          ),
        ],
      ),
    );
  }

  Widget _buildNoClientsSelectedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_outlined, color: Colors.orange, size: 32),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لم يتم اختيار عملاء',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'يجب اختيار عميل واحد على الأقل لإرسال الإشعار',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _tabController.animateTo(0),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('اختيار العملاء'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeAndPrioritySection() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('نوع الإشعار',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<NotificationType>(
                value: _selectedType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                items: NotificationType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('الأولوية',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<NotificationPriority>(
                value: _selectedPriority,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                items: NotificationPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPriority = value);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('عنوان الإشعار',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          maxLength: 50,
          decoration: InputDecoration(
            hintText: 'أدخل عنوان الإشعار...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال عنوان الإشعار';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBodyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('محتوى الإشعار',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _bodyController,
          maxLines: 4,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: 'أدخل محتوى الإشعار...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال محتوى الإشعار';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLinkToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.link, color: primaryColor),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('إضافة رابط للإشعار',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Switch.adaptive(
            value: _includeLinkSection,
            onChanged: _toggleLinkSection,
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildLinkSection() {
    if (!_includeLinkSection) return const SizedBox.shrink();

    return Column(
      children: [
        TextFormField(
          controller: _linkUrlController,
          decoration: InputDecoration(
            labelText: 'رابط الإشعار',
            hintText: 'https://example.com',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (_includeLinkSection &&
                value != null &&
                value.isNotEmpty &&
                !_isValidUrl(value)) {
              return 'يرجى إدخال رابط صحيح';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _linkTextController,
          decoration: InputDecoration(
            labelText: 'نص الرابط (اختياري)',
            hintText: 'اضغط للفتح',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('صورة الإشعار (اختيارية)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          height: _selectedImage != null ? 200 : 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _selectedImage != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_selectedImage!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 20),
                          onPressed: _removeImage,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _pickImage,
                        ),
                      ),
                    ),
                  ],
                )
              : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickImage,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate,
                            size: 32, color: primaryColor),
                        SizedBox(height: 8),
                        Text('اضغط لاختيار صورة',
                            style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSendButton(SelectedClientsState state, int selectedCount) {
    final bool isDisabled =
        selectedCount == 0 || state is SelectedClientsSending;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isDisabled
            ? LinearGradient(
                colors: [Colors.grey.shade400, Colors.grey.shade300],
              )
            : LinearGradient(
                colors: [
                  primaryColor,
                  _selectedPriority == NotificationPriority.high
                      ? const Color.fromARGB(255, 180, 0, 0)
                      : const Color.fromARGB(255, 138, 12, 12)
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        boxShadow: isDisabled
            ? null
            : [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isDisabled ? null : _sendNotification,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state is SelectedClientsSending) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else ...[
                  Icon(
                    _includeLinkSection &&
                            _linkUrlController.text.trim().isNotEmpty
                        ? Icons.link
                        : Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  isDisabled && selectedCount == 0
                      ? 'اختر العملاء أولاً'
                      : state is SelectedClientsSending
                          ? state.message
                          : 'إرسال الإشعار ($selectedCount عميل)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(SelectedClientsSending state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _selectedPriority == NotificationPriority.high
            ? Colors.orange.shade50
            : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedPriority == NotificationPriority.high
              ? Colors.orange.shade200
              : Colors.blue.shade200,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _selectedPriority == NotificationPriority.high
                    ? Colors.orange
                    : primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.message,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _selectedPriority == NotificationPriority.high
                        ? Colors.orange
                        : primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${_selectedType.displayName} | ${_selectedPriority.displayName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (_selectedPriority == NotificationPriority.high) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.priority_high,
                          size: 14, color: Colors.red),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
