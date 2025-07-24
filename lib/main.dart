import 'dart:async';
import 'dart:io';
import 'package:click_account/models/user_model.dart';
import 'package:click_account/screens/login_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:click_account/models/sale.dart';
import 'package:click_account/models/product.dart';
import 'package:click_account/models/payment.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // =============================================
  // SYNC ERROR PROTECTION
  // =============================================
  ErrorWidget.builder = (FlutterErrorDetails details) {
    _logError(details.exception, details.stack);
    return Material(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              'UI Rendering Error',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              kDebugMode
                  ? details.exception.toString()
                  : 'Please restart the app',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => exit(0),
              child: const Text('Exit App'),
            ),
          ],
        ),
      ),
    );
  };

  // =============================================
  // EXISTING ERROR HANDLING
  // =============================================
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // =============================================
      // NATIVE CRASH PROTECTION
      // =============================================
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          await const MethodChannel(
            'crash_handler',
          ).invokeMethod('setUpNativeCrashHandling');
        } catch (e) {
          debugPrint('Native crash handler setup failed: $e');
        }
      }

      // Set up global error handlers
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        _logError(details.exception, details.stack);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        _logError(error, stack);
        return true;
      };

      try {
        // Initialize critical services
        await Future.wait([
          _initializeHive(),
          _initializeDefaultProfileImage(),
          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
        ], eagerError: true);

        runApp(const AppErrorCatcher(child: MyApp()));
      } catch (error, stackTrace) {
        _logError(error, stackTrace);
        _showErrorScreen(error);
      }
    },
    (error, stackTrace) {
      _logError(error, stackTrace);
      _showErrorScreen(error);
    },
  );
}

// =============================================
// NEW ERROR CATCHER WIDGET
// =============================================
class AppErrorCatcher extends StatelessWidget {
  final Widget child;

  const AppErrorCatcher({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Builder(
        builder: (context) {
          return child;
        },
      ),
    );
  }
}

// === Error Handling Utilities ===
void _logError(Object error, [StackTrace? stackTrace]) {
  debugPrint('ERROR: ${error.toString()}');
  if (stackTrace != null) {
    debugPrint('STACK TRACE: $stackTrace');
  }
  // Add your custom logging here (e.g., save to file)
}

void _showErrorScreen(Object error) {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'App Initialization Failed',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                kDebugMode
                    ? error.toString()
                    : 'Please restart the application',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => exit(0),
                child: const Text('Exit App'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// === Hive Management Functions ===
Future<void> _initializeHive() async {
  try {
    // Clean up any existing boxes if needed
    // await _deleteAllHiveBoxes();

    await Hive.initFlutter();
    final appDocDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocDir.path);

    _registerAdapters();

    await Future.wait([
      _openBoxSafely<User>('users'),
      _openBoxSafely<Sale>('sales'),
      _openBoxSafely<Product>('products'),
      _openBoxSafely<Payment>('payments'),
    ]);
  } catch (e) {
    debugPrint('Hive initialization error: $e');
    rethrow;
  }
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

void _registerAdapters() {
  _registerAdapter<User>(0, UserAdapter());
  _registerAdapter<Sale>(1, SaleAdapter());
  _registerAdapter<Product>(2, ProductAdapter());
  _registerAdapter<Payment>(3, PaymentAdapter());
}

void _registerAdapter<T>(int typeId, TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(typeId)) {
    Hive.registerAdapter<T>(adapter);
  }
}

Future<Box<T>> _openBoxSafely<T>(String name) async {
  try {
    return await Hive.openBox<T>(name);
  } catch (e) {
    debugPrint('Failed to open box $name: $e');
    await Hive.deleteBoxFromDisk(name);
    return await Hive.openBox<T>(name);
  }
}

// === Other Initialization Functions ===
Future<void> _initializeDefaultProfileImage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profileImagePath');

    if (imagePath == null || !await File(imagePath).exists()) {
      final byteData = await rootBundle.load('assets/images/LOGO.jpg');
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/default_logo.jpg');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await prefs.setString('profileImagePath', file.path);
    }
  } catch (e) {
    debugPrint('Default image initialization failed: $e');
  }
}

// === Widget Classes ===
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
