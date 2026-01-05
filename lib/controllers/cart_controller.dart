import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../services/notification_service.dart';

class CartController extends ChangeNotifier {

  final Map<String, CartItemModel> _items = {};

  Map<String, CartItemModel> get items => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.totalPrice;
    });
    return total;
  }

  // 1. THÊM VÀO GIỎ
  void addToCart(ProductModel product) {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id!,
        (existing) => CartItemModel(
          id: existing.id,
          product: existing.product,
          quantity: existing.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        product.id!,
        () => CartItemModel(id: product.id!, product: product, quantity: 1),
      );
    }
    notifyListeners();
  }

  // 2. GIẢM SỐ LƯỢNG
  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;

    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existing) => CartItemModel(
          id: existing.id,
          product: existing.product,
          quantity: existing.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  // Xóa hẳn sản phẩm khỏi giỏ
  void deleteItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  // Xóa sạch giỏ hàng
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // --- 3. CHỨC NĂNG THANH TOÁN  ---
  Future<void> checkout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _items.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    final firestore = FirebaseFirestore.instance;

    try {
      await firestore.runTransaction((transaction) async {

        for (var item in _items.values) {
          final productRef = firestore
              .collection('products')
              .doc(item.product.id);
          final snapshot = await transaction.get(productRef);

          if (!snapshot.exists) {
            throw Exception("Sản phẩm '${item.product.name}' không tồn tại!");
          }


          int currentStock = snapshot.data()!['stock'] ?? 0;

          if (currentStock < item.quantity) {
            throw Exception(
              "Sản phẩm '${item.product.name}' chỉ còn $currentStock cái. Không đủ hàng!",
            );
          }

          int newStock = currentStock - item.quantity;
          transaction.update(productRef, {'stock': newStock});
        }

        final orderRef = firestore.collection('orders').doc();

        List<Map<String, dynamic>> orderItems = _items.values.map((item) {
          return {
            'productId': item.product.id,
            'name': item.product.name,
            'quantity': item.quantity,
            'price': item.product.sellPrice,
          };
        }).toList();

        transaction.set(orderRef, {
          'userId': user.uid,
          'totalAmount': totalAmount,
          'date': Timestamp.now(), 
          'products': orderItems, 
        });
      });

      // --- LOGIC SAU KHI THÀNH CÔNG ---

      // Kiểm tra cảnh báo nhập hàng (Dùng dữ liệu cục bộ để báo nhanh)
      int notificationId = 0;
      for (var item in _items.values) {
        int estimatedRemaining = item.product.stock - item.quantity;
        if (estimatedRemaining < 5) {
          NotificationService.showWarningNotification(
            id: notificationId++,
            title: '⚠️ Báo động đỏ: ${item.product.name}',
            body:
                'Ước tính chỉ còn khoảng $estimatedRemaining sản phẩm. Nhập hàng ngay!',
          );
        }
      }

      clearCart(); 
    } catch (e) {
      print("Lỗi thanh toán: $e");
      rethrow; 
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
