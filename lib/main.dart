import 'dart:async';
import 'dart:io';
import 'package:click_account/models/user_model.dart';
import 'package:click_account/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:click_account/models/sale.dart';
import 'package:click_account/models/product.dart';
import 'package:click_account/models/payment.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(UserAdapter());

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive with proper path
  final appDocDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocDir.path);

  // OPTIONAL: Delete boxes from disk before opening (use only when needed)
  // await _deleteAllHiveBoxes();

  // Register all Hive adapters with typeId checks
  if (!Hive.isAdapterRegistered(UserAdapter().typeId)) {
    Hive.registerAdapter(UserAdapter());
  }
  if (!Hive.isAdapterRegistered(SaleAdapter().typeId)) {
    Hive.registerAdapter(SaleAdapter());
  }
  if (!Hive.isAdapterRegistered(ProductAdapter().typeId)) {
    Hive.registerAdapter(ProductAdapter());
  }
  if (!Hive.isAdapterRegistered(PaymentAdapter().typeId)) {
    Hive.registerAdapter(PaymentAdapter());
  }

  // Open all required boxes
  await Hive.openBox<User>('users');
  await Hive.openBox<Sale>('sales');
  await Hive.openBox<Product>('products');
  await Hive.openBox<Payment>('payments');

  // Save default profile image if not already set
  final prefs = await SharedPreferences.getInstance();
  final imagePath = prefs.getString('profileImagePath');
  if (imagePath == null || !File(imagePath).existsSync()) {
    final byteData = await rootBundle.load('assets/images/LOGO.jpg');
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/default_logo.jpg');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    await prefs.setString('profileImagePath', file.path);
  }

  runApp(const MyApp());
}

// Future<void> _deleteAllHiveBoxes() async {
//   final List<String> boxNames = ['users', 'sales', 'products', 'payments'];

//   for (var boxName in boxNames) {
//     if (await Hive.boxExists(boxName)) {
//       if (Hive.isBoxOpen(boxName)) {
//         await Hive.box(boxName).close();
//       }
//       await Hive.deleteBoxFromDisk(boxName);
//     }
//   }
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Click Account',
      debugShowCheckedModeBanner: false,
      home: CustomSplashScreen(),
    );
  }
}

class CustomSplashScreen extends StatefulWidget {
  const CustomSplashScreen({super.key});

  @override
  State<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen()));
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
        decoration: const BoxDecoration(
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
                Image.asset('assets/images/logo.PNG', width: 130),
                const SizedBox(height: 20),
                const Text(
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
