part of 'batch_operations_cubit.dart';

@immutable
abstract class BatchOperationsState {
  const BatchOperationsState();
}

class BatchOperationsInitial extends BatchOperationsState {
  const BatchOperationsInitial();

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is BatchOperationsInitial;
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'BatchOperationsInitial()';
}

class BatchOperationsLoading extends BatchOperationsState {
  final String? operationName;
  final String loadingMessage;

  const BatchOperationsLoading({
    this.operationName,
    this.loadingMessage = 'جاري المعالجة...',
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BatchOperationsLoading &&
            other.operationName == operationName &&
            other.loadingMessage == loadingMessage);
  }

  @override
  int get hashCode => Object.hash(operationName, loadingMessage);

  @override
  String toString() =>
      'BatchOperationsLoading(operationName: $operationName, loadingMessage: $loadingMessage)';
}

class BatchOperationsSuccess extends BatchOperationsState {
  final String message;
  final int affectedCount;
  final String? operationType;
  final DateTime timestamp;
  final Map<String, dynamic>? additionalData;

  BatchOperationsSuccess({
    required this.message,
    required this.affectedCount,
    this.operationType,
    DateTime? timestamp,
    this.additionalData,
  }) : timestamp = timestamp ?? DateTime.now();

  BatchOperationsSuccess copyWith({
    String? message,
    int? affectedCount,
    String? operationType,
    DateTime? timestamp,
    Map<String, dynamic>? additionalData,
  }) {
    return BatchOperationsSuccess(
      message: message ?? this.message,
      affectedCount: affectedCount ?? this.affectedCount,
      operationType: operationType ?? this.operationType,
      timestamp: timestamp ?? this.timestamp,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BatchOperationsSuccess &&
            other.message == message &&
            other.affectedCount == affectedCount &&
            other.operationType == operationType);
  }

  @override
  int get hashCode => Object.hash(message, affectedCount, operationType);

  @override
  String toString() =>
      'BatchOperationsSuccess(message: $message, affectedCount: $affectedCount, operationType: $operationType)';
}

class BatchOperationsError extends BatchOperationsState {
  final String message;
  final String? errorCode;
  final String? operationType;
  final DateTime timestamp;
  final dynamic originalError;

  BatchOperationsError(
    this.message, {
    this.errorCode,
    this.operationType,
    DateTime? timestamp,
    this.originalError,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BatchOperationsError &&
            other.message == message &&
            other.errorCode == errorCode &&
            other.operationType == operationType);
  }

  @override
  int get hashCode => Object.hash(message, errorCode, operationType);

  @override
  String toString() =>
      'BatchOperationsError(message: $message, errorCode: $errorCode, operationType: $operationType)';
}

class BatchOperationsStatistics extends BatchOperationsState {
  final Map<String, dynamic> statistics;
  final DateTime generatedAt;

  BatchOperationsStatistics({
    required this.statistics,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  int get totalProducts => statistics['totalProducts'] as int? ?? 0;
  int get totalSales => statistics['totalSales'] as int? ?? 0;
  double get averageSales => statistics['averageSales'] as double? ?? 0.0;
  Set<String> get classifications =>
      statistics['classifications'] as Set<String>? ?? {};
  Set<String> get manufacturers =>
      statistics['manufacturers'] as Set<String>? ?? {};
  Set<String> get packages => statistics['packages'] as Set<String>? ?? {};
  Set<String> get sizes => statistics['sizes'] as Set<String>? ?? {};

  bool get hasMultipleClassifications => classifications.length > 1;
  bool get hasMultipleManufacturers => manufacturers.length > 1;
  String get mostCommonClassification => _getMostCommon('classifications');
  String get mostCommonManufacturer => _getMostCommon('manufacturers');

  String _getMostCommon(String key) {
    final items = statistics[key] as Set<String>? ?? {};
    return items.isNotEmpty ? items.first : 'غير محدد';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BatchOperationsStatistics &&
            _mapsEqual(other.statistics, statistics));
  }

  bool _mapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (String key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => statistics.hashCode;

  @override
  String toString() =>
      'BatchOperationsStatistics(totalProducts: $totalProducts, totalSales: $totalSales)';
}

class BatchOperationsSearchResults extends BatchOperationsState {
  final List<Product> products;
  final Map<String, dynamic> searchCriteria;
  final DateTime searchTime;

  BatchOperationsSearchResults({
    required this.products,
    this.searchCriteria = const {},
    DateTime? searchTime,
  }) : searchTime = searchTime ?? DateTime.now();

  int get resultCount => products.length;
  bool get hasResults => products.isNotEmpty;
  bool get isEmpty => products.isEmpty;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BatchOperationsSearchResults &&
            _listsEqual(other.products, products) &&
            _mapsEqual(other.searchCriteria, searchCriteria));
  }

