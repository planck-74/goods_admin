import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:goods_admin/business%20logic/cubits/selected_clients_notification_cubit/selected_clients_notification_state.dart';
import 'package:goods_admin/data/models/client_model.dart';

enum NotificationType {
  general('general'),
  update('update'),
  promotion('promotion'),
  news('news'),
  social('social');

  const NotificationType(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case NotificationType.general:
        return 'عام';
      case NotificationType.update:
        return 'تحديث التطبيق';
      case NotificationType.promotion:
        return 'عروض وخصومات';
      case NotificationType.news:
        return 'أخبار';
      case NotificationType.social:
        return 'وسائل التواصل';
    }
  }
}

enum NotificationPriority {
  normal('normal'),
  high('high');

  const NotificationPriority(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case NotificationPriority.normal:
        return 'عادية';
      case NotificationPriority.high:
        return 'عالية';
    }
  }
}

enum ClientFilter {
  all,
  activeOnly,
  withTokensOnly,
  recentlyActive,
  byCategory,
  byGovernment,
}

class SelectedClientsCubit extends Cubit<SelectedClientsState> {
  SelectedClientsCubit() : super(SelectedClientsInitial());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<ClientModel> _allClients = [];
  String _currentSearchQuery = '';
  ClientFilter _currentFilter = ClientFilter.all;

  // Load all clients with updated data structure
  Future<void> loadClients() async {
    try {
      print('🔄 Loading clients from Firestore...');
      emit(SelectedClientsLoading());

      final QuerySnapshot snapshot = await _firestore
          .collection('clients')
          .orderBy('lastTokenUpdate', descending: true)
          .get();

      _allClients = snapshot.docs.map((doc) {
        return ClientModel.fromMap(doc);
      }).toList();

      // Calculate category and government counts
      final Map<String, int> categoryCounts = {};
      final Map<String, int> governmentCounts = {};

      for (final client in _allClients) {
        // Count categories
        final category = client.category;
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;

        // Count governments
        final government = client.government;
        governmentCounts[government] = (governmentCounts[government] ?? 0) + 1;
      }

      _applyFiltersAndSearch(
        categoryCounts: categoryCounts,
        governmentCounts: governmentCounts,
      );
      print('✅ Loaded ${_allClients.length} clients.');
    } catch (e) {
      emit(SelectedClientsError('حدث خطأ في تحميل العملاء: ${e.toString()}'));
    }
  }

  // Toggle client selection
  void toggleClientSelection(String clientId) {
    final currentState = state;
    if (currentState is! SelectedClientsLoaded) return;

    final updatedClients = _allClients.map((client) {
      if (client.id == clientId) {
        return client.copyWith(isSelected: !client.isSelected);
      }
      return client;
    }).toList();

    _allClients = updatedClients;
    _applyFiltersAndSearch(
      categoryCounts: currentState.categoryCounts,
      governmentCounts: currentState.governmentCounts,
    );
  }

  // Select all filtered clients
  void selectAllFiltered() {
    final currentState = state;
    if (currentState is! SelectedClientsLoaded) return;

    final filteredIds = currentState.filteredClients.map((c) => c.id).toSet();

    _allClients = _allClients.map((client) {
      if (filteredIds.contains(client.id)) {
        return client.copyWith(isSelected: true);
      }
      return client;
    }).toList();

    _applyFiltersAndSearch(
      categoryCounts: currentState.categoryCounts,
      governmentCounts: currentState.governmentCounts,
    );
  }

  // Deselect all clients
  void deselectAll() {
    final currentState = state;
    if (currentState is! SelectedClientsLoaded) return;

    _allClients = _allClients.map((client) {
      return client.copyWith(isSelected: false);
    }).toList();

    _applyFiltersAndSearch(
      categoryCounts: currentState.categoryCounts,
      governmentCounts: currentState.governmentCounts,
    );
  }

  // Search clients - Updated to search in new fields
  void searchClients(String query) {
    _currentSearchQuery = query.toLowerCase();
    final currentState = state;
    if (currentState is SelectedClientsLoaded) {
      _applyFiltersAndSearch(
        categoryCounts: currentState.categoryCounts,
        governmentCounts: currentState.governmentCounts,
      );
    }
  }

