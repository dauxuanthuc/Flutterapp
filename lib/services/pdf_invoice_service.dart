import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';

class PdfInvoiceService {
  
  // Hàm chính: Gọi hàm này để in/xuất PDF
  Future<void> printInvoice(OrderModel order) async {
    final doc = pw.Document();
    
    // Tải font (Optional: Nếu muốn tiếng Việt đẹp thì cần file font)
    // final font = await PdfGoogleFonts.nunitoExtraLight(); 

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return buildInvoice(order); // Gọi hàm vẽ giao diện
        },
      ),
    );

    // Mở trình xem/in của điện thoại
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  // Hàm vẽ giao diện bên trong tờ giấy A4
  pw.Widget buildInvoice(OrderModel order) {
    final dateFormat = DateFormat("dd/MM/yyyy HH:mm");
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'd');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // 1. Tiêu đề
        pw.Header(
          level: 0,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('HOA DON BAN HANG', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Text('Shop Online', style: pw.TextStyle(fontSize: 18)),
            ],
          ),
        ),
        
        pw.SizedBox(height: 20),

        // 2. Thông tin chung
        pw.Text('Ma don hang: ${order.id}'),
        pw.Text('Ngay tao: ${dateFormat.format(order.date)}'),
        pw.Text('Nhan vien: ${order.userId}'), // Hoặc tên nhân viên nếu có

        pw.SizedBox(height: 30),

        // 3. Bảng sản phẩm
        pw.Table.fromTextArray(
          headers: ['San pham', 'SL', 'Don gia', 'Thanh tien'],
          data: order.products.map((item) {
            final double price = (item['price'] ?? 0).toDouble();
            final int quantity = item['quantity'] ?? 0;
            final double total = price * quantity;
            
            return [
              item['name'] ?? 'Unknown', // Tên sản phẩm
              quantity.toString(),
              currencyFormat.format(price),
              currencyFormat.format(total),
            ];
          }).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.center,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
          },
        ),

        pw.Divider(),

        // 4. Tổng tiền
        pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text("TONG CONG: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(
                currencyFormat.format(order.totalAmount),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColors.red),
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 20),
        pw.Center(child: pw.Text("Cam on quy khach!", style: pw.TextStyle(fontStyle: pw.FontStyle.italic))),
      ],
    );
  }
}