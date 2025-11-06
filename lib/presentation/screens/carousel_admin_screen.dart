import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/carousel_cubit/carousel_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/carousel_cubit/carousel_state.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/data/models/carousel_image_model.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';

class CarouselAdminScreen extends StatelessWidget {
  const CarouselAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: customAppBar(
        context,
        const Text(
          'إدارة المجلة',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: BlocListener<CarouselCubit, CarouselState>(
        listener: (context, state) {
          if (state is CarouselUploadSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text('تم رفع الصورة بنجاح'),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          } else if (state is CarouselUploadError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        child: Column(
          children: [
            _buildHeaderSection(context),
            Expanded(
              child: BlocBuilder<CarouselCubit, CarouselState>(
                builder: (context, state) {
                  if (state is CarouselUploading) {
                    return _buildUploadingState();
                  }

                  if (state is CarouselLoaded) {
                    if (state.images.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return _buildImagesList(context, state.images);
                  }

                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () => _handleUpload(context),
            icon: const Icon(Icons.add_photo_alternate, size: 20),
            label: const Text(
              'رفع صورة جديدة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'اسحب وأفلت الصور لإعادة ترتيبها',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 3),
          const SizedBox(height: 20),
          Text(
            'جارٍ رفع الصورة...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد صور مرفوعة حتى الآن',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة صور لعرضها في المجلة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesList(
      BuildContext context, List<CarouselImageModel> images) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: images.length,
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final updatedImages = List<CarouselImageModel>.from(images);
        final item = updatedImages.removeAt(oldIndex);
        updatedImages.insert(newIndex, item);

        context.read<CarouselCubit>().reorderImages(updatedImages);
      },
      itemBuilder: (context, index) {
        final image = images[index];
        return _buildImageCard(context, image, index);
      },
    );
  }

  Widget _buildImageCard(
      BuildContext context, CarouselImageModel image, int index) {
    return Card(
      key: ValueKey(image.id),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: image.isActive
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: image.isActive ? Colors.white : Colors.grey[100],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: image.imageUrl,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 180,
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  if (!image.isActive)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Icon(
                            Icons.visibility_off,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.reorder,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'ترتيب ${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Controls Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Status Toggle
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: image.isActive
                            ? Colors.green[50]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            image.isActive
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 18,
                            color: image.isActive
                                ? Colors.green
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            image.isActive ? 'نشط' : 'معطل',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: image.isActive
                                  ? Colors.green
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Toggle Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _toggleImageStatus(context, image),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          image.isActive ? Icons.toggle_on : Icons.toggle_off,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Delete Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          _showDeleteDialog(context, image.id, image.imageUrl),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Date Info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'تم الرفع: ${_formatDate(image.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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

  void _handleUpload(BuildContext context) {
    context.read<CarouselCubit>().uploadImage();
  }

  void _toggleImageStatus(BuildContext context, CarouselImageModel image) {
    context.read<CarouselCubit>().toggleImageStatus(image.id, image.isActive);
  }

  void _showDeleteDialog(
      BuildContext context, String imageId, String imageUrl) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('حذف الصورة'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذه الصورة؟ لا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'إلغاء',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<CarouselCubit>().deleteImage(imageId, imageUrl);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'إبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
