import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Auth
import '../models/category_model.dart';

class CategoryController extends ChangeNotifier {
  final CollectionReference _cateRef = FirebaseFirestore.instance.collection(
    'categories',
  );

  // --- 1. SỬA LẠI STREAM (Lọc theo User) ---
  Stream<List<CategoryModel>> get categoriesStream {
    final user = FirebaseAuth.instance.currentUser;

    // Nếu chưa đăng nhập -> Trả về danh sách rỗng
    if (user == null) {
      print("Chưa đăng nhập");
      return Stream.value([]);
    }
    print("User ID: ${user.uid}");

    // Lọc userId == user.uid VÀ sắp xếp theo tên
    return _cateRef
        .where('userId', isEqualTo: user.uid) // <--- LỌC CHÍNH CHỦ
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return CategoryModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  // --- 2. SỬA LẠI HÀM THÊM (Gán User ID) ---
  Future<void> addCategory(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _cateRef.add({
        'name': name,
        'userId': user.uid, 
      });
    } catch (e) {
      print("Lỗi thêm danh mục: $e");
    }
  }

  // Hàm xóa 
  Future<void> deleteCategory(String id) async {
    try {
      await _cateRef.doc(id).delete();
    } catch (e) {
      print("Lỗi xóa danh mục: $e");
    }
  }
}
