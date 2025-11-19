import 'package:bizmate/widgets/app_snackbar.dart' show AppSnackBar;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bizmate/models/user_model.dart';
import 'package:bizmate/screens/nav_bar_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final _storage = FlutterSecureStorage(
  aOptions: const AndroidOptions(encryptedSharedPreferences: true),
);

enum PasscodeType { numeric, alphanumeric }

class AuthGateScreen extends StatelessWidget {
  final User user;
  final String userPhone;
  final String userEmail;
  const AuthGateScreen({
    super.key,
    required this.user,
    required this.userPhone,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    Future.microtask(() async {
      final key = 'passcode_${user.email}';
      final savedPasscode = await _storage.read(key: key);

      if (savedPasscode == null || savedPasscode.isEmpty) {
        // 👉 User has NO PASSCODE → coming from SIGNUP
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) =>
                    PasscodeCreationScreen(user: user, secureStorage: _storage),
          ),
        );
      } else {
        // 👉 User already has passcode → LOGIN
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => EnterPasscodeScreen(user: user, secureStorage: _storage),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

// ---------------- PASSCODE CREATION SCREEN ----------------
class PasscodeCreationScreen extends StatefulWidget {
  final User user;
  final FlutterSecureStorage secureStorage;

  const PasscodeCreationScreen({
    super.key,
    required this.user,
    required this.secureStorage,
  });

  @override
  State<PasscodeCreationScreen> createState() => _PasscodeCreationScreenState();
}

class _PasscodeCreationScreenState extends State<PasscodeCreationScreen> {
  PasscodeType _selectedType = PasscodeType.numeric;
  int _numericLength = 4;
  final TextEditingController _alphanumericController = TextEditingController();
  List<String> _pinDigits = List.filled(6, '');
  bool _obscureAlphanumeric = true;

  // ---------------- Existing Save Function ----------------
  Future<void> _savePasscode() async {
    String passcode;
    if (_selectedType == PasscodeType.numeric) {
      passcode = _pinDigits.take(_numericLength).join();
      if (passcode.length != _numericLength) {
        AppSnackBar.showError(
          context,
          message:
              "Please enter exactly $_numericLength digits for the numeric passcode",
          duration: Duration(seconds: 2),
        );
        return;
      }
    } else {
      passcode = _alphanumericController.text.trim();
      if (passcode.length < 6) {
        AppSnackBar.showError(
          context,
          message: "Alphanumeric passcode must be at least 6 characters",
          duration: Duration(seconds: 2),
        );
        return;
      }
    }

    final key = 'passcode_${widget.user.email}';
    await widget.secureStorage.write(key: key, value: passcode);
    await widget.secureStorage.write(
      key: 'passcode_type_${widget.user.email}',
      value: _selectedType.name,
    );

    final check = await widget.secureStorage.read(key: key);
    if (check != null && check == passcode) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => NavBarPage(
                user: widget.user,
                userPhone: widget.user.phone,
                userEmail: widget.user.email,
              ),
        ),
      );
    } else {
      AppSnackBar.showError(
        context,
        message: "Failed to save passcode",
        duration: Duration(seconds: 2),
      );
    }
  }

