import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/category_controller.dart';
import '../models/category_model.dart';

class CategoryView extends StatefulWidget {
  const CategoryView({super.key});

  @override
  State<CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  final _nameController = TextEditingController();

  // Hàm hiện hộp thoại thêm mới
  void _showAddDialog() {
    _nameController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Thêm danh mục mới"),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: "Tên danh mục"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                // Gọi Controller thêm
                context.read<CategoryController>().addCategory(_nameController.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text("Thêm"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản lý Danh mục")),
      body: StreamBuilder<List<CategoryModel>>(
        stream: context.read<CategoryController>().categoriesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Chưa có danh mục nào"));
          }

          final categories = snapshot.data!;
          return ListView.separated(
            itemCount: categories.length,
            separatorBuilder: (ctx, i) => const Divider(),
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              return ListTile(
                leading: const Icon(Icons.category, color: Colors.blue),
                title: Text(cat.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // Xóa danh mục
                    context.read<CategoryController>().deleteCategory(cat.id!);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}