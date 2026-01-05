import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart'; // 1. IMPORT AUTH
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/product_model.dart';
import '../models/restock_suggestion_model.dart';
import '../services/restock_service.dart';

class ProductController extends ChangeNotifier {
  final CollectionReference _productRef = FirebaseFirestore.instance.collection(
    'products',
  );
  final RestockService _restockService = RestockService();
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<RestockSuggestion> _restockSuggestions = [];
  List<RestockSuggestion> get restockSuggestions => _restockSuggestions;

  bool _isLoadingSuggestions = false;
  bool get isLoadingSuggestions => _isLoadingSuggestions;

  // --- 1. UPLOAD ẢNH LÊN IMGBB ---
  Future<String?> uploadImageToImgBB(File imageFile) async {
    try {
      final apiKey = dotenv.env['IMGBB_API_KEY'];
      if (apiKey == null) {
        print("Lỗi: IMGBB_API_KEY không được tìm thấy trong biến môi trường");
        return null;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'),
      );
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final json = jsonDecode(responseData.body);
        return json['data']['url']; // Trả về link ảnh
      }
    } catch (e) {
      print("Lỗi upload: $e");
    }
    return null;
  }

  // --- 2. THÊM SẢN PHẨM MỚI (CÓ GẮN USER ID) ---
  Future<void> addProduct(ProductModel product, File? imageFile) async {
    _setLoading(true);
    try {

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String imageUrl = product.imageUrl;

      if (imageFile != null) {
        String? url = await uploadImageToImgBB(imageFile);
        if (url != null) imageUrl = url;
      }


      await _productRef.add({
        ...product.toMap(),
        'imageUrl': imageUrl,
        'userId': user.uid, 
      });
    } catch (e) {
      print("Lỗi thêm: $e");
    }
    _setLoading(false);
  }

  // --- 3. SỬA SẢN PHẨM ---
  Future<void> updateProduct(
    String id,
    ProductModel product,
    File? newImageFile,
  ) async {
    _setLoading(true);
    try {
      String imageUrl = product.imageUrl;

      // Nếu người dùng chọn ảnh mới thì upload ảnh mới
      if (newImageFile != null) {
        String? url = await uploadImageToImgBB(newImageFile);
        if (url != null) imageUrl = url;
      }

      await _productRef.doc(id).update({
        ...product.toMap(),
        'imageUrl': imageUrl,
        // Không update userId để tránh mất quyền sở hữu
      });
    } catch (e) {
      print("Lỗi sửa: $e");
    }
    _setLoading(false);
  }

  // --- 4. XÓA SẢN PHẨM ---
  Future<void> deleteProduct(String id) async {
    await _productRef.doc(id).delete();
  }

  // --- 5. TÌM SẢN PHẨM BẰNG MÃ VẠCH (MỚI THÊM) ---
  Future<ProductModel?> getProductByBarcode(String barcode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      // Tìm sản phẩm của User này có barcode trùng khớp
      final snapshot = await _productRef
          .where('userId', isEqualTo: user.uid)
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print("Lỗi tìm barcode: $e");
    }
    return null;
  }

  // --- 6. LẤY DANH SÁCH GỢI Ý NHẬP HÀNG THÔNG MINH ---
  Future<void> loadRestockSuggestions({
    int lookbackDays = 30,
    int safetyStockDays = 7,
    int maxDaysThreshold = 14,
    int minOrderQuantity = 10,
  }) async {
    _isLoadingSuggestions = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _restockSuggestions = [];
        _isLoadingSuggestions = false;
        notifyListeners();
        return;
      }

      _restockSuggestions = await _restockService.getRestockSuggestions(
        user.uid,
        lookbackDays: lookbackDays,
        safetyStockDays: safetyStockDays,
        maxDaysThreshold: maxDaysThreshold,
        minOrderQuantity: minOrderQuantity,
      );
    } catch (e) {
      print("Lỗi load gợi ý: $e");
      _restockSuggestions = [];
    }

    _isLoadingSuggestions = false;
    notifyListeners();
  }

  // --- 7. LẤY THỐNG KÊ RESTOCK ---
  Future<Map<String, dynamic>> getRestockStatistics() async {
    try {
      final totalCost = await _restockService.getTotalEstimatedCost(
        _restockSuggestions,
      );
      final criticalCount = _restockService.getCriticalProductsCount(
        _restockSuggestions,
      );

      return {
        'totalSuggestions': _restockSuggestions.length,
        'criticalProducts': criticalCount,
        'totalEstimatedCost': totalCost,
        'averageCostPerProduct': _restockSuggestions.isNotEmpty
            ? totalCost / _restockSuggestions.length
            : 0,
      };
    } catch (e) {
      print("Lỗi thống kê: $e");
      return {
        'totalSuggestions': 0,
        'criticalProducts': 0,
        'totalEstimatedCost': 0,
        'averageCostPerProduct': 0,
      };
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
