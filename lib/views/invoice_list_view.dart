import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../controllers/order_controller.dart';
import '../models/order_model.dart';
import '../services/pdf_invoice_service.dart'; // Import service PDF

class InvoiceListView extends StatelessWidget {
  const InvoiceListView({super.key});

  String formatCurrency(double price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lịch Sử Hóa Đơn")),
      body: StreamBuilder<List<OrderModel>>(
        stream: context.read<OrderController>().ordersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
           
             return Center(child: Text("Lỗi: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Chưa có đơn hàng nào"));
          }

          final orders = snapshot.data!;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (ctx, i) {
              final order = orders[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ExpansionTile( 
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.receipt, color: Colors.white),
                  ),
                  title: Text("Đơn: ${formatCurrency(order.totalAmount)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  subtitle: Text(formatDate(order.date)),

                  trailing: IconButton(
                    icon: const Icon(Icons.print, color: Colors.purple),
                    onPressed: () {

                      PdfInvoiceService().printInvoice(order);
                    },
                  ),
                  
                  children: order.products.map((prod) {
                    return ListTile(
                      dense: true,
                      title: Text(prod['name']),
                      trailing: Text("${prod['quantity']} x ${formatCurrency((prod['price'] as num).toDouble())}"),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}