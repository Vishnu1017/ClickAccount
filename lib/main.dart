import 'package:click_account/models/payment.dart';
import 'package:click_account/models/product.dart';
import 'package:click_account/models/sale.dart';
import 'package:click_account/screens/nav_bar_page.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(SaleAdapter().typeId)) {
    Hive.registerAdapter(SaleAdapter());
  }

  if (!Hive.isAdapterRegistered(ProductAdapter().typeId)) {
    Hive.registerAdapter(ProductAdapter());
  }

  if (!Hive.isAdapterRegistered(PaymentAdapter().typeId)) {
    Hive.registerAdapter(PaymentAdapter());
  }

  await Hive.openBox<Sale>('sales');
  await Hive.openBox<Product>('products');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Click Account',
      home: CustomSplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CustomSplashScreen extends StatefulWidget {
  @override
  State<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Timer(Duration(seconds: 3), () {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => NavBarPage()));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF00BCD4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _animation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.PNG', // Make sure this path exists in your pubspec.yaml
                  width: 130,
                ),
                SizedBox(height: 20),
                Text(
                  "Click Account",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