  bool _listsEqual(List<Product> list1, List<Product> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].productId != list2[i].productId) return false;
    }
    return true;
  }

  bool _mapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (String key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(products.length, searchCriteria.hashCode);

  @override
  String toString() =>
      'BatchOperationsSearchResults(resultCount: $resultCount)';
}

class BatchOperationsProgress extends BatchOperationsState {
  final int completed;
  final int total;
  final String currentOperation;
  final String? currentItemName;
  final DateTime startTime;
  final Map<String, dynamic>? progressData;

  BatchOperationsProgress({
    required this.completed,
    required this.total,
    required this.currentOperation,
    this.currentItemName,
    DateTime? startTime,
    this.progressData,
  }) : startTime = startTime ?? DateTime.now();

  double get progress => total > 0 ? completed / total : 0.0;
  int get progressPercentage => (progress * 100).round();
  bool get isCompleted => completed >= total;
  int get remaining => total - completed;

  Duration get elapsed => DateTime.now().difference(startTime);
  Duration? get estimatedTimeRemaining {
    if (completed <= 0 || isCompleted) return null;
    final avgTimePerItem = elapsed.inMilliseconds / completed;
    final remainingMs = (remaining * avgTimePerItem).round();
    return Duration(milliseconds: remainingMs);
  }

  String get progressText => '$completed من $total';
  String get percentageText => '$progressPercentage%';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BatchOperationsProgress &&
            other.completed == completed &&
            other.total == total &&
            other.currentOperation == currentOperation &&
            other.currentItemName == currentItemName);
  }

  @override
  int get hashCode =>
      Object.hash(completed, total, currentOperation, currentItemName);

  @override
  String toString() =>
      'BatchOperationsProgress(progress: $progressText, operation: $currentOperation)';
}

class BatchOperationsExportReady extends BatchOperationsState {
  final String filePath;
  final String fileName;
  final int itemCount;
  final String exportFormat;
  final DateTime exportTime;
  final int fileSizeBytes;

  BatchOperationsExportReady({
    required this.filePath,
    required this.fileName,
    required this.itemCount,
    required this.exportFormat,
    required this.fileSizeBytes,
    DateTime? exportTime,
  }) : exportTime = exportTime ?? DateTime.now();

  String get fileSizeFormatted => _formatFileSize(fileSizeBytes);

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BatchOperationsExportReady &&
            other.filePath == filePath &&
            other.fileName == fileName &&
            other.itemCount == itemCount);
  }

  @override
  int get hashCode => Object.hash(filePath, fileName, itemCount);

  @override
  String toString() =>
      'BatchOperationsExportReady(fileName: $fileName, itemCount: $itemCount, size: $fileSizeFormatted)';
}

class BatchOperationsValidationResult extends BatchOperationsState {
  final List<String> validationErrors;
  final List<String> validationWarnings;
  final List<Product> validProducts;
  final List<Product> invalidProducts;

  const BatchOperationsValidationResult({
    required this.validationErrors,
    required this.validationWarnings,
    required this.validProducts,
    required this.invalidProducts,
  });

  bool get hasErrors => validationErrors.isNotEmpty;
  bool get hasWarnings => validationWarnings.isNotEmpty;
  bool get isValid => validationErrors.isEmpty;
  int get validCount => validProducts.length;
  int get invalidCount => invalidProducts.length;
  int get totalCount => validCount + invalidCount;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BatchOperationsValidationResult &&
            _listsEqualString(other.validationErrors, validationErrors) &&
            _listsEqualString(other.validationWarnings, validationWarnings));
  }

  bool _listsEqualString(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        validationErrors.length,
        validationWarnings.length,
        validCount,
        invalidCount,
      );

  @override
  String toString() =>
      'BatchOperationsValidationResult(valid: $validCount, invalid: $invalidCount, errors: ${validationErrors.length})';
}
