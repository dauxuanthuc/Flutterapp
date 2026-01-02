import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/product_controller.dart';

class RestockQuickSummaryCard extends StatefulWidget {
  final VoidCallback? onTap;

  const RestockQuickSummaryCard({Key? key, this.onTap}) : super(key: key);

  @override
  State<RestockQuickSummaryCard> createState() =>
      _RestockQuickSummaryCardState();
}

class _RestockQuickSummaryCardState extends State<RestockQuickSummaryCard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ProductController>().loadRestockSuggestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductController>(
      builder: (context, controller, _) {
        final totalSuggestions = controller.restockSuggestions.length;
        final criticalCount = controller.restockSuggestions
            .where((s) => s.daysUntilStockout <= 2)
            .length;

        return GestureDetector(
          onTap: widget.onTap,
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Colors.orange.shade600, Colors.orange.shade700],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nhập hàng thông minh',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalSuggestions > 0
                              ? '$totalSuggestions sản phẩm cần nhập (${criticalCount > 0 ? '$criticalCount cấp bách' : 'bình thường'})'
                              : 'Tất cả sản phẩm đều đủ hàng',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (criticalCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$criticalCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
