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
    );
  }

  /// Safe factory that tolerates nulls and different types from Firestore.
  factory ClientModel.fromMap(DocumentSnapshot doc) {
    final raw = doc.data();
    final Map<String, dynamic> data =
        (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};

    // helper to parse timestamp-like fields
    DateTime? _parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is int) {
        // assume millisecondsSinceEpoch
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

    // helper to parse int-like fields
    int _parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // parse tokens safely
    List<String> _parseTokens(dynamic value) {
      if (value == null) return <String>[];
      if (value is List)
        return value
            .map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      return <String>[];
    }

    // parse map safely
    Map<String, dynamic>? _parseMap(dynamic value) {
      if (value == null) return null;
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    return ClientModel(
      id: doc.id,
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
      imageUrl: data['imageUrl'] != null ? data['imageUrl'].toString() : null,
      uid: (data['uid'] ?? '') as String,
      fcmTokens: _parseTokens(data['fcmTokens']),
      lastActiveToken: data['lastActiveToken'] != null
          ? data['lastActiveToken'].toString()
          : null,
      totalDevices: _parseInt(data['totalDevices']),
      geoLocation: data['geoLocation'] is GeoPoint
          ? data['geoLocation'] as GeoPoint
          : null,
      lastTokenUpdate: _parseDateTime(data['lastTokenUpdate']),
      deviceInfo: _parseMap(data['deviceInfo']),
    );
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
    };
  }

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
      ];
}
