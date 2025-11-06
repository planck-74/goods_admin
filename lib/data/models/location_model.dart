// lib/data/models/location_model.dart

class LocationModel {
  final String government;
  final String city;
  final String area;

  const LocationModel({
    required this.government,
    required this.city,
    required this.area,
  });

  Map<String, dynamic> toJson() => {
        'government': government,
        'city': city,
        'area': area,
      };

  factory LocationModel.fromJson(Map<String, dynamic> json) => LocationModel(
        government: json['government'] ?? '',
        city: json['city'] ?? '',
        area: json['area'] ?? '',
      );

  String get fullLocation => '$government - $city - $area';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationModel &&
          runtimeType == other.runtimeType &&
          government == other.government &&
          city == other.city &&
          area == other.area;

  @override
  int get hashCode => government.hashCode ^ city.hashCode ^ area.hashCode;

  @override
  String toString() => fullLocation;
}

// lib/data/models/coverage_area_model.dart

enum CoverageType {
  fullGovernment, // محافظة كاملة
  specificCity, // مدينة محددة
}

class CoverageAreaModel {
  final String government;
  final String? city; // null = المحافظة كاملة
  final CoverageType type;

  const CoverageAreaModel({
    required this.government,
    this.city,
    required this.type,
  });

  // محافظة كاملة
  factory CoverageAreaModel.fullGovernment(String government) {
    return CoverageAreaModel(
      government: government,
      city: null,
      type: CoverageType.fullGovernment,
    );
  }

  // مدينة محددة
  factory CoverageAreaModel.specificCity(String government, String city) {
    return CoverageAreaModel(
      government: government,
      city: city,
      type: CoverageType.specificCity,
    );
  }

  Map<String, dynamic> toJson() => {
        'government': government,
        'city': city,
        'type': type.name,
      };

  factory CoverageAreaModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final type = typeStr == 'fullGovernment'
        ? CoverageType.fullGovernment
        : CoverageType.specificCity;

    return CoverageAreaModel(
      government: json['government'] ?? '',
      city: json['city'],
      type: type,
    );
  }

  String get displayName => city != null ? city! : '$government (كاملة)';

  String get fullDisplayName =>
      city != null ? '$government - $city' : '$government (المحافظة كاملة)';

  bool get isFullGovernment => type == CoverageType.fullGovernment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoverageAreaModel &&
          runtimeType == other.runtimeType &&
          government == other.government &&
          city == other.city &&
          type == other.type;

  @override
  int get hashCode => government.hashCode ^ city.hashCode ^ type.hashCode;

  @override
  String toString() => fullDisplayName;
}

// lib/data/models/supplier_model.dart

class SupplierModel {
  final String id;
  final String businessName;
  final String imageUrl;
  final String town;
  final String government;
  final String phoneNumber;
  final int minOrderPrice;
  final int minOrderProducts;
  final List<CoverageAreaModel> coverageAreas;

  const SupplierModel({
    required this.id,
    required this.businessName,
    this.imageUrl = '',
    this.town = '',
    this.government = '',
    required this.phoneNumber,
    this.minOrderPrice = 3000,
    this.minOrderProducts = 5,
    this.coverageAreas = const [],
  });

  factory SupplierModel.fromFirestore(String id, Map<String, dynamic> data) {
    final coverageList = (data['coverageAreas'] as List<dynamic>?)
            ?.map((area) =>
                CoverageAreaModel.fromJson(area as Map<String, dynamic>))
            .toList() ??
        [];

    return SupplierModel(
      id: id,
      businessName: data['businessName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      town: data['town'] ?? '',
      government: data['government'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      minOrderPrice: data['minOrderPrice'] ?? 3000,
      minOrderProducts: data['minOrderProducts'] ?? 5,
      coverageAreas: coverageList,
    );
  }

  Map<String, dynamic> toJson() => {
        'businessName': businessName,
        'imageUrl': imageUrl,
        'town': town,
        'government': government,
        'phoneNumber': phoneNumber,
        'minOrderPrice': minOrderPrice,
        'minOrderProducts': minOrderProducts,
        'coverageAreas': coverageAreas.map((loc) => loc.toJson()).toList(),
      };

  SupplierModel copyWith({
    String? id,
    String? businessName,
    String? imageUrl,
    String? town,
    String? government,
    String? phoneNumber,
    int? minOrderPrice,
    int? minOrderProducts,
    List<CoverageAreaModel>? coverageAreas,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      imageUrl: imageUrl ?? this.imageUrl,
      town: town ?? this.town,
      government: government ?? this.government,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      minOrderPrice: minOrderPrice ?? this.minOrderPrice,
      minOrderProducts: minOrderProducts ?? this.minOrderProducts,
      coverageAreas: coverageAreas ?? this.coverageAreas,
    );
  }

  // مساعدات للعرض
  String get coverageSummary {
    if (coverageAreas.isEmpty) return 'لا توجد تغطية';

    final fullGovs = coverageAreas.where((a) => a.isFullGovernment).length;
    final cities = coverageAreas.where((a) => !a.isFullGovernment).length;

    final parts = <String>[];
    if (fullGovs > 0) parts.add('$fullGovs محافظة');
    if (cities > 0) parts.add('$cities مدينة');

    return parts.join(' و ');
  }
}
