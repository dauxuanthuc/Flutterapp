import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../controllers/auth_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/category_controller.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import 'add_product_view.dart';
import 'category_view.dart';
import 'checkout_view.dart';
import 'invoice_list_view.dart';
import 'stats_view.dart';
import 'login_view.dart';
import 'restock_suggestion_screen.dart';
import 'restock_test_screen.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String _filterCategory = 'Tất cả';
  int _selectedIndex = 0; // Quản lý index của BottomBar

  String formatCurrency(double price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  void _scanToSearch() async {
    String? res = await SimpleBarcodeScanner.scanBarcode(
      context,
      barcodeAppBar: const BarcodeAppBar(appBarTitle: 'Quét mã sản phẩm'),
      isShowFlashIcon: true,
      cameraFace: CameraFace.back,
    );

    if (res != null && res != '-1' && res.isNotEmpty && mounted) {
      final controller = context.read<ProductController>();
      final product = await controller.getProductByBarcode(res);

      if (product != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddProductView(product: product)),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Không tìm thấy sản phẩm: $res"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Hàm xử lý khi bấm vào BottomBar
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CheckoutView()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InvoiceListView()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StatsView()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    Query query = FirebaseFirestore.instance.collection('products');
    if (user != null) query = query.where('userId', isEqualTo: user.uid);
    if (_filterCategory != 'Tất cả')
      query = query.where('category', isEqualTo: _filterCategory);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          "Kho Hàng Online",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanToSearch,
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'category') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoryView()),
                );
              } else if (value == 'restock') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RestockSuggestionScreen(),
                  ),
                );
              } else if (value == 'test_restock') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RestockTestScreen()),
                );
              } else if (value == 'logout') {
                await context.read<AuthController>().logout();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginView()),
                    (route) => false,
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'category',
                child: Row(
                  children: [
                    Icon(Icons.category, size: 18),
                    SizedBox(width: 8),
                    Text("Danh mục"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'restock',
                child: Row(
                  children: [
                    Icon(Icons.inventory, size: 18, color: Colors.orange),
                    SizedBox(width: 8),
                    Text("Gợi ý nhập hàng"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Đăng xuất"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Bộ lọc danh mục (Chip Filter)
          _buildCategoryFilter(),

          // Danh sách sản phẩm
          Expanded(child: _buildProductGrid(query)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[800],
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddProductView()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Kho hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Bán hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Hóa đơn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Thống kê',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      color: Colors.white,
      child: StreamBuilder<List<CategoryModel>>(
        stream: context.read<CategoryController>().categoriesStream,
        builder: (context, snapshot) {
          List<String> displayCats = ['Tất cả'];
          if (snapshot.hasData)
            displayCats.addAll(snapshot.data!.map((e) => e.name));

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: displayCats.length,
            itemBuilder: (context, index) {
              final catName = displayCats[index];
              final isSelected = _filterCategory == catName;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(catName),
                  selected: isSelected,
                  selectedColor: Colors.blue[100],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.blue[800] : Colors.black,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  onSelected: (_) => setState(() => _filterCategory = catName),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(Query query) {
    return StreamBuilder(
      stream: query.snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return _buildEmptyState();

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            ProductModel product = ProductModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );

            return _buildProductCard(product);
          },
        );
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddProductView(product: product)),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCurrency(product.sellPrice),
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Tồn: ${product.stock}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      GestureDetector(
                        onTap: () => _confirmDelete(product),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc muốn xóa ${product.name}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              context.read<ProductController>().deleteProduct(product.id!);
              Navigator.pop(ctx);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            "Kho hàng trống",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
