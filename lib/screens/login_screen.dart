// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:click_account/models/user_model.dart';
import 'package:click_account/screens/auth_gate_screen.dart'; // ✅ new import

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool isCreating = false;
  bool _isLoggedIn = false;
  bool _obscurePassword = true;
  late AnimationController _controller;
  String selectedRole = 'None'; // Default role
  final List<String> roles = [
    'None',
    'Photographer',
    'Sales Representative',
    'Account Manager',
    'Business Development',
    'Sales Manager',
    'Marketing Specialist',
    'Retail Associate',
    'Sales Executive',
    'Entrepreneur',
  ];

  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final resetEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    resetEmailController.dispose();
    super.dispose();
  }

  void toggleMode() {
    setState(() {
      isCreating = !isCreating;
      if (isCreating) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Future<void> createAccount() async {
    final fullName = fullNameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (fullName.isEmpty ||
        phone.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      showError("All fields are required");
      return;
    }

    if (password.length < 6) {
      showError("Password must be at least 6 characters");
      return;
    }

    if (!email.contains('@')) {
      showError("Please enter a valid email address");
      return;
    }

    final box = Hive.box<User>('users');
    if (box.values.any((u) => u.email == email)) {
      showError("Email already exists");
      return;
    }
    if (box.values.any((u) => u.phone == phone)) {
      showError("Phone number already exists");
      return;
    }

    try {
      final user = User(
        name: fullName,
        email: email,
        phone: phone,
        password: password,
        role: selectedRole,
      );
      await box.add(user);

      // Save session
      final sessionBox = await Hive.openBox('session');
      await sessionBox.put('currentUser', email);

      showSuccess("Account created successfully!");

      // ✅ Navigate to AuthGateScreen instead of NavBarPage
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => AuthGateScreen(user: user),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    } catch (e) {
      showError("Account creation failed. Please try again.");
    }
  }

  Future<void> login() async {
    if (_isLoggedIn) return;
    _isLoggedIn = true;

    final identifier = emailController.text.trim();
    final password = passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      showError("Please enter your email/phone and password");
      _isLoggedIn = false;
      return;
    }

    try {
      final box = Hive.box<User>('users');
      final user = box.values.firstWhere(
        (u) =>
            (u.email == identifier || u.phone == identifier) &&
            u.password == password,
        orElse:
            () => User(name: '', email: '', phone: '', password: '', role: ''),
      );

      if (user.name.isNotEmpty) {
        final sessionBox = await Hive.openBox('session');
        await sessionBox.put('currentUser', user.email);

        // ✅ Navigate to AuthGateScreen
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => AuthGateScreen(user: user),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else {
        showError("Invalid credentials. Please try again.");
      }
    } catch (e) {
      debugPrint('Login error: $e');
      showError("Login failed. Please try again.");
    } finally {
      _isLoggedIn = false;
    }
  }

  Future<void> _checkExistingSession() async {
    try {
      final sessionBox = await Hive.openBox('session');
      final currentUserEmail = sessionBox.get('currentUser');

      if (currentUserEmail != null && mounted) {
        final usersBox = Hive.box<User>('users');
        final user = usersBox.values.firstWhere(
          (u) => u.email == currentUserEmail,
          orElse:
              () =>
                  User(name: '', email: '', phone: '', password: '', role: ''),
        );

        if (user.name.isNotEmpty) {
          // ✅ Go through AuthGateScreen when session exists
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => AuthGateScreen(user: user),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Session check error: $e');
    }
  }

  // ---------------- Snackbar helpers ----------------

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ---------------- Forgot password dialog ----------------

  void _showResetPasswordDialog() {
    resetEmailController.clear();
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade700, Colors.purple.shade500],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_reset, size: 50, color: Colors.white),
                  const SizedBox(height: 15),
                  const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Enter your email to receive a reset link",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: resetEmailController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email Address",
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(
                        Icons.email,
                        color: Colors.white70,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.white.withOpacity(0.2),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handlePasswordReset(),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue.shade700,
                          ),
                          child: const Text(
                            "Send Link",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _handlePasswordReset() {
    final email = resetEmailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      showError("Please enter a valid email address");
      return;
    }

    final box = Hive.box<User>('users');
    final userExists = box.values.any((u) => u.email == email);

    if (userExists) {
      Navigator.pop(context);
      showSuccess("Password reset link sent to $email");
    } else {
      showError("No account found with this email");
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade700, Colors.purple.shade500],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.08,
              vertical: screenHeight * 0.05,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.05),
                Text(
                  isCreating ? 'Join Us!' : 'Welcome Back',
                  style: TextStyle(
                    fontSize: screenHeight * 0.035,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  isCreating ? 'Create your account' : 'Login to continue',
                  style: TextStyle(
                    fontSize: screenHeight * 0.018,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),

                // Form
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    children: [
                      if (isCreating)
                        TextField(
                          controller: fullNameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Full Name",
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(
                              Icons.person,
                              color: Colors.white70,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.white54,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      if (isCreating) SizedBox(height: screenHeight * 0.025),
                      if (isCreating)
                        Container(
                          margin: EdgeInsets.only(bottom: screenHeight * 0.025),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white54),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: selectedRole,
                            dropdownColor: Colors.blue.shade800,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white70,
                            ),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: "Your Profession",
                              labelStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.work_outline,
                                color: Colors.white70,
                              ),
                            ),
                            items:
                                roles.map((String role) {
                                  return DropdownMenuItem<String>(
                                    value: role,
                                    child: Text(role),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedRole = newValue!;
                              });
                            },
                          ),
                        ),
                      if (isCreating)
                        TextField(
                          controller: phoneController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: "Phone Number",
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(
                              Icons.phone,
                              color: Colors.white70,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.white54,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      if (isCreating) SizedBox(height: screenHeight * 0.025),
                      TextField(
                        controller: emailController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: isCreating ? "Email" : "Email or Phone",
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: Icon(
                            isCreating ? Icons.email : Icons.alternate_email,
                            color: Colors.white70,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white54),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.025),
                      TextField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: Colors.white70,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white54),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),

                if (!isCreating)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showResetPasswordDialog,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                SizedBox(height: screenHeight * 0.04),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCreating ? createAccount : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      isCreating ? 'SIGN UP' : 'LOGIN',
                      style: TextStyle(
                        fontSize: screenHeight * 0.02,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),

                TextButton(
                  onPressed: toggleMode,
                  child: RichText(
                    text: TextSpan(
                      text:
                          isCreating
                              ? 'Already have an account? '
                              : 'Don\'t have an account? ',
                      style: const TextStyle(color: Colors.white70),
                      children: [
                        TextSpan(
                          text: isCreating ? 'Login' : 'Sign up',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
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