  Widget _buildAnimatedPinFields(BoxConstraints constraints) {
    // Calculate dynamic field size based on numeric length and screen width
    double totalSpacing = (_numericLength - 1) * 12; // space between fields
    double availableWidth =
        constraints.maxWidth - totalSpacing - 40; // 40 padding
    double fieldSize = availableWidth / _numericLength;

    // Clamp field size for small and large screens
    fieldSize = fieldSize > 80 ? 80 : fieldSize;
    fieldSize = fieldSize < 50 ? 50 : fieldSize;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_numericLength, (index) {
          bool isFilled = _pinDigits[index].isNotEmpty;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            width: fieldSize,
            height: fieldSize,
            margin: EdgeInsets.symmetric(horizontal: fieldSize / 22),
            decoration: BoxDecoration(
              gradient:
                  isFilled
                      ? LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                      : LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              borderRadius: BorderRadius.circular(fieldSize / 5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
                if (isFilled)
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(-2, -2),
                  ),
              ],
              border: Border.all(
                color:
                    isFilled
                        ? Colors.white.withOpacity(0.8)
                        : Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: TextField(
                obscureText: true, // 🔒 Hides the numeric passcode input
                obscuringCharacter: '•', // Optional: dot symbol
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fieldSize / 2.2,
                  fontWeight: FontWeight.w700,
                  shadows:
                      isFilled
                          ? [
                            Shadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(1, 1),
                            ),
                          ]
                          : null,
                ),
                decoration: const InputDecoration(
                  counterText: "",
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() => _pinDigits[index] = value);
                  if (value.isNotEmpty && index < _numericLength - 1) {
                    FocusScope.of(context).nextFocus();
                  }
                  if (value.isEmpty && index > 0) {
                    FocusScope.of(context).previousFocus();
                  }
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTypeOption("Numeric", Icons.numbers, PasscodeType.numeric),
              _buildTypeOption(
                "Alphanumeric",
                Icons.text_fields,
                PasscodeType.alphanumeric,
              ),
            ],
          ),
          if (_selectedType == PasscodeType.numeric) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Passcode Length:",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  DropdownButton<int>(
                    value: _numericLength,
                    dropdownColor: Colors.blue.shade800,
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 4, child: Text("4 Digits")),
                      DropdownMenuItem(value: 6, child: Text("6 Digits")),
                    ],
                    onChanged: (val) => setState(() => _numericLength = val!),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeOption(String title, IconData icon, PasscodeType type) {
    bool isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                  )
                  : LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 1.5,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.blue.shade300.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Spacer(flex: 1),
                        // Header Section
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade300,
                                    Colors.blue.shade700,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.shade300.withOpacity(
                                      0.4,
                                    ),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.fingerprint,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              "Create Your Passcode",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Secure your account with a unique passcode",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        const Spacer(flex: 1),

                        // Type Selector
                        _buildTypeSelector(),
                        const SizedBox(height: 32),

                        // Input Section
                        _selectedType == PasscodeType.numeric
                            ? _buildAnimatedPinFields(constraints)
                            : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: TextField(
                                controller: _alphanumericController,
                                obscureText: _obscureAlphanumeric,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                                decoration: InputDecoration(
                                  labelText: "Enter Passcode",
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  hintText: "Minimum 6 characters",
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureAlphanumeric
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureAlphanumeric =
                                            !_obscureAlphanumeric;
                                      });
                                    },
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 18,
                                  ),
                                ),
                              ),
                            ),
                        const Spacer(flex: 2),

                        // Save Button
                        Container(
                          width: double.infinity,
                          height: 60,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          child: ElevatedButton(
                            onPressed: _savePasscode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue.shade900,
                              elevation: 8,
                              shadowColor: Colors.white.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              "Save Passcode",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(flex: 1),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------- ENTER PASSCODE SCREEN ----------------
class EnterPasscodeScreen extends StatefulWidget {
  final User user;
  final FlutterSecureStorage secureStorage;

  const EnterPasscodeScreen({
    super.key,
    required this.user,
    required this.secureStorage,
  });

  @override
  State<EnterPasscodeScreen> createState() => _EnterPasscodeScreenState();
}

class _EnterPasscodeScreenState extends State<EnterPasscodeScreen> {
  final TextEditingController _passcodeController = TextEditingController();
  String _errorMessage = '';
  PasscodeType _savedType = PasscodeType.numeric;
  int _numericLength = 4;
  List<String> _pinDigits = List.filled(6, '');
  bool _obscureAlphanumeric = true;
  int _attemptCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPasscodeType();
  }

  Future<void> _loadPasscodeType() async {
    final typeStr = await widget.secureStorage.read(
      key: 'passcode_type_${widget.user.email}',
    );
    if (typeStr != null && typeStr == PasscodeType.alphanumeric.name) {
      setState(() => _savedType = PasscodeType.alphanumeric);
    } else {
      final pass = await widget.secureStorage.read(
        key: 'passcode_${widget.user.email}',
      );
      if (pass != null) _numericLength = pass.length;
      setState(() => _savedType = PasscodeType.numeric);
    }
  }

  Future<void> _verifyPasscode() async {
    final key = 'passcode_${widget.user.email}';
    final savedPasscode = await widget.secureStorage.read(key: key);

    if (savedPasscode == null || savedPasscode.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => PasscodeCreationScreen(
                user: widget.user,
                secureStorage: widget.secureStorage,
              ),
        ),
      );
      return;
    }

    String enteredPass =
        _savedType == PasscodeType.numeric
            ? _pinDigits.take(_numericLength).join()
            : _passcodeController.text.trim();

    if (enteredPass.length != savedPasscode.length) {
      setState(() {
        _errorMessage =
            "Passcode must be ${savedPasscode.length} characters long";
        _attemptCount++;
      });
      return;
    }

    if (enteredPass == savedPasscode) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => NavBarPage(
                user: widget.user,
                userPhone: widget.user.phone,
                userEmail: widget.user.email,
              ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Incorrect passcode';
        _attemptCount++;
      });

      // Shake animation effect for wrong attempts
      if (_attemptCount >= 2) {
        _triggerShakeAnimation();
      }
    }
  }

  void _triggerShakeAnimation() {
    // This would typically be implemented with an AnimationController
    // For simplicity, we're just showing a visual feedback
    AppSnackBar.showError(
      context,
      message:
          _attemptCount >= 3
              ? "Multiple failed attempts. Consider resetting your passcode."
              : "Please check your passcode and try again.",
      duration: Duration(seconds: 2),
    );
  }

  Widget _buildAnimatedPinFields(BoxConstraints constraints) {
    // Calculate dynamic field size based on numeric length and screen width
    double totalSpacing = (_numericLength - 1) * 12; // space between fields
    double availableWidth =
        constraints.maxWidth - totalSpacing - 40; // 40 padding
    double fieldSize = availableWidth / _numericLength;

    // Clamp field size for small and large screens
    fieldSize = fieldSize > 80 ? 80 : fieldSize;
    fieldSize = fieldSize < 50 ? 50 : fieldSize;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_numericLength, (index) {
          bool isFilled = _pinDigits[index].isNotEmpty;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            width: fieldSize,
            height: fieldSize,
            margin: EdgeInsets.symmetric(horizontal: fieldSize / 13),
            decoration: BoxDecoration(
              gradient:
                  isFilled
                      ? LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                      : LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              borderRadius: BorderRadius.circular(fieldSize / 5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
                if (isFilled)
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(-2, -2),
                  ),
              ],
              border: Border.all(
                color:
                    isFilled
                        ? Colors.white.withOpacity(0.8)
                        : Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: TextField(
                obscureText: true, // 🔒 Hides the numeric passcode input
                obscuringCharacter: '*', // Optional: dot symbol
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fieldSize / 2.2,
                  fontWeight: FontWeight.w700,
                  shadows:
                      isFilled
                          ? [
                            Shadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(1, 1),
                            ),
                          ]
                          : null,
                ),
                decoration: const InputDecoration(
                  counterText: "",
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() => _pinDigits[index] = value);
                  if (value.isNotEmpty && index < _numericLength - 1) {
                    FocusScope.of(context).nextFocus();
                  }
                  if (value.isEmpty && index > 0) {
                    FocusScope.of(context).previousFocus();
                  }
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  void _forgotPasscode() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.blue.shade800,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Reset Passcode?",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              "This will create a new passcode. Your old passcode will be lost.",
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => PasscodeCreationScreen(
                            user: widget.user,
                            secureStorage: widget.secureStorage,
                          ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade900,
                ),
                child: const Text("Continue"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),

                        // Header Section
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade300,
                                    Colors.blue.shade700,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.shade300.withOpacity(
                                      0.4,
                                    ),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.lock_outline,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              "Welcome Back",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Enter your passcode to continue",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(flex: 1),

                        // Error Message
                        if (_errorMessage.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade300,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _errorMessage,
                                  style: TextStyle(
                                    color: Colors.red.shade300,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(flex: 1),

                        // Input Section
                        _savedType == PasscodeType.numeric
                            ? _buildAnimatedPinFields(constraints)
                            : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: TextField(
                                controller: _passcodeController,
                                obscureText: _obscureAlphanumeric,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                                decoration: InputDecoration(
                                  labelText: "Enter Passcode",
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureAlphanumeric
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureAlphanumeric =
                                            !_obscureAlphanumeric;
                                      });
                                    },
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 18,
                                  ),
                                ),
                              ),
                            ),
                        const Spacer(flex: 2),

                        // Action Buttons
                        Column(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 60,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: ElevatedButton(
                                onPressed: _verifyPasscode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blue.shade900,
                                  elevation: 8,
                                  shadowColor: Colors.white.withOpacity(0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: const Text(
                                  "Unlock",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _forgotPasscode,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.help_outline,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Forgot Passcode?",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(flex: 2),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
