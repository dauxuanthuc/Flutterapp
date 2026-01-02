import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/product_controller.dart';
import '../models/restock_suggestion_model.dart';

/// Widget này dùng để TEST chức năng gợi ý nhập hàng
/// Hiển thị thông tin chi tiết về cách tính toán
class RestockTestScreen extends StatefulWidget {
  const RestockTestScreen({Key? key}) : super(key: key);

  @override
  State<RestockTestScreen> createState() => _RestockTestScreenState();
}

class _RestockTestScreenState extends State<RestockTestScreen> {
  bool _isLoading = false;
  List<RestockSuggestion> _suggestions = [];
  Map<String, dynamic>? _stats;

  // Các tham số có thể điều chỉnh để test
  int _lookbackDays = 30;
  int _safetyStockDays = 7;
  int _maxDaysThreshold = 14;
  int _minOrderQuantity = 10;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final controller = context.read<ProductController>();

      // Load gợi ý với tham số hiện tại
      await controller.loadRestockSuggestions(
        lookbackDays: _lookbackDays,
        safetyStockDays: _safetyStockDays,
        maxDaysThreshold: _maxDaysThreshold,
        minOrderQuantity: _minOrderQuantity,
      );

      // Lấy dữ liệu từ controller
      _suggestions = controller.restockSuggestions;
      _stats = await controller.getRestockStatistics();
    } catch (e) {
      print('Lỗi test: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TEST - Gợi ý nhập hàng'),
        backgroundColor: Colors.purple.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTestInfoCard(),
                  const SizedBox(height: 16),
                  _buildStatisticsCard(),
                  const SizedBox(height: 16),
                  _buildSuggestionsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildTestInfoCard() {
    return Card(
      color: Colors.purple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Text(
                  'Thông tin TEST',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Phân tích lịch sử', '$_lookbackDays ngày'),
            _buildInfoRow('Tồn kho an toàn', '$_safetyStockDays ngày'),
            _buildInfoRow('Ngưỡng cảnh báo', '<= $_maxDaysThreshold ngày'),
            _buildInfoRow('Đơn hàng tối thiểu', '$_minOrderQuantity sản phẩm'),
            const SizedBox(height: 12),
            const Text(
              '💡 Công thức tính:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            const Text(
              '• Ngày tồn = Tồn kho / TB bán/ngày\n'
              '• SL nhập = (TB bán/ngày × Ngày an toàn) - Tồn kho',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    if (_stats == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade800],
          ),
        ),
        child: Column(
          children: [
            const Text(
              'THỐNG KÊ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  'Tổng SP',
                  '${_stats!['totalSuggestions']}',
                  Colors.white,
                ),
                _buildStatColumn(
                  'Cấp bách',
                  '${_stats!['criticalProducts']}',
                  Colors.red.shade200,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatColumn(
              'Chi phí dự kiến',
              '${(_stats!['totalEstimatedCost'] as num).toStringAsFixed(0)} đ',
              Colors.yellow.shade200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: color.withOpacity(0.9), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh sách gợi ý (${_suggestions.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_suggestions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                '✅ Không có sản phẩm nào cần nhập',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ..._suggestions.map((s) => _buildSuggestionCard(s)),
      ],
    );
  }

  Widget _buildSuggestionCard(RestockSuggestion suggestion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _hexToColor(suggestion.priorityColor),
          child: Text(
            suggestion.daysUntilStockout.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          suggestion.productName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${suggestion.priorityLabel} • ${suggestion.currentStock} tồn',
          style: TextStyle(color: _hexToColor(suggestion.priorityColor)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  '🔢 Tồn kho hiện tại:',
                  '${suggestion.currentStock}',
                ),
                _buildDetailRow(
                  '📊 Trung bình bán:',
                  '${suggestion.avgDailySales}/ngày',
                ),
                _buildDetailRow(
                  '⏰ Ngày còn lại:',
                  '${suggestion.daysUntilStockout} ngày',
                ),
                _buildDetailRow(
                  '📦 Số lượng nên nhập:',
                  '${suggestion.suggestedQuantity}',
                ),
                _buildDetailRow(
                  '💰 Giá nhập:',
                  '${suggestion.importPrice.toStringAsFixed(0)} đ',
                ),
                _buildDetailRow(
                  '💵 Chi phí nhập:',
                  '${suggestion.estimatedCost.toStringAsFixed(0)} đ',
                  isBold: true,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '💡 Gợi ý: Nhập ${suggestion.suggestedQuantity} sản phẩm để duy trì tồn kho $_safetyStockDays ngày',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.orange.shade700 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cài đặt TEST'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSlider(
                'Phân tích lịch sử (ngày)',
                _lookbackDays.toDouble(),
                7,
                90,
                (val) => setState(() => _lookbackDays = val.toInt()),
              ),
              _buildSlider(
                'Tồn kho an toàn (ngày)',
                _safetyStockDays.toDouble(),
                3,
                30,
                (val) => setState(() => _safetyStockDays = val.toInt()),
              ),
              _buildSlider(
                'Ngưỡng cảnh báo (ngày)',
                _maxDaysThreshold.toDouble(),
                3,
                30,
                (val) => setState(() => _maxDaysThreshold = val.toInt()),
              ),
              _buildSlider(
                'Đơn hàng tối thiểu',
                _minOrderQuantity.toDouble(),
                1,
                50,
                (val) => setState(() => _minOrderQuantity = val.toInt()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('ÁP DỤNG'),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toInt()}'),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
