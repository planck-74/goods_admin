import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ClientModel extends Equatable {
  final String id;
  final String businessName;
  final String phoneNumber;
  final String? secondPhoneNumber;
  final String category;
  final String government;
  final String town;
  final String area;
  final String addressTyped;
  final String? imageUrl;
  final String uid;
  final List<String> fcmTokens;
  final String? lastActiveToken;
  final int totalDevices;
  final GeoPoint? geoLocation;
  final DateTime? lastTokenUpdate;
  final Map<String, dynamic>? deviceInfo;
  final bool isSelected;

  // NEW FIELDS for enhanced features
  final DateTime? dateCreated;
  final DateTime? lastUpdated;
  final DateTime? cartStatusUpdatedAt;
  final DateTime? lastReminderSentAt;
  final bool? registrationComplete;
  final bool? fullCart;
  final String? lastCartReminder;

  const ClientModel({
    required this.id,
    required this.businessName,
    required this.phoneNumber,
    this.secondPhoneNumber,
    required this.category,
    required this.government,
    required this.town,
    required this.area,
    required this.addressTyped,
    this.imageUrl,
    required this.uid,
    this.fcmTokens = const [],
    this.lastActiveToken,
    this.totalDevices = 0,
    this.geoLocation,
    this.lastTokenUpdate,
    this.deviceInfo,
    this.isSelected = false,
    // NEW FIELDS
    this.dateCreated,
    this.lastUpdated,
    this.cartStatusUpdatedAt,
    this.lastReminderSentAt,
    this.registrationComplete,
    this.fullCart,
    this.lastCartReminder,
  });

  // Convenience getters
  String get name => businessName;
  String get phone => phoneNumber;
  String get fullAddress => '$addressTyped، $area، $town، $government';
  bool get hasValidTokens => fcmTokens.isNotEmpty;
  int get tokensCount => fcmTokens.length;
  DateTime? get lastActive => lastTokenUpdate;
  String get displayName =>
      businessName.isNotEmpty ? businessName : 'عميل - $category';
  String get locationSummary => '$area، $town';

  ClientModel copyWith({
    String? id,
    String? businessName,
    String? phoneNumber,
    String? secondPhoneNumber,
    String? category,
    String? government,
    String? town,
    String? area,
    String? addressTyped,
    String? imageUrl,
    String? uid,
    List<String>? fcmTokens,
    String? lastActiveToken,
    int? totalDevices,
    GeoPoint? geoLocation,
    DateTime? lastTokenUpdate,
    Map<String, dynamic>? deviceInfo,
    bool? isSelected,
    // NEW FIELDS
    DateTime? dateCreated,
    DateTime? lastUpdated,
    DateTime? cartStatusUpdatedAt,
    DateTime? lastReminderSentAt,
    bool? registrationComplete,
    bool? fullCart,
    String? lastCartReminder,
  }) {
    return ClientModel(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      secondPhoneNumber: secondPhoneNumber ?? this.secondPhoneNumber,
      category: category ?? this.category,
      government: government ?? this.government,
      town: town ?? this.town,
      area: area ?? this.area,
      addressTyped: addressTyped ?? this.addressTyped,
      imageUrl: imageUrl ?? this.imageUrl,
      uid: uid ?? this.uid,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      lastActiveToken: lastActiveToken ?? this.lastActiveToken,
      totalDevices: totalDevices ?? this.totalDevices,
      geoLocation: geoLocation ?? this.geoLocation,
      lastTokenUpdate: lastTokenUpdate ?? this.lastTokenUpdate,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      isSelected: isSelected ?? this.isSelected,
      // NEW FIELDS
      dateCreated: dateCreated ?? this.dateCreated,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      cartStatusUpdatedAt: cartStatusUpdatedAt ?? this.cartStatusUpdatedAt,
      lastReminderSentAt: lastReminderSentAt ?? this.lastReminderSentAt,
      registrationComplete: registrationComplete ?? this.registrationComplete,
      fullCart: fullCart ?? this.fullCart,
      lastCartReminder: lastCartReminder ?? this.lastCartReminder,
    );
  }

  /// Helper to parse timestamp-like fields
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (_) {
        return null;
      }
    }
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Helper to parse int-like fields
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Helper to parse tokens safely
  static List<String> _parseTokens(dynamic value) {
    if (value == null) return <String>[];
    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  /// Helper to parse map safely
  static Map<String, dynamic>? _parseMap(dynamic value) {
    if (value == null) return null;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  /// Helper to parse bool safely
  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    if (value is int) return value != 0;
    return null;
  }

  /// Factory from DocumentSnapshot (for Firestore queries)
  factory ClientModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final raw = doc.data();
    final Map<String, dynamic> data =
        (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};

    return ClientModel._fromMapData(doc.id, data);
  }

  /// Factory from Map (for when you already have the data extracted)
  factory ClientModel.fromMapData(String docId, Map<String, dynamic> data) {
    return ClientModel._fromMapData(docId, data);
  }

  /// Private constructor that does the actual parsing
  factory ClientModel._fromMapData(String docId, Map<String, dynamic> data) {
    return ClientModel(
      id: docId,
      businessName: (data['businessName'] ?? '') as String,
      phoneNumber: (data['phoneNumber'] ?? '') as String,
      secondPhoneNumber: (data['secondPhoneNumber'] != null)
          ? data['secondPhoneNumber'].toString()
          : null,
      category: (data['category'] ?? '') as String,
      government: (data['government'] ?? '') as String,
      town: (data['town'] ?? '') as String,
      area: (data['area'] ?? '') as String,
      addressTyped: (data['addressTyped'] ?? '') as String,
      imageUrl: data['imageUrl']?.toString(),
      uid: (data['uid'] ?? docId) as String, // Use docId as fallback for uid
      fcmTokens: _parseTokens(data['fcmTokens']),
      lastActiveToken: data['lastActiveToken']?.toString(),
      totalDevices: _parseInt(data['totalDevices']),
      geoLocation: data['geoLocation'] is GeoPoint
          ? data['geoLocation'] as GeoPoint
          : null,
      lastTokenUpdate: _parseDateTime(data['lastTokenUpdate']),
      deviceInfo: _parseMap(data['deviceInfo']),
      isSelected: false, // Always default to false when loading from DB
      // NEW FIELDS
      dateCreated: _parseDateTime(data['dateCreated']),
      lastUpdated: _parseDateTime(data['lastUpdated']),
      cartStatusUpdatedAt: _parseDateTime(data['cartStatusUpdatedAt']),
      lastReminderSentAt: _parseDateTime(data['lastReminderSentAt']),
      registrationComplete: _parseBool(data['registrationComplete']),
      fullCart: _parseBool(data['fullCart']),
      lastCartReminder: data['lastCartReminder']?.toString(),
    );
  }

  /// Legacy factory for backward compatibility - now routes to fromDocumentSnapshot
  factory ClientModel.fromMap(DocumentSnapshot doc) {
    return ClientModel.fromDocumentSnapshot(doc);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'businessName': businessName,
      'phoneNumber': phoneNumber,
      'secondPhoneNumber': secondPhoneNumber,
      'category': category,
      'government': government,
      'town': town,
      'area': area,
      'addressTyped': addressTyped,
      'imageUrl': imageUrl,
      'uid': uid,
      'fcmTokens': fcmTokens,
      'lastActiveToken': lastActiveToken,
      'totalDevices': totalDevices,
      'geoLocation': geoLocation,
      'lastTokenUpdate':
          lastTokenUpdate != null ? Timestamp.fromDate(lastTokenUpdate!) : null,
      'deviceInfo': deviceInfo,
      // NEW FIELDS
      'dateCreated':
          dateCreated != null ? Timestamp.fromDate(dateCreated!) : null,
      'lastUpdated':
          lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
      'cartStatusUpdatedAt': cartStatusUpdatedAt != null
          ? Timestamp.fromDate(cartStatusUpdatedAt!)
          : null,
      'lastReminderSentAt': lastReminderSentAt != null
          ? Timestamp.fromDate(lastReminderSentAt!)
          : null,
      'registrationComplete': registrationComplete,
      'fullCart': fullCart,
      'lastCartReminder': lastCartReminder,
    };
  }

  /// Alias for toFirestore for consistency with old code
  Map<String, dynamic> toMap() => toFirestore();

  @override
  List<Object?> get props => [
        id,
        businessName,
        phoneNumber,
        secondPhoneNumber,
        category,
        government,
        town,
        area,
        addressTyped,
        imageUrl,
        uid,
        fcmTokens,
        lastActiveToken,
        totalDevices,
        geoLocation,
        lastTokenUpdate,
        deviceInfo,
        isSelected,
        // NEW FIELDS
        dateCreated,
        lastUpdated,
        cartStatusUpdatedAt,
        lastReminderSentAt,
        registrationComplete,
        fullCart,
        lastCartReminder,
      ];
}
