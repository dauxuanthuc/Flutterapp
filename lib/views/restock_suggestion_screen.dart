import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/product_controller.dart';
import '../models/restock_suggestion_model.dart';

class RestockSuggestionScreen extends StatefulWidget {
  const RestockSuggestionScreen({Key? key}) : super(key: key);

  @override
  State<RestockSuggestionScreen> createState() =>
      _RestockSuggestionScreenState();
}

class _RestockSuggestionScreenState extends State<RestockSuggestionScreen> {
  @override
  void initState() {
    super.initState();
    // Load gợi ý khi mở màn hình
    Future.microtask(() {
      context.read<ProductController>().loadRestockSuggestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gợi ý nhập hàng thông minh'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ProductController>().loadRestockSuggestions();
            },
          ),
        ],
      ),
      body: Consumer<ProductController>(
        builder: (context, controller, _) {
          if (controller.isLoadingSuggestions) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.restockSuggestions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.green.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tất cả sản phẩm đều đủ hàng',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Không có sản phẩm nào cần nhập khẩn cấp',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.restockSuggestions.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildStatisticsCard(context, controller);
              }

              final suggestion = controller.restockSuggestions[index - 1];
              return _buildRestockCard(suggestion);
            },
          );
        },
      ),
    );
  }

  Widget _buildStatisticsCard(
    BuildContext context,
    ProductController controller,
  ) {
    return FutureBuilder<Map<String, dynamic>>(
      future: controller.getRestockStatistics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;

        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade800],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thống kê nhập hàng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      label: 'Sản phẩm cần nhập',
                      value: '${stats['totalSuggestions']}',
                      color: Colors.white,
                    ),
                    _buildStatItem(
                      label: 'Khẩn cấp',
                      value: '${stats['criticalProducts']}',
                      color: Colors.red.shade200,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatItem(
                  label: 'Tổng chi phí dự kiến',
                  value:
                      '${(stats['totalEstimatedCost'] as num).toStringAsFixed(0)} đ',
                  color: Colors.white,
                  fontSize: 14,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
    double fontSize = 18,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRestockCard(RestockSuggestion suggestion) {
    final Color priorityColor = _hexToColor(suggestion.priorityColor);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: priorityColor, width: 5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion.productName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mã sản phẩm: ${suggestion.productId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        // Hiển thị cảnh báo chi tiết
                        if (suggestion.warningMessage.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            suggestion.warningMessage,
                            style: TextStyle(
                              fontSize: 12,
                              color: priorityColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      suggestion.priorityLabel,
                      style: TextStyle(
                        color: priorityColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Thông tin chi tiết
              _buildInfoRow(
                label: 'Tồn kho hiện tại:',
                value: '${suggestion.currentStock} sản phẩm',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                label: 'Bán trung bình:',
                value: '${suggestion.avgDailySales.toStringAsFixed(1)}/ngày',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                label: 'Dự kiến hết hàng:',
                value: '${suggestion.daysUntilStockout} ngày',
              ),
              const SizedBox(height: 16),
              // Gợi ý nhập hàng
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gợi ý nhập:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${suggestion.suggestedQuantity} sản phẩm',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          TextSpan(
                            text:
                                ' × ${suggestion.importPrice.toStringAsFixed(0)} đ = ',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          TextSpan(
                            text:
                                '${suggestion.estimatedCost.toStringAsFixed(0)} đ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
    } else if (hexString.length == 8) {
      buffer.write(hexString.replaceFirst('#', ''));
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
