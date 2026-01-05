# lib — Tóm tắt cấu trúc và tác dụng

Tệp này tóm tắt cấu trúc thư mục `lib/` của ứng dụng và chức năng chính của từng file/thư mục.

```
lib/
├─ main.dart
├─ firebase_options.dart
├─ controllers/
│  ├─ auth_controller.dart
│  ├─ product_controller.dart
│  ├─ category_controller.dart
│  ├─ cart_controller.dart
│  ├─ order_controller.dart
│  └─ stats_controller.dart
├─ models/
│  ├─ user_model.dart
│  ├─ product_model.dart
│  ├─ category_model.dart
│  ├─ cart_item_model.dart
│  ├─ order_model.dart
│  └─ restock_suggestion_model.dart
├─ services/
│  ├─ auth_service.dart
│  ├─ notification_service.dart
│  ├─ biometric_service.dart
│  ├─ pdf_invoice_service.dart
│  └─ restock_service.dart
├─ utils/
│  └─ show_snack.dart
└─ views/
   ├─ login_view.dart
   ├─ signup_view.dart
   ├─ home_view.dart
   ├─ auth_wrapper.dart
   ├─ biometric_lock_view.dart
   ├─ PhoneAuthView.dart
   ├─ add_product_view.dart
   ├─ category_view.dart
   ├─ checkout_view.dart
   ├─ invoice_list_view.dart
   ├─ restock_suggestion_screen.dart
   ├─ restock_quick_summary_card.dart
   ├─ restock_test_screen.dart
   └─ stats_view.dart
```

Mô tả ngắn

- `main.dart`: Điểm vào ứng dụng — khởi tạo Firebase, load `.env`, khởi tạo `NotificationService`, cấu hình `Provider` và `AuthWrapper`.
- `firebase_options.dart`: Cấu hình Firebase (auto-generated bởi FlutterFire).

Controllers
- `auth_controller.dart`: Quản lý trạng thái xác thực, thông tin người dùng và hành vi đăng nhập/đăng xuất.
- `product_controller.dart`: Quản lý lấy/điều chỉnh danh sách sản phẩm và logic CRUD sản phẩm.
- `category_controller.dart`: Quản lý danh mục sản phẩm.
- `cart_controller.dart`: Logic giỏ hàng (thêm/xóa mục, tính tổng).
- `order_controller.dart`: Tạo và quản lý đơn hàng.
- `stats_controller.dart`: Tổng hợp dữ liệu thống kê bán hàng.

Models
- `user_model.dart`: Định nghĩa cấu trúc dữ liệu người dùng.
- `product_model.dart`: Mô tả thuộc tính sản phẩm (tên, giá, tồn kho,...).
- `category_model.dart`: Mô tả danh mục sản phẩm.
- `cart_item_model.dart`: Mô tả mục trong giỏ hàng.
- `order_model.dart`: Mô tả đơn hàng và trạng thái.
- `restock_suggestion_model.dart`: Mô hình gợi ý nhập hàng/tồn kho.

Services
- `auth_service.dart`: Tương tác trực tiếp với Firebase Auth hoặc các API xác thực.
- `notification_service.dart`: Thiết lập và xử lý thông báo (local/remote).
- `biometric_service.dart`: Xác thực sinh trắc học (Face/Touch ID).
- `pdf_invoice_service.dart`: Tạo/xuất hóa đơn PDF.
- `restock_service.dart`: Logic kiểm tra tồn kho và gợi ý nhập hàng.

Utils
- `show_snack.dart`: Hàm tiện ích hiển thị `SnackBar` cho UI.

Views
- Các file trong `views/` là các màn hình giao diện (login, signup, home, checkout, quản lý sản phẩm/danh mục, hóa đơn, restock, thống kê, v.v.).

Gợi ý tiếp theo
- Muốn mình xuất cây thư mục dạng text (ví dụ `tree`) hoặc thêm liên kết tới file cụ thể không?
