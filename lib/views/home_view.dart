import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart'; // Import for Scan

import '../controllers/auth_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/category_controller.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import 'add_product_view.dart';
import 'category_view.dart';
import 'checkout_view.dart';
import 'invoice_list_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String _filterCategory = 'Tất cả';

  String formatCurrency(double price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  // --- Scan to Search Logic ---
  void _scanToSearch() async {
    String? res = await SimpleBarcodeScanner.scanBarcode(
      context,
      barcodeAppBar: const BarcodeAppBar(
        appBarTitle: 'Quét để tìm hàng',
        centerTitle: false,
        enableBackButton: true,
        backButtonIcon: Icon(Icons.arrow_back_ios),
      ),
      isShowFlashIcon: true,
      delayMillis: 2000,
      cameraFace: CameraFace.back,
    );

    if (res != null && res != '-1' && res.isNotEmpty && mounted) {
      final controller = context.read<ProductController>();
      final product = await controller.getProductByBarcode(res);

      if (product != null && mounted) {
         Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductView(product: product)));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Không tìm thấy SP mã: $res"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // 1. Build Query
    Query query = FirebaseFirestore.instance.collection('products');

    // Filter by Owner (Critical for Privacy)
    if (user != null) {
      query = query.where('userId', isEqualTo: user.uid);
    }

    // Filter by Category
    if (_filterCategory != 'Tất cả') {
      query = query.where('category', isEqualTo: _filterCategory);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kho Hàng Online"),
        actions: [
          // Scan Button
          IconButton(
            tooltip: "Tìm hàng",
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanToSearch,
          ),
          IconButton(
            tooltip: "Bán hàng",
            icon: const Icon(Icons.shopping_cart, color: Colors.green),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutView()));
            },
          ),
          IconButton(
  tooltip: "Lịch sử đơn",
  icon: const Icon(Icons.receipt_long),
  onPressed: () {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceListView()));
  },
),
          IconButton(
            tooltip: "Danh mục",
            icon: const Icon(Icons.category),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryView())),
          ),
          IconButton(
            tooltip: "Đăng xuất",
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthController>().logout(),
          )
        ],
      ),
      body: Column(
        children: [
          // 2. Horizontal Category Filter
          SizedBox(
            height: 60,
            child: StreamBuilder<List<CategoryModel>>(
              stream: context.read<CategoryController>().categoriesStream,
              builder: (context, snapshot) {
                List<String> displayCats = ['Tất cả'];
                if (snapshot.hasData) {
                  displayCats.addAll(snapshot.data!.map((e) => e.name));
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  itemCount: displayCats.length,
                  itemBuilder: (context, index) {
                    final catName = displayCats[index];
                    final isSelected = _filterCategory == catName;
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(catName),
                        selected: isSelected,
                        onSelected: (selected) => setState(() => _filterCategory = catName),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // 3. Product Grid
          Expanded(
            child: StreamBuilder(
              stream: query.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                // Error Handling (Specifically for Index Error)
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text("Lỗi tải dữ liệu (Có thể thiếu Index): ${snapshot.error}", 
                        style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Chưa có sản phẩm nào", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72, // Adjusted for better fit
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    ProductModel product = ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductView(product: product))),
                      child: Card(
                        elevation: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                child: product.imageUrl.isNotEmpty
                                    ? Image.network(product.imageUrl, width: double.infinity, fit: BoxFit.cover,
                                        errorBuilder: (c,e,s) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)))
                                    : Container(color: Colors.grey[200], child: const Icon(Icons.image, size: 40)),
                              ),
                            ),
                            // Details
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(formatCurrency(product.sellPrice), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Kho: ${product.stock}", style: const TextStyle(fontSize: 12)),
                                      InkWell(
                                        onTap: () {
                                           showDialog(context: context, builder: (ctx) => AlertDialog(
                                             title: const Text("Xóa?"),
                                             content: Text("Xóa ${product.name}?"),
                                             actions: [
                                               TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Hủy")),
                                               TextButton(onPressed: (){
                                                 context.read<ProductController>().deleteProduct(product.id!);
                                                 Navigator.pop(ctx);
                                               }, child: const Text("Xóa", style: TextStyle(color: Colors.red))),
                                             ],
                                           ));
                                        },
                                        child: const Icon(Icons.delete_outline, color: Colors.red, size: 20)
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductView())),
        child: const Icon(Icons.add),
      ),
    );
  }
}