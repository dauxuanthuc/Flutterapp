import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart'; // 1. IMPORT THƯ VIỆN SCAN

// Import các Controller và Model
import '../controllers/product_controller.dart';
import '../controllers/category_controller.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

class AddProductView extends StatefulWidget {
  final ProductModel? product;
  const AddProductView({super.key, this.product});

  @override
  State<AddProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends State<AddProductView> {
  final _formKey = GlobalKey<FormState>();
  
  // Các controller nhập liệu
  late TextEditingController _nameCtrl;
  late TextEditingController _barcodeCtrl; 
  late TextEditingController _importPriceCtrl;
  late TextEditingController _sellPriceCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _descCtrl;
  
  String? _selectedCategory;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product?.name ?? '');
    _barcodeCtrl = TextEditingController(text: widget.product?.barcode ?? ''); // Lấy mã vạch cũ nếu có
    _importPriceCtrl = TextEditingController(text: widget.product?.importPrice.toString() ?? '');
    _sellPriceCtrl = TextEditingController(text: widget.product?.sellPrice.toString() ?? '');
    _stockCtrl = TextEditingController(text: widget.product?.stock.toString() ?? '');
    _descCtrl = TextEditingController(text: widget.product?.description ?? '');
    
    if (widget.product != null) {
      _selectedCategory = widget.product!.category;
    }
  }

  // 3. HÀM QUÉT MÃ VẠCH
  void _scanBarcode() async {
    String? res = await SimpleBarcodeScanner.scanBarcode(
      context,
      barcodeAppBar: const BarcodeAppBar(
        appBarTitle: 'Quét mã vạch',
        centerTitle: false,
        enableBackButton: true,
        backButtonIcon: Icon(Icons.arrow_back_ios),
      ),
      isShowFlashIcon: true,
      delayMillis: 2000,
      cameraFace: CameraFace.back,
    );

    if (res != null && res != '-1' && res.isNotEmpty) {
      setState(() {
        _barcodeCtrl.text = res;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã quét: $res")));
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
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng chọn danh mục!"))
        );
        return;
      }

      final controller = Provider.of<ProductController>(context, listen: false);
      
      final newProduct = ProductModel(
        name: _nameCtrl.text,
        barcode: _barcodeCtrl.text, 
        importPrice: double.tryParse(_importPriceCtrl.text) ?? 0,
        sellPrice: double.tryParse(_sellPriceCtrl.text) ?? 0,
        stock: int.tryParse(_stockCtrl.text) ?? 0,
        description: _descCtrl.text,
        category: _selectedCategory!,
        imageUrl: widget.product?.imageUrl ?? '',
        userId: widget.product?.userId ?? '', 
      );

      if (widget.product == null) {
        await controller.addProduct(newProduct, _pickedImage);
      } else {
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
              const SizedBox(height: 20),

              // --- 5. GIAO DIỆN MÃ VẠCH ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.end, 
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeCtrl,
                      decoration: const InputDecoration(
                        labelText: "Mã vạch (Barcode)",
                        hintText: "Quét hoặc nhập tay",
                        prefixIcon: Icon(Icons.qr_code_2),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 55, 
                    child: ElevatedButton(
                      onPressed: _scanBarcode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[50],
                        foregroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))
                      ),
                      child: const Icon(Icons.qr_code_scanner, size: 30),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 15),
              
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Tên sản phẩm"), validator: (v) => v!.isEmpty ? "Cần nhập tên" : null),
              const SizedBox(height: 10),
              
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _importPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Giá nhập"))),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: _sellPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Giá bán"))),
                ],
              ),
              const SizedBox(height: 10),
              
              TextFormField(controller: _stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Số lượng tồn kho")),
              const SizedBox(height: 10),

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
                    items: categories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                    decoration: const InputDecoration(labelText: "Danh mục", border: OutlineInputBorder()),
                  );
                },
              ),
              
              const SizedBox(height: 10),
              TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: "Mô tả"), maxLines: 3),
              const SizedBox(height: 20),
              
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