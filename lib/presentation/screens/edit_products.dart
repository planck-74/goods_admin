import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:goods_admin/business%20logic/cubits/firestore_services_cubit/firestore_services_state.dart';
import 'package:goods_admin/presentation/dialogs/batch_edit_dialog.dart';
import 'package:goods_admin/presentation/screens/custom_image_cropper.dart';
import 'package:goods_admin/presentation/sheets/edit_products_sheet.dart';
import 'package:goods_admin/services/storage_services.dart';
import 'package:image/image.dart' as img;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/fetch_products/fetch_products_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/firestore_services_cubit/firestore_services_cubit.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/data/models/product_model.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Future<File> _processImageForTransparency(File imageFile) async {
  try {
    final String extension = imageFile.path.toLowerCase().split('.').last;

    // Skip processing if already PNG - assume it has proper format
    if (extension == 'png') {
      debugPrint("Image is already PNG, skipping processing");
      return imageFile;
    }

    // Only process non-PNG images
    debugPrint("Converting $extension to PNG with transparency support");

    // Read and decode image
    final Uint8List imageBytes = await imageFile.readAsBytes();
    final img.Image? originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) {
      debugPrint("Could not decode image, returning original");
      return imageFile;
    }

    // Use more efficient image processing - avoid pixel-by-pixel operations
    img.Image processedImage;

    if (originalImage.hasAlpha) {
      // Image already has alpha, just re-encode as PNG
      processedImage = originalImage;
    } else {
      // Convert to RGBA format more efficiently using copyResize with same dimensions
      processedImage = img.copyResize(
        originalImage,
        width: originalImage.width,
        height: originalImage.height,
      );
      // This ensures proper RGBA format without pixel-by-pixel operations
    }

    // Encode as PNG
    final List<int> pngBytes =
        img.encodePng(processedImage, level: 6); // Faster compression

    // Create temporary file
    final tempDir = await getTemporaryDirectory();
    final processedFile = File(
        '${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.png');
    await processedFile.writeAsBytes(pngBytes);

    debugPrint("Image processed and saved as PNG");
    return processedFile;
  } catch (e) {
    debugPrint("Error processing image: $e");
    return imageFile; // Return original if processing fails
  }
}

Future<String?> uploadImage(File imageFile, String productId) async {
  try {
    final Future<File> processingFuture =
        _processImageForTransparency(imageFile);

    final storageRef = FirebaseStorage.instance.ref().child(
        'products_images/${productId}_${DateTime.now().millisecondsSinceEpoch}.png');

    final metadata = SettableMetadata(
      contentType: 'image/png',
      customMetadata: {'uploaded_by': 'admin', 'product_id': productId},
      cacheControl: 'public, max-age=31536000', // 1 year cache
    );

    final File processedImage = await processingFuture;

    final UploadTask uploadTask = storageRef.putFile(
      processedImage,
      metadata,
    );

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      debugPrint(
          'Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes * 100).toStringAsFixed(2)}%');
    });

    final TaskSnapshot snapshot = await uploadTask;
    final String downloadUrl = await snapshot.ref.getDownloadURL();

    if (processedImage.path != imageFile.path) {
      try {
        await processedImage.delete();
      } catch (e) {
        debugPrint("Error deleting processed image: $e");
      }
    }

    debugPrint("Upload completed successfully");
    return downloadUrl;
  } catch (e) {
    debugPrint("Error uploading image: $e");
    return null;
  }
}

