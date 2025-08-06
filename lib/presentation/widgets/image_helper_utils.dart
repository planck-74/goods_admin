import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';

class ImageHelperUtils {
  static final ImagePicker _picker = ImagePicker();

  static const int _defaultMaxWidth = 1024;
  static const int _defaultMaxHeight = 1024;
  static const int _defaultQuality = 85;
  static const int _thumbnailSize = 200;
  static const int _tempFileCleanupHours = 1;

  static Future<File?> pickImage({
    required BuildContext context,
    ImageSource? source,
    bool allowCropping = true,
    bool compressImage = true,
    int maxWidth = _defaultMaxWidth,
    int maxHeight = _defaultMaxHeight,
    int quality = _defaultQuality,
  }) async {
    try {
      if (quality < 0 || quality > 100) {
        throw ArgumentError('Quality must be between 0 and 100');
      }
      if (maxWidth <= 0 || maxHeight <= 0) {
        throw ArgumentError('Width and height must be positive');
      }

      final selectedSource =
          source ?? await _showSourceSelectionDialog(context);

      final XFile? pickedFile = await _picker.pickImage(
        source: selectedSource,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
      );

      if (pickedFile == null) return null;

      File imageFile = File(pickedFile.path);

      if (!await _isValidImageFile(imageFile)) {
        _showErrorSnackBar(context, 'نوع الملف غير مدعوم');
        return null;
      }

      if (allowCropping) {
        final croppedFile = await _cropImage(pickedFile.path, context);
        if (croppedFile != null) {
          imageFile = File(croppedFile.path);
        }
      }

      if (compressImage) {
        imageFile = await _compressImage(imageFile);
      }

      return imageFile;
    } on PlatformException catch (e) {
      debugPrint('Platform error picking image: $e');
      _showErrorSnackBar(context, 'خطأ في الوصول للكاميرا أو المعرض');
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showErrorSnackBar(context, 'خطأ في اختيار الصورة');
      return null;
    }
  }

  static Future<ImageSource> _showSourceSelectionDialog(
      BuildContext context) async {
    ImageSource? selectedSource;

    await showDialog<ImageSource>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('اختر مصدر الصورة'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt,
                  title: 'الكاميرا',
                  onTap: () {
                    selectedSource = ImageSource.camera;
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 8),
                _buildSourceOption(
                  icon: Icons.photo_library,
                  title: 'المعرض',
                  onTap: () {
                    selectedSource = ImageSource.gallery;
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        );
      },
    );

    return selectedSource ?? ImageSource.gallery;
  }

