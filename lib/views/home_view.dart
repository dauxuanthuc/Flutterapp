import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Auth

// Import các file cần thiết
import '../controllers/auth_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/category_controller.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import 'add_product_view.dart';
import 'category_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String _filterCategory = 'Tất cả';

  // Hàm format tiền tệ
  String formatCurrency(double price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Lấy thông tin User hiện tại
    final user = FirebaseAuth.instance.currentUser;

    // 2. Tạo Query cơ bản
    Query query = FirebaseFirestore.instance.collection('products');

    // --- CỐT LÕI CỦA VIỆC PHÂN QUYỀN ---
    // Chỉ lấy sản phẩm có userId trùng với người đang đăng nhập
    if (user != null) {
      query = query.where('userId', isEqualTo: user.uid);
    }

    // 3. Logic lọc theo danh mục
    if (_filterCategory != 'Tất cả') {
      query = query.where('category', isEqualTo: _filterCategory);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kho Hàng Online"),
        actions: [
          // Nút Quản lý danh mục
          IconButton(
            tooltip: "Quản lý danh mục",
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoryView()),
              );
            },
          ),
          // Nút Đăng xuất
          IconButton(
            tooltip: "Đăng xuất",
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthController>().logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 4. BỘ LỌC DANH MỤC NGANG (Lấy từ Firebase thông qua Controller)
          // CategoryController đã tự lọc theo userId rồi, nên ở đây cứ hiển thị thôi
          SizedBox(
            height: 60,
            child: StreamBuilder<List<CategoryModel>>(
              stream: context.read<CategoryController>().categoriesStream,
              builder: (context, snapshot) {
                // Tạo danh sách hiển thị: Luôn có chữ "Tất cả" ở đầu
                List<String> displayCats = ['Tất cả'];

                if (snapshot.hasData) {
                  displayCats.addAll(snapshot.data!.map((e) => e.name));
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  itemCount: displayCats.length,
                  itemBuilder: (context, index) {
                    final catName = displayCats[index];
                    final isSelected = _filterCategory == catName;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(catName),
                        selected: isSelected,
                        selectedColor: Colors.blue[100],
                        onSelected: (selected) {
                          setState(() => _filterCategory = catName);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 5. LƯỚI SẢN PHẨM (GRID)
          Expanded(
            child: StreamBuilder(
              stream: query.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());

                // Xử lý khi không có dữ liệu
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 60,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Kho trống! Hãy thêm sản phẩm mới.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75, // Tỷ lệ khung hình
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    ProductModel product = ProductModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    );

                    return GestureDetector(
                      onTap: () {
                        // Bấm vào để Sửa
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddProductView(product: product),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ảnh sản phẩm
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(10),
                                ),
                                child: product.imageUrl.isNotEmpty
                                    ? Image.network(
                                        product.imageUrl,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) =>
                                            const Icon(Icons.broken_image),
                                      )
                                    : Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(Icons.image, size: 40),
                                        ),
                                      ),
                              ),
                            ),
                            // Thông tin
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatCurrency(product.sellPrice),
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Kho: ${product.stock}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      // Nút xóa nhanh
                                      InkWell(
                                        onTap: () {
                                          // Xác nhận xóa
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text(
                                                "Xóa sản phẩm?",
                                              ),
                                              content: Text(
                                                "Bạn có chắc muốn xóa ${product.name}?",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx),
                                                  child: const Text("Hủy"),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    context
                                                        .read<
                                                          ProductController
                                                        >()
                                                        .deleteProduct(
                                                          product.id!,
                                                        );
                                                    Navigator.pop(ctx);
                                                  },
                                                  child: const Text(
                                                    "Xóa",
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
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
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductView()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
