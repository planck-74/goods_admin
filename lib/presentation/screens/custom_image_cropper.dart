// custom_image_cropper.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class CustomImageCropper extends StatefulWidget {
  final File imageFile;
  final String? title;

  const CustomImageCropper({
    super.key,
    required this.imageFile,
    this.title,
  });

  @override
  State<CustomImageCropper> createState() => _CustomImageCropperState();
}

class _CustomImageCropperState extends State<CustomImageCropper> {
  final GlobalKey _cropKey = GlobalKey();

  double _scale = 1.0;
  Offset _imageOffset = Offset.zero;
  Size? _containerSize;
  ui.Image? _uiImage;

  bool _isLoading = false;
  img.Image? _originalImage;

  // Crop area properties - منطقة القطع ثابتة في وسط الشاشة
  Rect _cropRect = Rect.zero;
  bool _isDraggingImage = false;
  bool _isResizingCrop = false;
  String _activeHandle = '';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    _originalImage = img.decodeImage(bytes);
    _uiImage = await decodeImageFromList(bytes);
    setState(() {});
  }

  void _initializeCropRect() {
    if (_initialized || _containerSize == null) return;

    // منطقة القطع ثابتة في وسط الحاوية
    const cropSize = 250.0;
    final centerX = _containerSize!.width / 2;
    final centerY = _containerSize!.height / 2;

    _cropRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: cropSize,
      height: cropSize,
    );

    _initialized = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'اقتصاص الصورة'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      darkBlueColor,
                    )),
              ),
            )
          else
            TextButton(
              onPressed: _cropImage,
              child: const Text(
                'حفظ',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Crop controls
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                const Text('تحريك وتكبير الصورة',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                // Scale slider
                Row(
                  children: [
                    const Icon(Icons.zoom_out),
                    Expanded(
                      child: Slider(
                        value: _scale,
                        min: 0.5,
                        max: 3.0,
                        onChanged: (value) {
                          setState(() {
                            _scale = value;
                          });
                        },
                      ),
                    ),
                    const Icon(Icons.zoom_in),
                  ],
                ),
                // Quick ratio buttons for crop area
                const Text('نسب القطع',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildRatioButton('مربع', 1.0),
                    _buildRatioButton('3:2', 3 / 2),
                    _buildRatioButton('4:3', 4 / 3),
                    _buildRatioButton('16:9', 16 / 9),
                  ],
                ),
                // Reset button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _resetImage,
                      child: const Text('إعادة تعيين الصورة'),
                    ),
                    ElevatedButton(
                      onPressed: _resetCrop,
                      child: const Text('إعادة تعيين القطع'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Main crop area
          Expanded(
            child: Container(
              color: Colors.black,
              child: Center(
                child: _originalImage == null
                    ? const CircularProgressIndicator()
                    : _buildCropWidget(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatioButton(String label, double ratio) {
    return ElevatedButton(
      onPressed: () => _setCropRatio(ratio),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  void _setCropRatio(double ratio) {
    if (_cropRect == Rect.zero || _containerSize == null) return;

    setState(() {
      final center = _cropRect.center;
      const maxSize = 300.0;

      double width, height;
      if (ratio >= 1.0) {
        // عرض أكبر من الارتفاع
        width = maxSize;
        height = maxSize / ratio;
      } else {
        // ارتفاع أكبر من العرض
        height = maxSize;
        width = maxSize * ratio;
      }

      // التأكد من أن المنطقة لا تتجاوز حدود الحاوية
      width = width.clamp(100.0, _containerSize!.width * 0.8);
      height = height.clamp(100.0, _containerSize!.height * 0.8);

      _cropRect = Rect.fromCenter(
        center: center,
        width: width,
        height: height,
      );

      _constrainCropToContainer();
    });
  }

  void _resetImage() {
    setState(() {
      _scale = 1.0;
      _imageOffset = Offset.zero;
    });
  }

  void _resetCrop() {
    setState(() {
      _initialized = false;
    });
    _initializeCropRect();
  }

  void _constrainCropToContainer() {
    if (_containerSize == null) return;

    // التأكد من أن منطقة القطع داخل حدود الحاوية
    double left = _cropRect.left;
    double top = _cropRect.top;
    double width = _cropRect.width;
    double height = _cropRect.height;

    if (left < 0) left = 0;
    if (top < 0) top = 0;
    if (left + width > _containerSize!.width) {
      left = _containerSize!.width - width;
    }
    if (top + height > _containerSize!.height) {
      top = _containerSize!.height - height;
    }

    _cropRect = Rect.fromLTWH(left, top, width, height);
  }

  Widget _buildCropWidget() {
    return LayoutBuilder(
      builder: (context, constraints) {
        _containerSize = constraints.biggest;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeCropRect();
        });

        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Stack(
            key: _cropKey,
            children: [
              // الصورة المتحركة
              ClipRect(
                child: Transform.scale(
                  scale: _scale,
                  child: Transform.translate(
                    offset: _imageOffset,
                    child: Image.file(
                      widget.imageFile,
                      fit: BoxFit.contain,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                    ),
                  ),
                ),
              ),
              // منطقة القطع الثابتة
              if (_cropRect != Rect.zero)
                CustomPaint(
                  size: constraints.biggest,
                  painter: CropOverlayPainter(cropRect: _cropRect),
                ),
              // مقابض تغيير حجم منطقة القطع
              if (_cropRect != Rect.zero) ..._buildCropHandles(),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildCropHandles() {
    const handleSize = 20.0;
    final handles = <Widget>[];

    // زوايا منطقة القطع
    final positions = [
      ('tl', _cropRect.topLeft),
      ('tr', _cropRect.topRight),
      ('bl', _cropRect.bottomLeft),
      ('br', _cropRect.bottomRight),
      ('tm', Offset(_cropRect.center.dx, _cropRect.top)),
      ('bm', Offset(_cropRect.center.dx, _cropRect.bottom)),
      ('lm', Offset(_cropRect.left, _cropRect.center.dy)),
      ('rm', Offset(_cropRect.right, _cropRect.center.dy)),
    ];

    for (final (handle, position) in positions) {
      handles.add(
        Positioned(
          left: position.dx - handleSize / 2,
          top: position.dy - handleSize / 2,
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.circular(handleSize / 2),
            ),
          ),
        ),
      );
    }

    return handles;
  }

  void _onPanStart(DragStartDetails details) {
    final localPosition = details.localPosition;
    _activeHandle = _getActiveHandle(localPosition);

    if (_activeHandle.isNotEmpty) {
      _isResizingCrop = true;
    } else {
      _isDraggingImage = true;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isResizingCrop && _activeHandle.isNotEmpty) {
      _resizeCropRect(details.delta);
    } else if (_isDraggingImage) {
      // تحريك الصورة فقط
      setState(() {
        _imageOffset += details.delta;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _isDraggingImage = false;
    _isResizingCrop = false;
    _activeHandle = '';
  }

  String _getActiveHandle(Offset position) {
    const threshold = 15.0;

    if ((position - _cropRect.topLeft).distance < threshold) return 'tl';
    if ((position - _cropRect.topRight).distance < threshold) return 'tr';
    if ((position - _cropRect.bottomLeft).distance < threshold) return 'bl';
    if ((position - _cropRect.bottomRight).distance < threshold) return 'br';
    if ((position - Offset(_cropRect.center.dx, _cropRect.top)).distance <
        threshold) {
      return 'tm';
    }
    if ((position - Offset(_cropRect.center.dx, _cropRect.bottom)).distance <
        threshold) {
      return 'bm';
    }
    if ((position - Offset(_cropRect.left, _cropRect.center.dy)).distance <
        threshold) {
      return 'lm';
    }
    if ((position - Offset(_cropRect.right, _cropRect.center.dy)).distance <
        threshold) {
      return 'rm';
    }

    return '';
  }

  void _resizeCropRect(Offset delta) {
    setState(() {
      Rect newRect = _cropRect;
      const minSize = 50.0;

      switch (_activeHandle) {
        case 'tl':
          newRect = Rect.fromLTRB(
            _cropRect.left + delta.dx,
            _cropRect.top + delta.dy,
            _cropRect.right,
            _cropRect.bottom,
          );
          break;
        case 'tr':
          newRect = Rect.fromLTRB(
            _cropRect.left,
            _cropRect.top + delta.dy,
            _cropRect.right + delta.dx,
            _cropRect.bottom,
          );
          break;
        case 'bl':
          newRect = Rect.fromLTRB(
            _cropRect.left + delta.dx,
            _cropRect.top,
            _cropRect.right,
            _cropRect.bottom + delta.dy,
          );
          break;
        case 'br':
          newRect = Rect.fromLTRB(
            _cropRect.left,
            _cropRect.top,
            _cropRect.right + delta.dx,
            _cropRect.bottom + delta.dy,
          );
          break;
        case 'tm':
          newRect = Rect.fromLTRB(
            _cropRect.left,
            _cropRect.top + delta.dy,
            _cropRect.right,
            _cropRect.bottom,
          );
          break;
        case 'bm':
          newRect = Rect.fromLTRB(
            _cropRect.left,
            _cropRect.top,
            _cropRect.right,
            _cropRect.bottom + delta.dy,
          );
          break;
        case 'lm':
          newRect = Rect.fromLTRB(
            _cropRect.left + delta.dx,
            _cropRect.top,
            _cropRect.right,
            _cropRect.bottom,
          );
          break;
        case 'rm':
          newRect = Rect.fromLTRB(
            _cropRect.left,
            _cropRect.top,
            _cropRect.right + delta.dx,
            _cropRect.bottom,
          );
          break;
      }

      // التأكد من الحد الأدنى للحجم
      if (newRect.width >= minSize && newRect.height >= minSize) {
        _cropRect = newRect;
        _constrainCropToContainer();
      }
    });
  }

  Rect _getImageDisplayRect() {
    if (_containerSize == null || _uiImage == null) return Rect.zero;

    final containerAspect = _containerSize!.width / _containerSize!.height;
    final imageAspect = _uiImage!.width / _uiImage!.height;

    double displayWidth, displayHeight;
    double offsetX = 0, offsetY = 0;

    if (containerAspect > imageAspect) {
      displayHeight = _containerSize!.height;
      displayWidth = displayHeight * imageAspect;
      offsetX = (_containerSize!.width - displayWidth) / 2;
    } else {
      displayWidth = _containerSize!.width;
      displayHeight = displayWidth / imageAspect;
      offsetY = (_containerSize!.height - displayHeight) / 2;
    }

    return Rect.fromLTWH(offsetX, offsetY, displayWidth, displayHeight);
  }

  Future<void> _cropImage() async {
    if (_originalImage == null ||
        _containerSize == null ||
        _cropRect == Rect.zero) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // حساب موضع الصورة الفعلي
      final imageDisplayRect = _getImageDisplayRect();
      if (imageDisplayRect == Rect.zero) {
        throw Exception('Unable to calculate image display rect');
      }

      // تطبيق التحويلات على الصورة
      final scaledImageRect = Rect.fromCenter(
        center: imageDisplayRect.center + _imageOffset,
        width: imageDisplayRect.width * _scale,
        height: imageDisplayRect.height * _scale,
      );

      // حساب منطقة القطع بإحداثيات الصورة الأصلية
      final scaleX = _originalImage!.width / scaledImageRect.width;
      final scaleY = _originalImage!.height / scaledImageRect.height;

      // تحويل منطقة القطع إلى إحداثيات الصورة
      final cropInImageCoords = Rect.fromLTWH(
        (_cropRect.left - scaledImageRect.left) * scaleX,
        (_cropRect.top - scaledImageRect.top) * scaleY,
        _cropRect.width * scaleX,
        _cropRect.height * scaleY,
      );

      // التأكد من أن منطقة القطع داخل حدود الصورة
      final x = cropInImageCoords.left
          .clamp(0.0, _originalImage!.width.toDouble())
          .round();
      final y = cropInImageCoords.top
          .clamp(0.0, _originalImage!.height.toDouble())
          .round();
      final width = cropInImageCoords.width
          .clamp(1.0, _originalImage!.width.toDouble() - x)
          .round();
      final height = cropInImageCoords.height
          .clamp(1.0, _originalImage!.height.toDouble() - y)
          .round();

      if (width <= 0 || height <= 0) {
        throw Exception('Invalid crop dimensions');
      }

      // قطع الصورة
      final croppedImage = img.copyCrop(
        _originalImage!,
        x: x,
        y: y,
        width: width,
        height: height,
      );

      // حفظ الصورة المقطوعة
      final tempDir = await getTemporaryDirectory();
      final croppedFile = File(
          '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png');

      await croppedFile.writeAsBytes(img.encodePng(croppedImage));

      if (mounted) {
        Navigator.of(context).pop(croppedFile);
      }
    } catch (e) {
      debugPrint('Error cropping image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء اقتصاص الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class CropOverlayPainter extends CustomPainter {
  final Rect cropRect;

  CropOverlayPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    // رسم الطبقة المعتمة خارج منطقة القطع
    final overlayPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final cropBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final gridPaint = Paint()
      ..color = Colors.white38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // رسم المناطق المعتمة
    // أعلى
    if (cropRect.top > 0) {
      canvas.drawRect(
        Rect.fromLTRB(0, 0, size.width, cropRect.top),
        overlayPaint,
      );
    }

    // أسفل
    if (cropRect.bottom < size.height) {
      canvas.drawRect(
        Rect.fromLTRB(0, cropRect.bottom, size.width, size.height),
        overlayPaint,
      );
    }

    // يسار
    canvas.drawRect(
      Rect.fromLTRB(0, cropRect.top, cropRect.left, cropRect.bottom),
      overlayPaint,
    );

    // يمين
    canvas.drawRect(
      Rect.fromLTRB(cropRect.right, cropRect.top, size.width, cropRect.bottom),
      overlayPaint,
    );

    // رسم حدود منطقة القطع
    canvas.drawRect(cropRect, cropBorderPaint);

    // رسم خطوط الشبكة (قاعدة الأثلاث)
    final gridWidth = cropRect.width / 3;
    final gridHeight = cropRect.height / 3;

    // خطوط عمودية
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(cropRect.left + (gridWidth * i), cropRect.top),
        Offset(cropRect.left + (gridWidth * i), cropRect.bottom),
        gridPaint,
      );
    }

    // خطوط أفقية
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(cropRect.left, cropRect.top + (gridHeight * i)),
        Offset(cropRect.right, cropRect.top + (gridHeight * i)),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
