import 'package:flutter/material.dart';
import 'dart:ui' show PlatformDispatcher;
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';

// Controllers
import 'controllers/product_controller.dart';
import 'controllers/category_controller.dart';
import 'controllers/cart_controller.dart';
import 'controllers/stats_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/order_controller.dart';

// Services
import 'services/notification_service.dart';

// Views
import 'views/login_view.dart';
import 'views/home_view.dart';
import 'views/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await dotenv.load(fileName: ".env");


  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter error: ${details.exception}');
    debugPrintStack(stackTrace: details.stack);
  };


  final originalOnError = FlutterError.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Zone error: $error');
    debugPrintStack(stackTrace: stack);
    return true;
  };


  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase init error: $e');
  }


  try {
    await NotificationService.initialize();
    debugPrint('✅ Notification service initialized');
  } catch (e) {
    debugPrint('❌ Notification init error: $e');
  }

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
        title: 'Online Shop',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: false),


        home: const AuthWrapper(),
      ),
    );
  }
}
