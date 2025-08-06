import 'package:cloud_firestore/cloud_firestore.dart';

class ClientModel {
  final String uid;
  final String businessName;
  final String category;
  final String imageUrl;
  final String address;
  final String phoneNumber;
  final String secondPhoneNumber;
  final GeoPoint geoPoint;
  final bool isProfileComplete;
  final double totalSavings;
  final double totalPayments;

  ClientModel({
    required this.uid,
    required this.businessName,
    required this.category,
    required this.imageUrl,
    required this.address,
    required this.phoneNumber,
    required this.secondPhoneNumber,
    required this.geoPoint,
    required this.isProfileComplete,
    required this.totalSavings,
    required this.totalPayments,
  });

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      uid: map['uid'] ?? '',
      businessName: map['businessName'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      address: map['address'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      secondPhoneNumber: map['secondPhoneNumber'] ?? '',
      geoPoint: map['geoPoint'] ?? const GeoPoint(0, 0),
      isProfileComplete: map['isProfileComplete'] ?? false,
      totalSavings: map['totalSavings']?.toDouble() ?? 0.0,
      totalPayments: map['totalPayments']?.toDouble() ?? 0.0,
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
      'address': address,
      'phoneNumber': phoneNumber,
      'secondPhoneNumber': secondPhoneNumber,
      'geoPoint': geoPoint,
      'isProfileComplete': isProfileComplete,
      'totalSavings': totalSavings,
      'totalPayments': totalPayments,
    };
  }
}