Future<File?> downloadImageFromUrl(String imageUrl) async {
  try {
    debugPrint("Downloading image from: $imageUrl");

    final response = await http.get(
      Uri.parse(imageUrl),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Android; Mobile)',
        'Accept': 'image/png,image/webp,image/jpeg,image/*;q=0.9,*/*;q=0.8',
        'Connection': 'keep-alive',
      },
    ).timeout(const Duration(seconds: 20)); // Reduced timeout

    debugPrint("HTTP Response status: ${response.statusCode}");
    debugPrint("Response content length: ${response.bodyBytes.length}");

    if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
      final documentDirectory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file =
          File('${documentDirectory.path}/temp_crop_image_$timestamp.png');

      // Skip image processing for downloads - just save as PNG
      // The original format conversion can be handled during upload if needed
      await file.writeAsBytes(response.bodyBytes);

      debugPrint("Image saved to: ${file.path}");
      return file;
    } else {
      debugPrint("Invalid response: status=${response.statusCode}");
      return null;
    }
  } catch (e) {
    debugPrint("Error downloading image: $e");
    return null;
  }
}

Future<File?> pickAndCropImage(BuildContext context) async {
  try {
    // Use lower max dimensions for faster processing while maintaining quality
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800, // Reduced from 1024
      maxHeight: 800, // Reduced from 1024
      imageQuality: 95, // Slightly reduced from 100 for faster processing
      preferredCameraDevice: CameraDevice.rear,
    );

    if (pickedFile == null) return null;

    // Check if we're on Windows, Web, or Linux where image_cropper might not work
    if (Platform.isWindows || Platform.isLinux || kIsWeb) {
      // Use custom cropper
      final croppedFile = await Navigator.of(context).push<File>(
        MaterialPageRoute(
          builder: (context) => CustomImageCropper(
            imageFile: File(pickedFile.path),
            title: 'اقتصاص الصورة',
          ),
        ),
      );
      return croppedFile;
    } else {
      // Use original image_cropper for mobile platforms
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        compressFormat: ImageCompressFormat.png,
        compressQuality: 95,
        maxWidth: 800,
        maxHeight: 800,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'اقتصاص الصورة',
            toolbarColor: primaryColor, // Replace with your primaryColor
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
          ),
          IOSUiSettings(
            title: 'اقتصاص الصورة',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            aspectRatioPickerButtonHidden: false,
            aspectRatioLockDimensionSwapEnabled: true,
          ),
        ],
      );

      return croppedFile != null ? File(croppedFile.path) : null;
    }
  } catch (e) {
    debugPrint("Error picking/cropping image: $e");
    return null;
  }
}