  // Apply filter
  void applyFilter(ClientFilter filter) {
    _currentFilter = filter;
    final currentState = state;
    if (currentState is SelectedClientsLoaded) {
      _applyFiltersAndSearch(
        categoryCounts: currentState.categoryCounts,
        governmentCounts: currentState.governmentCounts,
      );
    }
  }

  // Updated filter and search logic
  void _applyFiltersAndSearch({
    required Map<String, int> categoryCounts,
    required Map<String, int> governmentCounts,
  }) {
    List<ClientModel> filtered = List.from(_allClients);

    // Apply search - Updated to include new fields
    if (_currentSearchQuery.isNotEmpty) {
      filtered = filtered.where((client) {
        return client.businessName
                .toLowerCase()
                .contains(_currentSearchQuery) ||
            client.phoneNumber.contains(_currentSearchQuery) ||
            (client.secondPhoneNumber?.contains(_currentSearchQuery) ??
                false) ||
            client.category.toLowerCase().contains(_currentSearchQuery) ||
            client.government.toLowerCase().contains(_currentSearchQuery) ||
            client.town.toLowerCase().contains(_currentSearchQuery) ||
            client.area.toLowerCase().contains(_currentSearchQuery) ||
            client.addressTyped.toLowerCase().contains(_currentSearchQuery);
      }).toList();
    }

    // Apply filter
    switch (_currentFilter) {
      case ClientFilter.activeOnly:
        filtered = filtered.where((client) {
          final lastActive = client.lastTokenUpdate;
          if (lastActive == null) return false;
          final daysSinceActive = DateTime.now().difference(lastActive).inDays;
          return daysSinceActive <= 30; // Active in last 30 days
        }).toList();
        break;
      case ClientFilter.withTokensOnly:
        filtered = filtered.where((client) => client.hasValidTokens).toList();
        break;
      case ClientFilter.recentlyActive:
        filtered = filtered.where((client) {
          final lastActive = client.lastTokenUpdate;
          if (lastActive == null) return false;
          final daysSinceActive = DateTime.now().difference(lastActive).inDays;
          return daysSinceActive <= 7; // Active in last 7 days
        }).toList();
        break;
      case ClientFilter.all:
      default:
        // No additional filtering
        break;
    }

    final selectedCount = _allClients.where((c) => c.isSelected).length;

    emit(SelectedClientsLoaded(
      clients: _allClients,
      filteredClients: filtered,
      searchQuery: _currentSearchQuery,
      currentFilter: _currentFilter,
      selectedCount: selectedCount,
      categoryCounts: categoryCounts,
      governmentCounts: governmentCounts,
    ));
  }

  // Filter by category
  void filterByCategory(String category) {
    final currentState = state;
    if (currentState is! SelectedClientsLoaded) return;

    final filtered = _allClients.where((client) {
      return client.category == category;
    }).toList();

    emit(currentState.copyWith(
      filteredClients: filtered,
      currentFilter: ClientFilter.byCategory,
    ));
  }

  // Filter by government
  void filterByGovernment(String government) {
    final currentState = state;
    if (currentState is! SelectedClientsLoaded) return;

    final filtered = _allClients.where((client) {
      return client.government == government;
    }).toList();

    emit(currentState.copyWith(
      filteredClients: filtered,
      currentFilter: ClientFilter.byGovernment,
    ));
  }

