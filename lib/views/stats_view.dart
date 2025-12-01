import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // Import thư viện vẽ
import '../controllers/stats_controller.dart';

class StatsView extends StatefulWidget {
  const StatsView({super.key});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  // Bộ màu sắc cho biểu đồ (Nếu nhiều hơn 5 danh mục thì nó lặp lại)
  final List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    // Gọi hàm tính toán ngay khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsController>().fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StatsController>();
    final data = controller.categoryData;

    return Scaffold(
      appBar: AppBar(title: const Text("Thống Kê Kho Hàng")),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : data.isEmpty
              ? const Center(child: Text("Chưa có dữ liệu để thống kê"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        "Tỉ lệ tồn kho theo danh mục",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      
                      // 1. VẼ BIỂU ĐỒ TRÒN
                      SizedBox(
                        height: 250,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2, // Khoảng cách giữa các miếng
                            centerSpaceRadius: 40, // Độ rỗng ở giữa (Tạo hình bánh Donut)
                            sections: List.generate(data.length, (index) {
                              final categoryName = data.keys.elementAt(index);
                              final stock = data[categoryName]!;
                              final percent = (stock / controller.totalStock * 100);
                              
                              return PieChartSectionData(
                                color: _colors[index % _colors.length],
                                value: stock.toDouble(),
                                title: '${percent.toStringAsFixed(1)}%', // Hiển thị %
                                radius: 80,
                                titleStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),

                      // 2. CHÚ THÍCH (LEGEND)
                      Expanded(
                        child: ListView.builder(
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            final categoryName = data.keys.elementAt(index);
                            final stock = data[categoryName]!;
                            
                            return ListTile(
                              leading: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _colors[index % _colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              title: Text(categoryName),
                              trailing: Text(
                                "$stock sp",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // 3. TỔNG KẾT
                      Container(
                        padding: const EdgeInsets.all(15),
                        color: Colors.blue[50],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.warehouse),
                            const SizedBox(width: 10),
                            Text(
                              "Tổng tồn kho: ${controller.totalStock} sản phẩm",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
    );
  }
}