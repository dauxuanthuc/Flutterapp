import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Import các Controller và Model
import '../controllers/product_controller.dart';
import '../controllers/category_controller.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

class AddProductView extends StatefulWidget {
  final ProductModel? product; // Nếu null là Thêm, có dữ liệu là Sửa
  const AddProductView({super.key, this.product});

  @override
  State<AddProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends State<AddProductView> {
  final _formKey = GlobalKey<FormState>();
  
  // Các controller nhập liệu
  late TextEditingController _nameCtrl;
  late TextEditingController _importPriceCtrl;
  late TextEditingController _sellPriceCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _descCtrl;
  
  // Biến lưu danh mục đang chọn
  String? _selectedCategory;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    // Điền dữ liệu cũ nếu là chế độ Sửa
    _nameCtrl = TextEditingController(text: widget.product?.name ?? '');
    _importPriceCtrl = TextEditingController(text: widget.product?.importPrice.toString() ?? '');
    _sellPriceCtrl = TextEditingController(text: widget.product?.sellPrice.toString() ?? '');
    _stockCtrl = TextEditingController(text: widget.product?.stock.toString() ?? '');
    _descCtrl = TextEditingController(text: widget.product?.description ?? '');
    
    // Nếu đang sửa thì lấy danh mục cũ
    if (widget.product != null) {
      _selectedCategory = widget.product!.category;
    }
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (img != null) {
      setState(() => _pickedImage = File(img.path));
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      // Kiểm tra xem đã chọn danh mục chưa
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng chọn danh mục!"))
        );
        return;
      }

      final controller = Provider.of<ProductController>(context, listen: false);
      
      final newProduct = ProductModel(
        name: _nameCtrl.text,
        importPrice: double.tryParse(_importPriceCtrl.text) ?? 0,
        sellPrice: double.tryParse(_sellPriceCtrl.text) ?? 0,
        stock: int.tryParse(_stockCtrl.text) ?? 0,
        description: _descCtrl.text,
        category: _selectedCategory!,
        imageUrl: widget.product?.imageUrl ?? '',
        // --- SỬA LỖI Ở ĐÂY ---
        // Phải truyền userId vào Model. 
        // Nếu là Sửa -> Lấy userId cũ. Nếu là Thêm -> Để rỗng (Controller sẽ tự điền UID mới)
        userId: widget.product?.userId ?? '', 
      );

      if (widget.product == null) {
        // Thêm mới
        await controller.addProduct(newProduct, _pickedImage);
      } else {
        // Cập nhật
        await controller.updateProduct(widget.product!.id!, newProduct, _pickedImage);
      }
      
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProductController>().isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(widget.product == null ? "Thêm Sản Phẩm" : "Sửa Sản Phẩm")),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Chọn ảnh
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: _pickedImage != null
                      ? Image.file(_pickedImage!, fit: BoxFit.cover)
                      : (widget.product?.imageUrl.isNotEmpty == true
                          ? Image.network(widget.product!.imageUrl, fit: BoxFit.cover)
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                                Text("Chạm để thêm ảnh")
                              ],
                            )),
                ),
              ),
              const SizedBox(height: 10),
              
              // 2. Form nhập liệu
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Tên sản phẩm"), validator: (v) => v!.isEmpty ? "Cần nhập tên" : null),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _importPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Giá nhập"))),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: _sellPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Giá bán"))),
                ],
              ),
              TextFormField(controller: _stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Số lượng tồn kho")),
              
              const SizedBox(height: 10),

              // 3. Dropdown Danh mục
              StreamBuilder<List<CategoryModel>>(
                stream: context.read<CategoryController>().categoriesStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: LinearProgressIndicator());
                  
                  final categories = snapshot.data!;
                  
                  if (categories.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text("Chưa có danh mục. Hãy tạo danh mục trước!", style: TextStyle(color: Colors.red)),
                    );
                  }

                  if (_selectedCategory == null || !categories.any((c) => c.name == _selectedCategory)) {
                    _selectedCategory = categories.first.name;
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: categories.map((c) => DropdownMenuItem(
                      value: c.name, 
                      child: Text(c.name)
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                    decoration: const InputDecoration(labelText: "Danh mục", border: OutlineInputBorder()),
                  );
                },
              ),
              
              const SizedBox(height: 10),
              TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: "Mô tả"), maxLines: 3),
              const SizedBox(height: 20),
              
              // 4. Nút Lưu
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15)
                ),
                child: const Text("LƯU SẢN PHẨM", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
    );
  }
}