  // Upload image (unchanged)
  Future<String?> uploadImage(File imageFile) async {
    try {
      final String fileName =
          'notifications/selected/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final Reference ref = _storage.ref().child(fileName);

      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'type': 'admin_selected_notification',
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }

  // Send notification (unchanged)
  Future<void> sendNotificationToSelectedClients({
    required String title,
    required String body,
    File? imageFile,
    String? linkUrl,
    String? linkText,
    required NotificationType notificationType,
    required NotificationPriority priority,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final selectedClients = _allClients.where((c) => c.isSelected).toList();

      if (selectedClients.isEmpty) {
        emit(const SelectedClientsError('يجب اختيار عميل واحد على الأقل'));
        return;
      }

      emit(const SelectedClientsSending(
        message: 'جاري التحضير لإرسال الإشعار...',
      ));

      // Upload image if provided
      String? imageUrl;
      if (imageFile != null) {
        emit(const SelectedClientsSending(
          message: 'جاري رفع الصورة...',
          isUploadingImage: true,
        ));

        imageUrl = await uploadImage(imageFile);
        if (imageUrl == null) {
          emit(const SelectedClientsError('فشل في رفع الصورة'));
          return;
        }
      }

      emit(SelectedClientsSending(
        message: 'جاري إرسال الإشعار إلى ${selectedClients.length} عميل...',
      ));

      // Prepare data for cloud function
      final Map<String, dynamic> data = {
        'title': title.trim(),
        'body': body.trim(),
        'clientIds': selectedClients.map((c) => c.id).toList(),
        'notificationType': notificationType.value,
        'priority': priority.value,
        'data': {
          'source': 'admin_app_selected',
          'category': notificationType.value,
          ...?additionalData,
        },
      };

      if (imageUrl != null) {
        data['imageUrl'] = imageUrl;
      }

      if (linkUrl != null && linkUrl.trim().isNotEmpty) {
        data['linkUrl'] = linkUrl.trim();
        if (linkText != null && linkText.trim().isNotEmpty) {
          data['linkText'] = linkText.trim();
        }
      }

      // Call cloud function
      final HttpsCallable callable = _functions.httpsCallable(
        'sendNotificationToSelectedClients',
        options: HttpsCallableOptions(
          timeout: const Duration(minutes: 3),
        ),
      );

      final HttpsCallableResult result = await callable.call(data);
      final Map<String, dynamic> response =
          Map<String, dynamic>.from(result.data);

      // Reset selections after successful send
      deselectAll();

      emit(SelectedClientsSent(
        message: response['message'] ?? 'تم إرسال الإشعار بنجاح',
        successCount: response['sent'] ?? 0,
        totalClients: response['validClientsCount'] ?? selectedClients.length,
      ));
    } catch (e) {
      String errorMessage = 'حدث خطأ في إرسال الإشعار';

      final String errorStr = e.toString().toLowerCase();
      if (errorStr.contains('unauthenticated')) {
        errorMessage = 'يجب تسجيل الدخول أولاً';
      } else if (errorStr.contains('invalid-argument')) {
        errorMessage = 'البيانات المدخلة غير صحيحة';
      } else if (errorStr.contains('not-found')) {
        errorMessage = 'لا توجد أجهزة نشطة للعملاء المحددين';
      } else if (errorStr.contains('network')) {
        errorMessage = 'تحقق من الاتصال بالإنترنت';
      } else if (errorStr.contains('timeout')) {
        errorMessage = 'انتهت مهلة الإرسال، حاول مرة أخرى';
      }

      emit(SelectedClientsError(errorMessage));
    }
  }

  // Updated filter display names
  String getFilterDisplayName(ClientFilter filter) {
    switch (filter) {
      case ClientFilter.all:
        return 'جميع العملاء';
      case ClientFilter.activeOnly:
        return 'النشطين (30 يوم)';
      case ClientFilter.withTokensOnly:
        return 'مع إشعارات فعالة';
      case ClientFilter.recentlyActive:
        return 'النشطين مؤخراً (7 أيام)';
      case ClientFilter.byCategory:
        return 'حسب النوع';
      case ClientFilter.byGovernment:
        return 'حسب المحافظة';
    }
  }

  // Get selected clients count by filter (unchanged)
  int getSelectedCountForFilter(ClientFilter filter) {
    final filtered = _allClients.where((client) {
      if (!client.isSelected) return false;

      switch (filter) {
        case ClientFilter.activeOnly:
          final lastActive = client.lastTokenUpdate;
          if (lastActive == null) return false;
          return DateTime.now().difference(lastActive).inDays <= 30;
        case ClientFilter.withTokensOnly:
          return client.hasValidTokens;
        case ClientFilter.recentlyActive:
          final lastActive = client.lastTokenUpdate;
          if (lastActive == null) return false;
          return DateTime.now().difference(lastActive).inDays <= 7;
        case ClientFilter.all:
        case ClientFilter.byCategory:
        case ClientFilter.byGovernment:
          return true;
      }
    });

    return filtered.length;
  }

  // Reset state (unchanged)
  void resetState() {
    _allClients.clear();
    _currentSearchQuery = '';
    _currentFilter = ClientFilter.all;
    emit(SelectedClientsInitial());
  }
}
