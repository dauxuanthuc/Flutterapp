import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Import Controllers
import 'controllers/product_controller.dart';
import 'controllers/category_controller.dart';
import 'controllers/cart_controller.dart';
import 'controllers/stats_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/order_controller.dart';

// Import Services
import 'services/notification_service.dart';

// Import Views
import 'views/login_view.dart';
import 'views/home_view.dart';
import 'views/biometric_lock_view.dart';
import 'views/auth_wrapper.dart'; // ✅ Đã import file này thì không viết class ở dưới nữa

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ProductController()),
        ChangeNotifierProvider(create: (_) => CategoryController()),
        ChangeNotifierProvider(create: (_) => CartController()),
        ChangeNotifierProvider(create: (_) => OrderController()),
        ChangeNotifierProvider(create: (_) => StatsController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MVC Auth Project',
        theme: ThemeData(primarySwatch: Colors.blue),
        
        // Gọi AuthWrapper từ file 'views/auth_wrapper.dart'
        home: const AuthWrapper(), 
      ),
    );
  }
}