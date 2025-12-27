class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final String category;
  final String imageUrl;
  final bool isAvailable;
  final int stockQuantity;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
    this.isAvailable = true,
    this.stockQuantity = 0,
  });

  // Convert from Firestore document
  factory Product.fromMap(Map<String, dynamic> map, String documentId) {
    return Product(
      id: documentId,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      category: map['category'] ?? 'Other',
      imageUrl: map['imageUrl'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      stockQuantity: (map['stockQuantity'] ?? 0) as int,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Added for cart persistence
      'name': name,
      'price': price,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'stockQuantity': stockQuantity,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    String? category,
    String? imageUrl,
    bool? isAvailable,
    int? stockQuantity,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      stockQuantity: stockQuantity ?? this.stockQuantity,
    );
  }
}
