import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';

class OrderController extends ChangeNotifier {
  final CollectionReference _orderRef = FirebaseFirestore.instance.collection('orders');

  // Lấy danh sách hóa đơn của User hiện tại
  Stream<List<OrderModel>> get ordersStream {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _orderRef
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true) // Mới nhất lên đầu
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}