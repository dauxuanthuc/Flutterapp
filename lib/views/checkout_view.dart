import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/cart_controller.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  // Hàm format tiền
  String formatCurrency(double price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  // --- 1. HÀM QUÉT MÃ (GIỮ NGUYÊN) ---
  void _scanToAdd() async {
    String? res = await SimpleBarcodeScanner.scanBarcode(
      context,
      barcodeAppBar: const BarcodeAppBar(
        appBarTitle: 'Quét bán hàng',
        centerTitle: false,
        enableBackButton: true,
        backButtonIcon: Icon(Icons.arrow_back_ios),
      ),
      isShowFlashIcon: true,
      delayMillis: 2000,
      cameraFace: CameraFace.back,
    );

    if (res != null && res != '-1' && res.isNotEmpty && mounted) {
      final productController = context.read<ProductController>();
      final product = await productController.getProductByBarcode(res);

      if (product != null && mounted) {
         context.read<CartController>().addToCart(product);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã thêm: ${product.name}")));
      } else if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không tìm thấy sản phẩm!"), backgroundColor: Colors.red));
      }
    }
  }

  // --- 2. HÀM MỞ DANH SÁCH TÌM KIẾM THỦ CÔNG (MỚI) ---
  void _showSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Để full chiều cao khi cần
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => const SearchProductSheet(),
    );
  }

  // --- 3. HÀM THANH TOÁN (GIỮ NGUYÊN) ---
  void _processCheckout() async {
    try {
      await context.read<CartController>().checkout();
      if(mounted) {
        showDialog(
          context: context, 
          builder: (ctx) => AlertDialog(
            title: const Text("Thành công!"),
            content: const Text("Đã xuất kho và lưu đơn hàng."),
            actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("OK"))],
          )
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();

    return Scaffold(
      appBar: AppBar(title: const Text("Bán Hàng / Xuất Kho")),
      body: Column(
        children: [
          // KHU VỰC CHỨC NĂNG (QUÉT + TÌM)
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                // Nút Quét Mã (To)
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _scanToAdd,
                    icon: const Icon(Icons.qr_code_scanner, size: 20),
                    label: const Text("QUÉT MÃ", style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800], 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15)
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Nút Tìm Kiếm (Nhỏ hơn chút)
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: _showSearchSheet, // <--- GỌI HÀM TÌM KIẾM
                    icon: const Icon(Icons.search, size: 20),
                    label: const Text("TÌM"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange, 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15)
                    ),
                  ),
                ),
              ],
            ),
          ),

          // DANH SÁCH GIỎ HÀNG
          Expanded(
            child: cart.items.isEmpty 
              ? const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey),
                    Text("Giỏ hàng trống", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ))
              : ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (ctx, i) {
                    var item = cart.items.values.toList()[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: item.product.imageUrl.isNotEmpty ? NetworkImage(item.product.imageUrl) : null,
                          child: item.product.imageUrl.isEmpty ? const Icon(Icons.shopping_bag) : null,
                        ),
                        title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${formatCurrency(item.product.sellPrice)} x ${item.quantity}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(formatCurrency(item.totalPrice), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => cart.removeSingleItem(item.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                              onPressed: () => cart.addToCart(item.product),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),

          // KHU VỰC THANH TOÁN
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -5))]
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Tổng thanh toán:", style: TextStyle(color: Colors.grey)),
                      Text(formatCurrency(cart.totalAmount), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: cart.items.isEmpty ? null : _processCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)
                    ),
                    child: const Text("THANH TOÁN", style: TextStyle(fontSize: 16)),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// --- WIDGET BOTTOM SHEET: TÌM KIẾM SẢN PHẨM ---
class SearchProductSheet extends StatefulWidget {
  const SearchProductSheet({super.key});

  @override
  State<SearchProductSheet> createState() => _SearchProductSheetState();
}

class _SearchProductSheetState extends State<SearchProductSheet> {
  String _searchKeyword = "";
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    // Truy vấn tất cả sản phẩm của User
    // (Lưu ý: Firestore không hỗ trợ tìm kiếm text "chứa" (contains) tốt,
    // nên ta sẽ tải list về và lọc trên máy cho nhanh và mượt)
    final Stream<QuerySnapshot> _usersStream = FirebaseFirestore.instance
        .collection('products')
        .where('userId', isEqualTo: user?.uid)
        .snapshots();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8, // Cao 80% màn hình
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Thanh kéo nhỏ
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 15),
          
          // Ô Tìm kiếm
          TextField(
            autofocus: true, // Tự động bật bàn phím
            decoration: const InputDecoration(
              labelText: "Nhập tên sản phẩm...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchKeyword = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 10),

          // Danh sách kết quả
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _usersStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Text('Lỗi tải dữ liệu');
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                // Lấy danh sách và lọc
                var docs = snapshot.data!.docs;
                var filteredDocs = docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String name = (data['name'] ?? '').toString().toLowerCase();
                  // Lọc: Tên chứa từ khóa
                  return name.contains(_searchKeyword);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text("Không tìm thấy sản phẩm nào"));
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var doc = filteredDocs[index];
                    ProductModel product = ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

                    return ListTile(
                      leading: SizedBox(
                        width: 50, height: 50,
                        child: product.imageUrl.isNotEmpty 
                          ? Image.network(product.imageUrl, fit: BoxFit.cover) 
                          : const Icon(Icons.image),
                      ),
                      title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Giá: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(product.sellPrice)} | Kho: ${product.stock}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue, size: 30),
                        onPressed: () {
                          // Thêm vào giỏ
                          context.read<CartController>().addToCart(product);
                          // Thông báo nhẹ
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("Đã thêm: ${product.name}"), 
                            duration: const Duration(milliseconds: 500),
                          ));
                          // Không đóng dialog để chọn tiếp
                        },
                      ),
                      onTap: () {
                         // Chạm vào dòng cũng thêm vào giỏ
                         context.read<CartController>().addToCart(product);
                         Navigator.pop(context); // Đóng dialog luôn
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}