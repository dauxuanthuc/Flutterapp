import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  String id;
  String userId;
  double totalAmount;
  DateTime date;
  List<Map<String, dynamic>> products; // List các map: {name, quantity, price}

  OrderModel({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.date,
    required this.products,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      products: List<Map<String, dynamic>>.from(map['products'] ?? []),
    );
  }
}