import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';

class StatsController extends ChangeNotifier {
  Map<String, int> _categoryData = {}; // Map: Tên Danh Mục -> Tổng Tồn Kho
  int _totalStock = 0; // Tổng tất cả hàng trong kho
  bool _isLoading = false;

  Map<String, int> get categoryData => _categoryData;
  int get totalStock => _totalStock;
  bool get isLoading => _isLoading;

  // Hàm lấy dữ liệu và tính toán
  Future<void> fetchStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('userId', isEqualTo: user.uid)
          .get();

      // Reset dữ liệu cũ
      _categoryData = {};
      _totalStock = 0;

      for (var doc in snapshot.docs) {
        final product = ProductModel.fromMap(doc.data(), doc.id);
        
        // 1. Cộng dồn tổng kho
        _totalStock += product.stock;

        // 2. Cộng dồn theo danh mục
        if (_categoryData.containsKey(product.category)) {
          _categoryData[product.category] = _categoryData[product.category]! + product.stock;
        } else {
          _categoryData[product.category] = product.stock;
        }
      }

    } catch (e) {
      print("Lỗi thống kê: $e");
    }

    _isLoading = false;
    notifyListeners();
  }
}