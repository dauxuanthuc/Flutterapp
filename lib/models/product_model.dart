class ProductModel {
  String? id;
  String name;
  String barcode;
  double importPrice; // Giá nhập
  double sellPrice;   // Giá bán
  int stock;          // Tồn kho
  String description;
  String category;    // Danh mục
  String imageUrl;  
  String userId;      // Chủ sở hữu

  ProductModel({
    this.id,
    required this.name,
    required this.barcode,
    required this.importPrice,
    required this.sellPrice,
    required this.stock,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.userId,
  });

  // Chuyển từ Firestore xuống App
  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      barcode: map['barcode'] ?? '',
      importPrice: (map['importPrice'] ?? 0).toDouble(),
      sellPrice: (map['sellPrice'] ?? 0).toDouble(),
      stock: map['stock'] ?? 0,
      description: map['description'] ?? '',
      category: map['category'] ?? 'Khác',
      imageUrl: map['imageUrl'] ?? '',
      userId: map['userId'] ?? '',
    );
  }

  // Chuyển từ App lên Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'barcode': barcode,
      'importPrice': importPrice,
      'sellPrice': sellPrice,
      'stock': stock,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'userId': userId,
    };
  }
}