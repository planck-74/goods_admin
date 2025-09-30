import 'package:cloud_firestore/cloud_firestore.dart';

class Manufacturer {
  final String id;
  final String name;
  final String imageUrl;
  final List<String> productsIds;
  final int number;

  Manufacturer({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.productsIds,
    required this.number,
  });

  factory Manufacturer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Manufacturer(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      productsIds: List<String>.from(data['productsIds'] ?? []),
      number: data['number'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'productsIds': productsIds,
      'number': number,
    };
  }

  Manufacturer copyWith({
    String? id,
    String? name,
    String? imageUrl,
    List<String>? productsIds,
    int? number,
  }) {
    return Manufacturer(
        id: id ?? this.id,
        name: name ?? this.name,
        imageUrl: imageUrl ?? this.imageUrl,
        productsIds: productsIds ?? this.productsIds,
        number: number ?? this.number);
  }
}
