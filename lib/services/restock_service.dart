import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/restock_suggestion_model.dart';

class RestockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tính toán gợi ý nhập hàng cho sản phẩm
  ///
  /// Tham số:
  /// - product: Sản phẩm cần tính toán
  /// - lookbackDays: Số ngày quá khứ để phân tích lịch sử bán hàng (default: 30)
  /// - safetyStockDays: Số ngày tồn kho an toàn cần duy trì (default: 7)
  ///
  /// Công thức:
  /// 1. Tính trung bình bán/ngày từ lịch sử đơn hàng
  /// 2. Tính số ngày dự kiến hết hàng = tồn kho / trung bình bán/ngày
  /// 3. Tính số lượng cần nhập = (trung bình bán/ngày × safetyStockDays) - tồn kho hiện tại
  Future<RestockSuggestion?> calculateRestockSuggestion(
    ProductModel product, {
    int lookbackDays = 30,
    int safetyStockDays = 7,
    int minOrderQuantity = 10,
  }) async {
    try {
      // Bước 1: Lấy lịch sử bán hàng từ collection 'orders'
      final startDate = DateTime.now().subtract(Duration(days: lookbackDays));
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: product.userId)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .get();

      // Bước 2: Tính tổng số lượng bán được
      int totalQuantitySold = 0;
      for (var doc in ordersSnapshot.docs) {
        final products = doc['products'] as List<dynamic>? ?? [];
        for (var item in products) {
          if (item['name'] == product.name) {
            totalQuantitySold += (item['quantity'] as num?)?.toInt() ?? 0;
          }
        }
      }

      // Bước 3: Tính trung bình bán/ngày
      double avgDailySales = lookbackDays > 0
          ? totalQuantitySold / lookbackDays
          : 0;

      // Nếu không có lịch sử bán, giả sử tối thiểu 1 cái/ngày để không chia cho 0
      if (avgDailySales == 0) {
        avgDailySales = 1.0;
      }

      // Bước 4: Tính số ngày dự kiến hết hàng
      int daysUntilStockout = product.stock > 0
          ? (product.stock / avgDailySales).ceil()
          : 0;

      // Bước 5: Tính số lượng nên nhập
      // Công thức: (trung bình bán/ngày × số ngày an toàn) - tồn kho hiện tại
      int suggestedQuantity =
          ((avgDailySales * safetyStockDays).ceil() - product.stock)
              .clamp(0, double.infinity)
              .toInt();

      // ⚠️ CẢNH BÁO: Sản phẩm tồn kho dưới 5 → đảm bảo luôn có gợi ý nhập
      if (product.stock < 5 && suggestedQuantity == 0) {
        suggestedQuantity = minOrderQuantity;
      }

      // ⚠️ Nếu sản phẩm dưới 5 ngày → đảm bảo luôn có gợi ý nhập
      if (daysUntilStockout < 5 && suggestedQuantity == 0) {
        suggestedQuantity = minOrderQuantity;
      }

      // Đảm bảo số lượng tối thiểu
      if (suggestedQuantity > 0 && suggestedQuantity < minOrderQuantity) {
        suggestedQuantity = minOrderQuantity;
      }

      return RestockSuggestion(
        productId: product.id ?? '',
        productName: product.name,
        currentStock: product.stock,
        avgDailySales: double.parse(avgDailySales.toStringAsFixed(2)),
        daysUntilStockout: daysUntilStockout,
        suggestedQuantity: suggestedQuantity,
        importPrice: product.importPrice,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      print("Lỗi tính toán gợi ý nhập hàng: $e");
      return null;
    }
  }

  /// Lấy danh sách gợi ý nhập hàng cho tất cả sản phẩm của người dùng
  /// Chỉ bao gồm sản phẩm có daysUntilStockout <= maxDaysThreshold
  Future<List<RestockSuggestion>> getRestockSuggestions(
    String userId, {
    int lookbackDays = 30,
    int safetyStockDays = 7,
    int maxDaysThreshold = 14,
    int minOrderQuantity = 10,
  }) async {
    try {
      // Lấy tất cả sản phẩm của người dùng
      final productsSnapshot = await _firestore
          .collection('products')
          .where('userId', isEqualTo: userId)
          .get();

      List<RestockSuggestion> suggestions = [];

      // Tính toán gợi ý cho từng sản phẩm
      for (var doc in productsSnapshot.docs) {
        final product = ProductModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

        final suggestion = await calculateRestockSuggestion(
          product,
          lookbackDays: lookbackDays,
          safetyStockDays: safetyStockDays,
          minOrderQuantity: minOrderQuantity,
        );

        // Điều kiện thêm vào danh sách gợi ý:
        // 1. Sản phẩm có tồn kho < 5 sản phẩm -> CẢNH BÁO SẮP HẾT
        // 2. Sản phẩm dưới 5 ngày -> BẮT BUỘC hiển thị (cấp bách)
        // 3. Hoặc sản phẩm trong ngưỡng maxDays VÀ cần nhập (suggestedQuantity > 0)
        if (suggestion != null) {
          final lowStock = suggestion.currentStock < 5;
          final isUrgent = suggestion.daysUntilStockout < 5;
          final needsRestock =
              suggestion.daysUntilStockout <= maxDaysThreshold &&
              suggestion.suggestedQuantity > 0;

          if (lowStock || isUrgent || needsRestock) {
            suggestions.add(suggestion);
          }
        }
      }

      // Sắp xếp theo mức độ ưu tiên (critical → high → medium → low)
      suggestions.sort((a, b) {
        final priorityOrder = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3};
        final aPriority =
            priorityOrder[a.priority.toString().split('.').last] ?? 3;
        final bPriority =
            priorityOrder[b.priority.toString().split('.').last] ?? 3;
        return aPriority.compareTo(bPriority);
      });

      return suggestions;
    } catch (e) {
      print("Lỗi lấy danh sách gợi ý: $e");
      return [];
    }
  }

  /// Lấy thống kê tổng chi phí nhập hàng gợi ý
  Future<double> getTotalEstimatedCost(
    List<RestockSuggestion> suggestions,
  ) async {
    return suggestions.fold<double>(
      0.0,
      (sum, item) => sum + item.estimatedCost,
    );
  }

  /// Lấy số lượng sản phẩm cần nhập khẩn cấp (critical)
  int getCriticalProductsCount(List<RestockSuggestion> suggestions) {
    return suggestions
        .where((s) => s.priority == PriorityLevel.critical)
        .length;
  }
}
