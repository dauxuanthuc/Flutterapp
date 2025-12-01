import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';

class CartController extends ChangeNotifier {
  // Danh sách hàng trong giỏ
  final Map<String, CartItemModel> _items = {};

  Map<String, CartItemModel> get items => _items;

  // Tổng số lượng sản phẩm
  int get itemCount => _items.length;

  // Tổng tiền cần thanh toán
  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.totalPrice;
    });
    return total;
  }

  // 1. THÊM VÀO GIỎ (Quét mã hoặc chọn tay đều gọi hàm này)
  void addToCart(ProductModel product) {
    if (_items.containsKey(product.id)) {
      // Nếu có rồi -> Tăng số lượng
      _items.update(
        product.id!,
        (existing) => CartItemModel(
          id: existing.id,
          product: existing.product,
          quantity: existing.quantity + 1,
        ),
      );
    } else {
      // Chưa có -> Thêm mới
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
              quantity: existing.quantity - 1));
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

  // --- 3. CHỨC NĂNG THANH TOÁN (XUẤT KHO) ---
  Future<void> checkout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _items.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch(); // Dùng Batch để đảm bảo an toàn dữ liệu

    try {
      // A. Tạo đơn hàng lưu vào lịch sử (Orders)
      final orderRef = firestore.collection('orders').doc();
      batch.set(orderRef, {
        'userId': user.uid,
        'totalAmount': totalAmount,
        'date': Timestamp.now(),
        'products': _items.values.map((item) => {
          'productId': item.product.id,
          'name': item.product.name,
          'quantity': item.quantity,
          'price': item.product.sellPrice,
        }).toList(),
      });

      // B. Trừ tồn kho (Stock Out)
      for (var item in _items.values) {
        final productRef = firestore.collection('products').doc(item.product.id);
        
        // Logic trừ: Tồn kho mới = Tồn kho cũ - Số lượng mua
        // Lưu ý: Trong thực tế cần check xem còn đủ hàng không, ở đây làm đơn giản
        batch.update(productRef, {
          'stock': FieldValue.increment(-item.quantity), 
        });
      }

      // C. Thực thi lệnh
      await batch.commit();
      
      // D. Xóa giỏ hàng sau khi bán xong
      clearCart();
      
    } catch (e) {
      print("Lỗi thanh toán: $e");
      rethrow;
    }
  }
}