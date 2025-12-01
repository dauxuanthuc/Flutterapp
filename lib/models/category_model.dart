class CategoryModel {
  String? id;
  String name;
  String userId;

  CategoryModel({this.id, required this.name, required this.userId});

  // Từ Firestore về App
  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(id: id, name: map['name'] ?? '', userId: map['userId'] ?? '');
  }

  // Từ App lên Firestore
  Map<String, dynamic> toMap() {
    return {'name': name, 'userId': userId};
  }
}
