import 'product_model.dart';

class CartItemModel {
  String id; // ID riêng của item trong giỏ (thường dùng ID sản phẩm luôn)
  ProductModel product;
  int quantity;

  CartItemModel({
    required this.id,
    required this.product,
    this.quantity = 1,
  });

  // Tính tổng tiền của item này (Giá bán * Số lượng)
  double get totalPrice => product.sellPrice * quantity;
}