import 'package:cloud_firestore/cloud_firestore.dart';

class ClientModel {
  final String uid;
  final String businessName;
  final String category;
  final String imageUrl;
  final String addressTyped;
  final String phoneNumber;
  final String secondPhoneNumber;
  final GeoPoint geoLocation;
  final bool isProfileComplete;
  final double totalSavings;
  final double totalPayments;

  // New fields
  final String government;
  final String town;
  final String area;

  ClientModel({
    required this.uid,
    required this.businessName,
    required this.category,
    required this.imageUrl,
    required this.addressTyped,
    required this.phoneNumber,
    required this.secondPhoneNumber,
    required this.geoLocation,
    required this.isProfileComplete,
    required this.totalSavings,
    required this.totalPayments,
    required this.government,
    required this.town,
    required this.area,
  });

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      uid: map['uid'] ?? '',
      businessName: map['businessName'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      addressTyped: map['addressTyped'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      secondPhoneNumber: map['secondPhoneNumber'] ?? '',
      geoLocation: map['geoLocation'] ?? const GeoPoint(0, 0),
      isProfileComplete: map['isProfileComplete'] ?? false,
      totalSavings: (map['totalSavings'] != null)
          ? (map['totalSavings'] as num).toDouble()
          : 0.0,
      totalPayments: (map['totalPayments'] != null)
          ? (map['totalPayments'] as num).toDouble()
          : 0.0,
      government: map['government'] ?? '',
      town: map['town'] ?? '',
      area: map['area'] ?? '',
    );
  }

  factory ClientModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return ClientModel.fromMap(map);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'businessName': businessName,
      'category': category,
      'imageUrl': imageUrl,
      'addressTyped': addressTyped,
      'phoneNumber': phoneNumber,
      'secondPhoneNumber': secondPhoneNumber,
      'geoLocation': geoLocation,
      'isProfileComplete': isProfileComplete,
      'totalSavings': totalSavings,
      'totalPayments': totalPayments,
      'government': government,
      'town': town,
      'area': area,
    };
  }
}
