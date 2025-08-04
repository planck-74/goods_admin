class CarouselImageModel {
  final String id;
  final String imageUrl;
  final int order;
  final bool isActive;
  final DateTime createdAt;

  CarouselImageModel({
    required this.id,
    required this.imageUrl,
    required this.order,
    this.isActive = true,
    required this.createdAt,
  });

  factory CarouselImageModel.fromMap(Map<String, dynamic> map, String id) {
    return CarouselImageModel(
      id: id,
      imageUrl: map['imageUrl'] ?? '',
      order: map['order'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'order': order,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
