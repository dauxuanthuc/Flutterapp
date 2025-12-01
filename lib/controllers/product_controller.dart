import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart'; // 1. IMPORT AUTH
import '../models/product_model.dart';

class ProductController extends ChangeNotifier {
  final CollectionReference _productRef = FirebaseFirestore.instance.collection('products');
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- 1. UPLOAD ẢNH LÊN IMGBB ---
  Future<String?> uploadImageToImgBB(File imageFile) async {
    try {
      // API Key của bạn
      const apiKey = '0fef1b66583bedc0a470d5d13a461bcc'; 
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      
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
      // Lấy User hiện tại
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return; 

      String imageUrl = product.imageUrl;
      
      // Nếu có chọn ảnh thì upload trước
      if (imageFile != null) {
        String? url = await uploadImageToImgBB(imageFile);
        if (url != null) imageUrl = url;
      }

      // Lưu vào Firestore
      await _productRef.add({
        ...product.toMap(),
        'imageUrl': imageUrl,
        'userId': user.uid, // <--- QUAN TRỌNG: Gắn chủ sở hữu
      });
    } catch (e) {
      print("Lỗi thêm: $e");
    }
    _setLoading(false);
  }

  // --- 3. SỬA SẢN PHẨM ---
  Future<void> updateProduct(String id, ProductModel product, File? newImageFile) async {
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}