Future<File?> cropExistingImage(BuildContext context, String imageUrl) async {
  try {
    debugPrint("Starting crop process for URL: $imageUrl");

    // Show loading with timeout
    bool loadingShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Download with timeout
    final imageFile = await downloadImageFromUrl(imageUrl)
        .timeout(const Duration(seconds: 20));

    // Hide loading
    if (context.mounted && loadingShowing) {
      Navigator.of(context).pop();
      loadingShowing = false;
    }

    if (imageFile == null) {
      debugPrint("Failed to download image file");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في تحميل الصورة للتعديل'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    debugPrint("Image downloaded successfully, starting cropper...");

    File? croppedFile;

    // Check platform and use appropriate cropper
    if (Platform.isWindows || Platform.isLinux || kIsWeb) {
      // Use custom cropper for Windows/Linux/Web
      croppedFile = await Navigator.of(context).push<File>(
        MaterialPageRoute(
          builder: (context) => CustomImageCropper(
            imageFile: imageFile,
            title: 'اقتصاص الصورة الحالية',
          ),
        ),
      );
    } else {
      // Use original image_cropper for mobile platforms
      final croppedResult = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressFormat: ImageCompressFormat.png,
        compressQuality: 95,
        maxWidth: 800,
        maxHeight: 800,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'اقتصاص الصورة الحالية',
            toolbarColor: primaryColor, // Replace with primaryColor
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            activeControlsWidgetColor:
                primaryColor, // Replace with primaryColor
            backgroundColor: Colors.white,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
          ),
          IOSUiSettings(
            title: 'اقتصاص الصورة الحالية',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            aspectRatioPickerButtonHidden: false,
            aspectRatioLockDimensionSwapEnabled: true,
          ),
        ],
      );

      croppedFile = croppedResult != null ? File(croppedResult.path) : null;
    }

    // Clean up downloaded file
    try {
      await imageFile.delete();
    } catch (e) {
      debugPrint("Error deleting temp file: $e");
    }

    return croppedFile;
  } catch (e) {
    debugPrint("Error in cropExistingImage: $e");

    if (context.mounted) {
      try {
        Navigator.of(context).pop(); // Close any open dialogs
      } catch (navError) {
        debugPrint("Error closing dialog: $navError");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء اقتصاص الصورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return null;
  }
}

/// Show image options dialog
Future<void> showImageOptionsDialog(BuildContext context,
    String currentImageUrl, Function(File?) onImageSelected) async {
  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('خيارات الصورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('اختيار صورة جديدة'),
              onTap: () async {
                // Close dialog first
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }

                try {
                  // Use the original context for image picking
                  final imageFile = await pickAndCropImage(context);
                  if (imageFile != null) {
                    onImageSelected(imageFile);
                  }
                } catch (e) {
                  debugPrint("Error picking new image: $e");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('حدث خطأ في اختيار الصورة: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            if (currentImageUrl.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.crop),
                title: const Text('اقتصاص الصورة الحالية'),
                onTap: () async {
                  // Close dialog first
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }

                  try {
                    debugPrint("Starting crop process from dialog...");
                    // Use the original context for cropping
                    final croppedFile =
                        await cropExistingImage(context, currentImageUrl);
                    if (croppedFile != null) {
                      debugPrint("Crop successful, calling onImageSelected");
                      onImageSelected(croppedFile);
                    } else {
                      debugPrint("Crop returned null");
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم إلغاء اقتصاص الصورة'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    debugPrint("Error in crop process: $e");
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('حدث خطأ في اقتصاص الصورة: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('إلغاء'),
          ),
        ],
      );
    },
  );
}

// Keep all image processing functions as they are...
// [Previous image processing functions remain unchanged]

class EditProducts extends StatefulWidget {
  const EditProducts({super.key});

  @override
  State<EditProducts> createState() => _EditProductsState();
}

class _EditProductsState extends State<EditProducts> {
  final TextEditingController _searchController = TextEditingController();
  List<Product>? _searchResults;
  bool _isSearching = false;
  bool _isBatchMode = false;
  Set<String> _selectedProductIds = <String>{};
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    final fetchCubit = context.read<FetchProductsCubit>();
    if (fetchCubit.cachedProducts.isEmpty) {
      fetchCubit.fetchProducts();
    }
  }

  void _toggleBatchMode() {
    setState(() {
      _isBatchMode = !_isBatchMode;
      _selectedProductIds.clear();
    });
  }

  void _selectAllProducts(List<Product> products) {
    setState(() {
      if (_selectedProductIds.length == products.length) {
        _selectedProductIds.clear();
      } else {
        _selectedProductIds = products.map((p) => p.productId).toSet();
      }
    });
  }

  void _showBatchEditDialog(List<Product> allProducts) {
    final selectedProducts = allProducts
        .where((p) => _selectedProductIds.contains(p.productId))
        .toList();

    showDialog(
      context: context,
      builder: (context) => BatchEditDialog(
        products: selectedProducts,
        onComplete: () {
          setState(() {
            _selectedProductIds.clear();
            _isBatchMode = false;
          });
          _refreshSearchResults(forceRefetch: false);
        },
      ),
    );
  }

  Future<void> _showMultipleCropDialog() async {
    if (_selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار منتجات للتعديل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final allProducts = _searchResults ??
        (context.read<FetchProductsCubit>().state is FetchProductsLoaded
            ? (context.read<FetchProductsCubit>().state as FetchProductsLoaded)
                .products
            : <Product>[]);

    final selectedProducts = allProducts
        .where((p) =>
            _selectedProductIds.contains(p.productId) && p.imageUrl.isNotEmpty)
        .toList();

    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد منتجات محددة تحتوي على صور'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => MultipleCropDialog(
        products: selectedProducts,
        onComplete: () {
          setState(() {
            _selectedProductIds.clear();
            _isBatchMode = false;
          });
          _refreshSearchResults(forceRefetch: false);
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _searchController,
        cursorHeight: 25,
        style: const TextStyle(fontSize: 16),
        decoration: const InputDecoration(
          hintText: 'ابحث عن منتج',
          hintStyle: TextStyle(color: darkBlueColor, fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          prefixIcon: Icon(Icons.search, size: 20),
        ),
        onChanged: _searchProducts,
      ),
    );
  }

  Widget _buildBatchModeHeader(List<Product> products) {
    if (!_isBatchMode) return const SizedBox.shrink();

    final productsWithImages = products
        .where((p) =>
            _selectedProductIds.contains(p.productId) && p.imageUrl.isNotEmpty)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.1),
            primaryColor.withOpacity(0.05)
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(color: primaryColor.withOpacity(0.3)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_selectedProductIds.length} محدد',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'من ${products.length}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _selectAllProducts(products),
                icon: Icon(
                  _selectedProductIds.length == products.length
                      ? Icons.deselect
                      : Icons.select_all,
                  size: 18,
                ),
                label: Text(
                  _selectedProductIds.length == products.length
                      ? 'إلغاء الكل'
                      : 'اختيار الكل',
                ),
              ),
            ],
          ),
          if (_selectedProductIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showBatchEditDialog(products),
                    icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                    label: const Text(
                      'تعديل البيانات',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        productsWithImages > 0 ? _showMultipleCropDialog : null,
                    icon: const Icon(Icons.crop, color: Colors.white, size: 18),
                    label: Text(
                      'اقتصاص ($productsWithImages)',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          productsWithImages > 0 ? Colors.green : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
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

  Future<void> deleteOldImage(String imageUrl) async {
    if (imageUrl.isEmpty) return;

    try {
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete().timeout(const Duration(seconds: 10));
      debugPrint("Old image deleted successfully");
    } catch (e) {
      debugPrint("Error deleting old image: $e");
    }
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final fetchCubit = context.read<FetchProductsCubit>();
    final results = fetchCubit.searchInCachedProducts(query);

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  Future<void> _refreshSearchResults({bool forceRefetch = false}) async {
    if (forceRefetch) {
      await context.read<FetchProductsCubit>().fetchProducts();
    }

    if (_searchController.text.isNotEmpty) {
      await _searchProducts(_searchController.text);
    }
  }

  Future<void> _updateProductImage(Product product, File newImage) async {
    bool loadingShowing = false;

    try {
      setState(() => _isSyncing = true);

      loadingShowing = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (loadingContext) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: const Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  'جاري رفع الصورة...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );

      String? newImageUrl = await uploadImage(newImage, product.productId);

      if (newImageUrl != null) {
        if (product.imageUrl.isNotEmpty) {
          await deleteOldImage(product.imageUrl);
        }

        Product updatedProduct = Product(
          name: product.name,
          manufacturer: product.manufacturer,
          size: product.size,
          package: product.package,
          classification: product.classification,
          note: product.note,
          salesCount: product.salesCount,
          imageUrl: newImageUrl,
          productId: product.productId,
        );

        if (context.mounted) {
          // Close upload dialog
          Navigator.of(context).pop();
          loadingShowing = false;

          // Update product (this will show sync dialog automatically)
          await context.read<FirestoreServicesCubit>().updateProduct(context,
              updatedProduct, FetchProductsCubit as FetchProductsCubit);
        }

        if (_searchResults != null) {
          setState(() {
            _searchResults = _searchResults!.map((p) {
              if (p.productId == product.productId) {
                return updatedProduct;
              }
              return p;
            }).toList();
          });
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل في رفع الصورة'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error updating image: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
      if (loadingShowing && context.mounted) {
        try {
          Navigator.of(context).pop();
        } catch (e) {
          debugPrint("Error closing loading dialog: $e");
        }
      }
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('تأكيد الحذف'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من حذف المنتج:'),
            const SizedBox(height: 8),
            Text(
              '"${product.name}"',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'لن يتم حذف المنتج من المتاجر تلقائياً',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();

              await context
                  .read<FirestoreServicesCubit>()
                  .deleteProduct(context, product);

              if (_searchResults != null) {
                setState(() {
                  _searchResults = _searchResults!
                      .where((p) => p.productId != product.productId)
                      .toList();
                });
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم حذف "${product.name}" بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withOpacity(0.1) : whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: primaryColor, width: 2)
            : Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          if (_isBatchMode)
            Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleProductSelection(product.productId),
              activeColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          GestureDetector(
            onTap: () async {
              if (!_isBatchMode && context.mounted) {
                await showImageOptionsDialog(context, product.imageUrl,
                    (File? newImage) async {
                  if (newImage != null && context.mounted) {
                    await _updateProductImage(product, newImage);
                  }
                  ;
                });
              }
            },
            child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[100],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported,
                        color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildProductDetails(product)),
          if (!_isBatchMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _showDeleteConfirmationDialog(context, product),
              tooltip: 'حذف المنتج',
            ),
        ],
      ),
    );
  }

  Widget _buildProductDetails(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        _buildDetailRow(Icons.business, product.manufacturer),
        if (product.size?.isNotEmpty ?? false)
          _buildDetailRow(Icons.straighten, product.size!),
        _buildDetailRow(Icons.inventory_2_outlined, product.package),
        _buildDetailRow(Icons.category_outlined, product.classification),
        _buildDetailRow(
            Icons.trending_up, '${product.salesCount} مبيعة', Colors.green),
        if (product.note?.isNotEmpty ?? false)
          _buildDetailRow(Icons.notes, product.note!, Colors.orange),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String text, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color ?? Colors.grey[600]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: color ?? Colors.grey[800]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<Product> products) {
    return Column(
      children: [
        _buildBatchModeHeader(products),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: products.length,
            itemBuilder: (context, index) {
              Product product = products[index];
              bool isSelected = _selectedProductIds.contains(product.productId);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    if (_isBatchMode) {
                      _toggleProductSelection(product.productId);
                    } else {
                      showEditProductSheet(context, product);
                    }
                  },
                  child: _buildProductCard(product, isSelected),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        context,
        Row(
          children: [
            const Text('المنتجات', style: TextStyle(color: whiteColor)),
            const SizedBox(width: 10),
            Expanded(child: _buildSearchField()),
            IconButton(
              icon: Icon(
                _isBatchMode ? Icons.close : Icons.checklist,
                color: whiteColor,
              ),
              onPressed: _toggleBatchMode,
              tooltip: _isBatchMode ? 'إلغاء التحديد' : 'تحديد متعدد',
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _searchResults != null
                  ? RefreshIndicator(
                      onRefresh: () =>
                          _refreshSearchResults(forceRefetch: true),
                      child: _buildProductList(_searchResults!),
                    )
                  : BlocBuilder<FetchProductsCubit, FetchProductsState>(
                      builder: (context, state) {
                        if (state is FetchProductsLoading) {
                          return const Center(
                            child:
                                CircularProgressIndicator(color: primaryColor),
                          );
                        } else if (state is FetchProductsLoaded) {
                          return RefreshIndicator(
                            onRefresh: () =>
                                _refreshSearchResults(forceRefetch: true),
                            child: _buildProductList(state.products),
                          );
                        } else if (state is FetchProductsError) {
                          return Center(child: Text(state.message));
                        }
                        return const SizedBox();
                      },
                    ),
          if (_isSyncing)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          BlocBuilder<FirestoreServicesCubit, FirestoreServicesState>(
            builder: (context, state) {
              if (state is FirestoreServicesLoading) {
                return Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Card(
                      margin: EdgeInsets.all(20),
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'جاري التحديث والمزامنة...',
                              style: TextStyle(
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
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Keep all other classes and functions (MultipleCropDialog, etc.) as they were...
// Keep all other classes and functions (MultipleCropDialog, etc.) as they were...
class MultipleCropDialog extends StatefulWidget {
  final List<Product> products;
  final VoidCallback onComplete;

  const MultipleCropDialog({
    super.key,
    required this.products,
    required this.onComplete,
  });

  @override
  State<MultipleCropDialog> createState() => _MultipleCropDialogState();
}

class _MultipleCropDialogState extends State<MultipleCropDialog> {
  List<Product> _remainingProducts = [];
  final List<Product> _processedProducts = [];
  bool _isProcessing = false;
  int _currentIndex = 0;
  String _currentStatus = '';

  @override
  void initState() {
    super.initState();
    _remainingProducts = List.from(widget.products);
  }

  Future<void> _startBatchCropping() async {
    setState(() {
      _isProcessing = true;
      _currentIndex = 0;
    });

    for (int i = 0; i < _remainingProducts.length; i++) {
      if (!mounted) break;

      setState(() {
        _currentIndex = i;
        _currentStatus =
            'معالجة ${_remainingProducts[i].name}... (${i + 1}/${_remainingProducts.length})';
      });

      await _processSingleProduct(_remainingProducts[i]);

      // Add small delay to show progress
      await Future.delayed(const Duration(milliseconds: 500));
    }

    setState(() {
      _isProcessing = false;
      _currentStatus = 'تم الانتهاء من معالجة جميع الصور';
    });

    // Auto close after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onComplete();
      }
    });
  }

  Future<void> _processSingleProduct(Product product) async {
    try {
      // Download and crop the image
      final croppedFile = await cropExistingImage(context, product.imageUrl);

      if (croppedFile != null) {
        // Upload the new cropped image
        String? newImageUrl = await uploadImage(croppedFile, product.productId);

        if (newImageUrl != null) {
          // Delete old image
          if (product.imageUrl.isNotEmpty) {
            await StorageService().deleteOldImage(product.imageUrl);
          }

          // Update product in Firestore
          await FirebaseFirestore.instance
              .collection('products')
              .doc(product.productId)
              .update({'imageUrl': newImageUrl});
          syncStoreProductsByIds(context, storeId, [product.productId]);

          setState(() {
            _processedProducts.add(product);
          });
        }
      }
    } catch (e) {
      debugPrint("Error processing ${product.name}: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('اقتصاص متعدد (${widget.products.length} صورة)'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Column(
          children: [
            if (!_isProcessing) ...[
              const Text('سيتم اقتصاص جميع الصور المحددة واحدة تلو الأخرى'),
              const SizedBox(height: 16),
              Text('عدد الصور: ${widget.products.length}'),
              const SizedBox(height: 8),
              const Text(
                'ملاحظة: ستحتاج للموافقة على كل عملية اقتصاص',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ] else ...[
              Text(_currentStatus),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _remainingProducts.isNotEmpty
                    ? (_currentIndex + 1) / _remainingProducts.length
                    : 1.0,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
              ),
              const SizedBox(height: 8),
              Text('${_currentIndex + 1} من ${_remainingProducts.length}'),
              const SizedBox(height: 16),
              Text('تم المعالجة: ${_processedProducts.length}'),
            ],
            const Spacer(),
            Expanded(
              child: ListView.builder(
                itemCount: widget.products.length,
                itemBuilder: (context, index) {
                  final product = widget.products[index];
                  final isProcessed = _processedProducts.contains(product);
                  final isCurrent = _isProcessing && _currentIndex == index;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isProcessed
                          ? Colors.green
                          : isCurrent
                              ? primaryColor
                              : Colors.grey,
                      child: Icon(
                        isProcessed
                            ? Icons.check
                            : isCurrent
                                ? Icons.crop
                                : Icons.image,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    title: Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: isProcessed ? Colors.green : null,
                      ),
                    ),
                    trailing: isProcessed
                        ? const Icon(Icons.done, color: Colors.green, size: 16)
                        : isCurrent
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (!_isProcessing) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _startBatchCropping,
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('بدء الاقتصاص',
                style: TextStyle(color: Colors.white)),
          ),
        ] else ...[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onComplete();
            },
            child: const Text('إغلاق'),
          ),
        ],
      ],
    );
  }
}

Future<File?> cropExistingImageForBatch(
    BuildContext context, String imageUrl, String productName) async {
  try {
    debugPrint("Starting crop process for: $productName");

    // Download image
    final imageFile = await downloadImageFromUrl(imageUrl)
        .timeout(const Duration(seconds: 15));

    if (imageFile == null) {
      debugPrint("Failed to download image file for $productName");
      return null;
    }

    debugPrint("Image downloaded for $productName, starting cropper...");

    File? croppedFile;

    // Check platform and use appropriate cropper
    if (Platform.isWindows || Platform.isLinux || kIsWeb) {
      // Use custom cropper for Windows/Linux/Web
      croppedFile = await Navigator.of(context).push<File>(
        MaterialPageRoute(
          builder: (context) => CustomImageCropper(
            imageFile: imageFile,
            title: 'اقتصاص: $productName',
          ),
        ),
      );
    } else {
      // Use original image_cropper for mobile platforms
      final croppedResult = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressFormat: ImageCompressFormat.png,
        compressQuality: 95,
        maxWidth: 800,
        maxHeight: 800,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'اقتصاص: $productName',
            toolbarColor: primaryColor, // Replace with primaryColor
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            activeControlsWidgetColor:
                primaryColor, // Replace with primaryColor
            backgroundColor: Colors.white,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
          ),
          IOSUiSettings(
            title: 'اقتصاص: $productName',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            aspectRatioPickerButtonHidden: false,
            aspectRatioLockDimensionSwapEnabled: true,
          ),
        ],
      );

      croppedFile = croppedResult != null ? File(croppedResult.path) : null;
    }

    // Clean up
    try {
      await imageFile.delete();
    } catch (e) {
      debugPrint("Error deleting temp file: $e");
    }

    return croppedFile;
  } catch (e) {
    debugPrint("Error in cropExistingImageForBatch for $productName: $e");
    return null;
  }
}

Future<void> syncStoreProductsByIds(
  BuildContext context,
  String storeId,
  List<String> productDocIds,
) async {
  try {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    WriteBatch batch = firestore.batch();
    int updatedCount = 0;

    for (String storeProductId in productDocIds) {
      final storeDocRef = firestore
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .doc(storeProductId);

      final storeDoc = await storeDocRef.get();

      if (!storeDoc.exists) {
        continue;
      }

      final storeProduct = storeDoc.data()!;
      final mainProductId = storeProduct['productId'];

      final mainProductDoc =
          await firestore.collection('products').doc(mainProductId).get();

      if (mainProductDoc.exists) {
        final mainProduct = mainProductDoc.data()!;

        final updatedData = {
          ...storeProduct,
          'name': mainProduct['name'],
          'classification': mainProduct['classification'],
          'imageUrl': mainProduct['imageUrl'],
          'manufacturer': mainProduct['manufacturer'],
          'size': mainProduct['size'],
          'package': mainProduct['package'],
          'note': mainProduct['note'],
        };

        batch.update(storeDocRef, updatedData);
        updatedCount++;
      } else {}
    }

    await batch.commit();
  } catch (e) {}
}