  static Widget _buildSourceOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: primaryColor, size: 24),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<CroppedFile?> _cropImage(
      String sourcePath, BuildContext context) async {
    try {
      return await ImageCropper().cropImage(
        sourcePath: sourcePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        maxWidth: _defaultMaxWidth,
        maxHeight: _defaultMaxHeight,
        compressFormat: ImageCompressFormat.png,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'اقتصاص الصورة',
            toolbarColor: primaryColor,
            toolbarWidgetColor: Colors.white,
            backgroundColor: Colors.white,
            activeControlsWidgetColor: primaryColor,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            statusBarColor: kDarkBlueColor,
            cropGridColor: primaryColor.withOpacity(0.5),
            cropFrameColor: primaryColor,
            showCropGrid: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'اقتصاص الصورة',
            doneButtonTitle: 'تم',
            cancelButtonTitle: 'إلغاء',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: false,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }

  static Future<File> _compressImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) return imageFile;

      final (newWidth, newHeight) = _calculateOptimalDimensions(
        image.width,
        image.height,
        _defaultMaxWidth,
        _defaultMaxHeight,
      );

      if (image.width > _defaultMaxWidth || image.height > _defaultMaxHeight) {
        image = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.cubic,
        );
      }

      image = _optimizeImage(image);

      final hasTransparency = _hasTransparency(image);
      final compressedBytes = hasTransparency
          ? img.encodePng(image, level: 6)
          : img.encodeJpg(image, quality: _defaultQuality);

      final tempDir = await getTemporaryDirectory();
      final extension = hasTransparency ? 'png' : 'jpg';
      final compressedFile = File(
        '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.$extension',
      );
      await compressedFile.writeAsBytes(compressedBytes);

      return compressedFile;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return imageFile;
    }
  }

  static (int, int) _calculateOptimalDimensions(
    int originalWidth,
    int originalHeight,
    int maxWidth,
    int maxHeight,
  ) {
    if (originalWidth <= maxWidth && originalHeight <= maxHeight) {
      return (originalWidth, originalHeight);
    }

    final aspectRatio = originalWidth / originalHeight;

    int newWidth, newHeight;
    if (aspectRatio > 1) {
      newWidth = maxWidth;
      newHeight = (maxWidth / aspectRatio).round();
    } else {
      newHeight = maxHeight;
      newWidth = (maxHeight * aspectRatio).round();
    }

    return (newWidth, newHeight);
  }

  static bool _hasTransparency(img.Image image) {
    try {
      return image.numChannels == 4;
    } catch (e) {
      return false;
    }
  }

  static img.Image _optimizeImage(img.Image image) {
    try {
      image = img.convolution(
        image,
        filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
        div: 1,
      );

      image = img.adjustColor(
        image,
        contrast: 1.1,
        brightness: 1.02,
        saturation: 1.05,
      );

      return image;
    } catch (e) {
      debugPrint('Error optimizing image: $e');
      return image;
    }
  }

  static Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String basePath,
    required Function(int current, int total, double progress) onProgress,
    Map<String, String>? customMetadata,
  }) async {
    final List<String> uploadedUrls = [];
    final List<String> failedUploads = [];

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i';
        final url = await uploadSingleImage(
          imageFiles[i],
          '$basePath/$fileName',
          customMetadata: {
            'batch_index': i.toString(),
            'batch_total': imageFiles.length.toString(),
            ...?customMetadata,
          },
          onProgress: (progress) {
            onProgress(i + 1, imageFiles.length, progress);
          },
        );

        if (url != null) {
          uploadedUrls.add(url);
        } else {
          failedUploads.add('Image ${i + 1}');
        }
      } catch (e) {
        debugPrint('Error uploading image $i: $e');
        failedUploads.add('Image ${i + 1}');
      }
    }

    if (failedUploads.isNotEmpty) {
      debugPrint('Failed uploads: ${failedUploads.join(', ')}');
    }

    return uploadedUrls;
  }

  static Future<String?> uploadSingleImage(
    File imageFile,
    String storagePath, {
    Map<String, String>? customMetadata,
    Function(double)? onProgress,
  }) async {
    try {
      if (!await _isValidImageFile(imageFile)) {
        throw ArgumentError('Invalid image file');
      }

      final fileSize = await imageFile.length();
      final extension = _getFileExtension(imageFile.path);
      final storageRef =
          FirebaseStorage.instance.ref().child('$storagePath.$extension');

      final metadata = SettableMetadata(
        contentType: _getContentType(extension),
        cacheControl: 'public, max-age=31536000',
        customMetadata: {
          'uploaded_at': DateTime.now().toIso8601String(),
          'uploaded_by': 'admin',
          'file_size': fileSize.toString(),
          'original_name': _getFileName(imageFile.path),
          'app_version': '1.0.0',
          ...?customMetadata,
        },
      );

      final uploadTask = storageRef.putFile(imageFile, metadata);

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Successfully uploaded: $storagePath');
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('Firebase error uploading image: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  static Future<File?> createThumbnail(
    File imageFile, {
    int size = _thumbnailSize,
    bool maintainAspectRatio = false,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) return null;

      img.Image thumbnail;
      if (maintainAspectRatio) {
        thumbnail = img.copyResize(
          image,
          width: image.width > image.height ? size : null,
          height: image.height >= image.width ? size : null,
          interpolation: img.Interpolation.cubic,
        );
      } else {
        thumbnail = img.copyResizeCropSquare(
          image,
          size: size,
          interpolation: img.Interpolation.cubic,
        );
      }

      final thumbnailBytes = img.encodePng(thumbnail, level: 6);

      final tempDir = await getTemporaryDirectory();
      final thumbnailFile = File(
        '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await thumbnailFile.writeAsBytes(thumbnailBytes);

      return thumbnailFile;
    } catch (e) {
      debugPrint('Error creating thumbnail: $e');
      return null;
    }
  }

  static Future<File?> generatePlaceholderImage({
    required String text,
    int width = 400,
    int height = 400,
    Color backgroundColor = Colors.grey,
    Color textColor = Colors.white,
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.bold,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final gradient = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(width.toDouble(), height.toDouble()),
        [backgroundColor, backgroundColor.withOpacity(0.7)],
      );

      final paint = Paint()..shader = gradient;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        paint,
      );

      final borderPaint = Paint()
        ..color = backgroundColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        borderPaint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontFamily: 'Arial',
          ),
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
      );

      textPainter.layout(maxWidth: width * 0.8);

      final textX = (width - textPainter.width) / 2;
      final textY = (height - textPainter.height) / 2;
      textPainter.paint(canvas, Offset(textX, textY));

      final picture = recorder.endRecording();
      final image = await picture.toImage(width, height);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return null;

      final tempDir = await getTemporaryDirectory();
      final placeholderFile = File(
        '${tempDir.path}/placeholder_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await placeholderFile.writeAsBytes(byteData.buffer.asUint8List());

      return placeholderFile;
    } catch (e) {
      debugPrint('Error generating placeholder: $e');
      return null;
    }
  }

  static Future<List<File>> batchProcessImages({
    required List<File> imageFiles,
    bool applyFilter = false,
    bool createThumbnails = false,
    bool optimize = true,
    Function(int current, int total)? onProgress,
  }) async {
    final List<File> processedFiles = [];

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        File processedFile = imageFiles[i];

        if (optimize) {
          processedFile = await _compressImage(processedFile);
        }

        if (applyFilter) {
          processedFile = await _applyImageFilter(processedFile);
        }

        processedFiles.add(processedFile);

        if (createThumbnails) {
          final thumbnail = await createThumbnail(processedFile);
          if (thumbnail != null) {
            processedFiles.add(thumbnail);
          }
        }

        onProgress?.call(i + 1, imageFiles.length);
      } catch (e) {
        debugPrint('Error processing image ${i + 1}: $e');
      }
    }

    return processedFiles;
  }

  static Future<File> _applyImageFilter(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) return imageFile;

      image = img.adjustColor(
        image,
        contrast: 1.1,
        brightness: 1.05,
        gamma: 0.95,
        saturation: 1.1,
      );

      final filteredBytes = img.encodePng(image, level: 6);

      final tempDir = await getTemporaryDirectory();
      final filteredFile = File(
        '${tempDir.path}/filtered_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await filteredFile.writeAsBytes(filteredBytes);

      return filteredFile;
    } catch (e) {
      debugPrint('Error applying filter: $e');
      return imageFile;
    }
  }

  static Future<bool> _isValidImageFile(File file) async {
    try {
      final allowedExtensions = [
        '.jpg',
        '.jpeg',
        '.png',
        '.gif',
        '.bmp',
        '.webp'
      ];
      final fileName = file.path.toLowerCase();
      final hasValidExtension =
          allowedExtensions.any((ext) => fileName.endsWith(ext));

      if (!hasValidExtension) return false;

      final fileSize = await file.length();
      const maxSizeBytes = 10 * 1024 * 1024;

      if (fileSize > maxSizeBytes) {
        debugPrint('File too large: ${fileSize / (1024 * 1024)}MB');
        return false;
      }

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      return image != null;
    } catch (e) {
      debugPrint('Error validating image file: $e');
      return false;
    }
  }

  static String _getFileExtension(String path) {
    return path.split('.').last.toLowerCase();
  }

  static String _getContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  static String _getFileName(String path) {
    return path.split('/').last;
  }

  static Future<String> getFormattedImageSize(File imageFile) async {
    final bytes = await imageFile.length();
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(2)} ميجابايت';
  }

  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      int deletedCount = 0;

      for (FileSystemEntity file in files) {
        if (file is File && _isTempImageFile(file.path)) {
          final stat = await file.stat();
          final age = DateTime.now().difference(stat.modified);

          if (age.inHours > _tempFileCleanupHours) {
            await file.delete();
            deletedCount++;
          }
        }
      }

      debugPrint('Cleaned up $deletedCount temporary image files');
    } catch (e) {
      debugPrint('Error cleaning up temp files: $e');
    }
  }

  static bool _isTempImageFile(String path) {
    final tempPrefixes = [
      'compressed_',
      'thumb_',
      'filtered_',
      'placeholder_',
    ];

    return tempPrefixes.any((prefix) => path.contains(prefix));
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
