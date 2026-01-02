class RestockSuggestion {
  String productId;
  String productName;
  int currentStock;
  double avgDailySales; // Trung bình bán/ngày
  int daysUntilStockout; // Số ngày dự kiến hết hàng
  int suggestedQuantity; // Số lượng nên nhập
  double importPrice; // Giá nhập
  DateTime generatedAt;

  RestockSuggestion({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.avgDailySales,
    required this.daysUntilStockout,
    required this.suggestedQuantity,
    required this.importPrice,
    required this.generatedAt,
  });

  // Tính toán chi phí nhập hàng gợi ý
  double get estimatedCost => suggestedQuantity * importPrice;

  // Phân loại mức độ ưu tiên
  PriorityLevel get priority {
    // ⚠️ Ưu tiên cao nhất: Tồn kho dưới 5 sản phẩm (cảnh báo sắp hết)
    if (currentStock < 5) {
      return PriorityLevel.critical;
    }
    // Ưu tiên theo số ngày còn lại
    if (daysUntilStockout <= 2) {
      return PriorityLevel.critical;
    } else if (daysUntilStockout <= 5) {
      return PriorityLevel.high;
    } else if (daysUntilStockout <= 10) {
      return PriorityLevel.medium;
    }
    return PriorityLevel.low;
  }

  // Lấy màu theo mức độ ưu tiên
  String get priorityColor {
    switch (priority) {
      case PriorityLevel.critical:
        return '#FF6B6B'; // Đỏ
      case PriorityLevel.high:
        return '#FFA500'; // Cam
      case PriorityLevel.medium:
        return '#FFD93D'; // Vàng
      case PriorityLevel.low:
        return '#6BCF7F'; // Xanh
    }
  }

  // Lấy nhãn theo mức độ ưu tiên
  String get priorityLabel {
    switch (priority) {
      case PriorityLevel.critical:
        return 'Cấp bách';
      case PriorityLevel.high:
        return 'Cao';
      case PriorityLevel.medium:
        return 'Trung bình';
      case PriorityLevel.low:
        return 'Thấp';
    }
  }

  // Kiểm tra loại cảnh báo
  bool get isLowStockWarning => currentStock < 5;
  bool get isLowDaysWarning => daysUntilStockout < 5;

  // Lấy text cảnh báo chi tiết
  String get warningMessage {
    if (currentStock < 5 && daysUntilStockout < 5) {
      return '⚠️ Tồn kho thấp & Sắp hết trong $daysUntilStockout ngày';
    } else if (currentStock < 5) {
      return '⚠️ Cảnh báo: Chỉ còn $currentStock sản phẩm';
    } else if (daysUntilStockout < 5) {
      return '⏰ Dự kiến hết trong $daysUntilStockout ngày';
    }
    return '';
  }
}

enum PriorityLevel { critical, high, medium, low }
