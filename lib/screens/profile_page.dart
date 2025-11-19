import 'dart:io';
import 'package:bizmate/widgets/app_snackbar.dart' show AppSnackBar;
import 'package:bizmate/widgets/confirm_delete_dialog.dart'
    show showConfirmDialog;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bizmate/models/user_model.dart';
import 'login_screen.dart';

class ProfilePage extends StatefulWidget {
  final User user;
  final Future<void> Function()? onRentalStatusChanged; // ✅ Add this

  const ProfilePage({
    super.key,
    required this.user,
    this.onRentalStatusChanged,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoggingOut = false;
  late String name;
  late String role;
  late String email;
  late String phone;
  late String upiId;
  File? _profileImage;
  final picker = ImagePicker();
  bool _isImageLoading = false;
  bool _isImageSaved = false;
  bool _isEditing = false;
  bool _isRentalEnabled = false;

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

  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _upiController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifySession();
    });

    // 🔥 Load the latest user data from Hive instead of using the old widget.user
    final box = Hive.box<User>('users');
    final user = box.values.firstWhere(
      (u) => u.email == widget.user.email,
      orElse: () => widget.user,
    );

    name = user.name;
    email = user.email;
    phone = user.phone;
    role = user.role;
    upiId = user.upiId; // ✅ this ensures updated UPI ID persists

    _nameController = TextEditingController(text: name);
    _roleController = TextEditingController(text: role);
    _emailController = TextEditingController(text: email);
    _phoneController = TextEditingController(text: phone);
    _upiController = TextEditingController(text: upiId);

    _loadImage();
    _loadRentalSetting();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _verifySession() async {
    try {
      final sessionBox = await Hive.openBox('session');
      if (sessionBox.isEmpty && mounted) {
        debugPrint('Session expired');
        await _logout();
      }
    } catch (e) {
      debugPrint('Session verification error: $e');
      if (mounted) {
        AppSnackBar.showError(
          context,
          message: 'Session error. Please login again.',
          duration: Duration(seconds: 2),
        );
        await _logout();
      }
    }
  }

  Future<void> _loadImage() async {
    setState(() => _isImageLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('${widget.user.email}_profileImagePath');

    if (path != null && path.isNotEmpty) {
      final file = File(path);
      try {
        final exists = await file.exists();
        if (exists) {
          setState(() {
            _profileImage = file;
            _isImageSaved = true;
          });
        } else {
          await prefs.remove('${widget.user.email}_profileImagePath');
          setState(() {
            _profileImage = null;
            _isImageSaved = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading image: $e');
        setState(() {
          _profileImage = null;
          _isImageSaved = false;
        });
      }
    } else {
      setState(() {
        _profileImage = null;
        _isImageSaved = false;
      });
    }

    setState(() => _isImageLoading = false);
  }

  Future<void> _loadRentalSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isRentalEnabled =
          prefs.getBool('${widget.user.email}_rentalEnabled') ?? false;
    });
  }

  Future<void> _enableRental() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${widget.user.email}_rentalEnabled', true);
    if (widget.onRentalStatusChanged != null) {
      await widget.onRentalStatusChanged!();
    }

    setState(() {
      _isRentalEnabled = true;
    });

    // Call the callback if provided
    widget.onRentalStatusChanged?.call();

    if (mounted) {
      AppSnackBar.showSuccess(
        context,
        message: 'Rental page enabled successfully!',
      );
    }
  }

  Future<void> _disableRental() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${widget.user.email}_rentalEnabled', false);
    setState(() {
      _isRentalEnabled = false;
    });

    // Call the callback if provided
    widget.onRentalStatusChanged?.call();

    if (mounted) {
      AppSnackBar.showWarning(context, message: 'Rental page disabled');
    }
  }

  Future<void> _pickImage() async {
    try {
      final status = await Permission.photos.request();

      if (!status.isGranted) {
        if (!mounted) return;
        AppSnackBar.showError(
          context,
          message: 'Permission denied. Please allow access to gallery.',
          duration: Duration(seconds: 2),
        );
        return;
      }

      setState(() => _isImageLoading = true);

      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (picked == null) {
        setState(() => _isImageLoading = false);
        return;
      }

      final file = File(picked.path);
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('${widget.user.email}_profileImagePath', file.path);

      if (!mounted) return;
      setState(() {
        _profileImage = file;
        _isImageLoading = false;
        _isImageSaved = true;
      });

      AppSnackBar.showSuccess(
        context,
        message: 'Profile image updated successfully!',
      );
    } catch (e) {
      debugPrint('Image picking error: $e');
      setState(() => _isImageLoading = false);
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        message: 'Error picking image: ${e.toString()}',
        duration: Duration(seconds: 2),
      );
    }
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset controllers to latest saved values
        _nameController.text = name;
        _roleController.text = role;
        _emailController.text = email;
        _phoneController.text = phone;
        _upiController.text = upiId;
      }
    });
  }

  Future<void> _saveProfile() async {
    try {
      final box = Hive.box<User>('users');
      final userKey = box.keys.firstWhere(
        (key) => box.get(key)?.email == widget.user.email,
        orElse: () => null,
      );

      if (userKey != null) {
        final updatedUser = User(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          role: _roleController.text.trim(),
          password: widget.user.password,
          upiId: _upiController.text.trim(),
        );

        await box.put(userKey, updatedUser);

        setState(() {
          name = updatedUser.name;
          role = updatedUser.role;
          email = updatedUser.email;
          phone = updatedUser.phone;
          upiId = updatedUser.upiId;
          _isEditing = false;

          _nameController.text = name;
          _roleController.text = role;
          _emailController.text = email;
          _phoneController.text = phone;
          _upiController.text = upiId;
        });

        // ✅ Manage rental control visibility instantly
        final prefs = await SharedPreferences.getInstance();
        if (role == 'Photographer') {
          await prefs.setBool('${updatedUser.email}_rentalEnabled', true);
          setState(() => _isRentalEnabled = true);
        } else {
          await prefs.setBool('${updatedUser.email}_rentalEnabled', false);
          setState(() => _isRentalEnabled = false);
        }

        // ✅ Update HomePage instantly without refreshing
        if (widget.onRentalStatusChanged != null) {
          await widget.onRentalStatusChanged!();
        }

        AppSnackBar.showSuccess(
          context,
          message: 'Profile updated successfully!',
        );
      } else {
        AppSnackBar.showError(
          context,
          message: 'User not found in database.',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      debugPrint('Save profile error: $e');
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        message: 'Error saving profile. Please try again.',
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      final sessionBox = await Hive.openBox('session');
      await sessionBox.clear();
      await sessionBox.close();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Logout error: $e');
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        message: 'Logout failed. Please try again.',
        duration: Duration(seconds: 2),
      );
    } finally {
      setState(() => _isLoggingOut = false);
    }
  }

  Future<void> deleteCurrentUser(String email) async {
    try {
      // ------------------------------------
      // 1️⃣ DELETE USER FROM HIVE USERS BOX
      // ------------------------------------
      final userBox = Hive.box<User>('users');
      final userKey = userBox.keys.firstWhere(
        (key) => userBox.get(key)?.email == email,
        orElse: () => null,
      );

      if (userKey != null) {
        await userBox.delete(userKey);
      }

      // ------------------------------------
      // 2️⃣ DELETE USER SESSION
      // ------------------------------------
      if (Hive.isBoxOpen('session')) {
        final sessionBox = Hive.box('session');
        await sessionBox.clear();
      } else {
        final sessionBox = await Hive.openBox('session');
        await sessionBox.clear();
      }

      // ------------------------------------
      // 3️⃣ DELETE ALL USER-RELATED SharedPreferences
      // ------------------------------------
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${email}_profileImagePath');
      await prefs.remove('${email}_rentalEnabled');

      // ------------------------------------
      // 4️⃣ DELETE PROFILE IMAGE FILE FROM STORAGE
      // ------------------------------------
      final path = prefs.getString('${email}_profileImagePath');
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // ------------------------------------
      // 5️⃣ OPTIONAL: DELETE ALL HIVE BOXES
      //    (Use only if you want total wipeout)
      // ------------------------------------
      // await Hive.deleteBoxFromDisk('users');
      // await Hive.deleteBoxFromDisk('session');

      // ------------------------------------
      // 6️⃣ NAVIGATE TO LOGIN
      // ------------------------------------
      if (!mounted) return;

      AppSnackBar.showSuccess(context, message: "Account deleted fully!");

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint("Delete user error: $e");

      if (!mounted) return;
      AppSnackBar.showError(
        context,
        message: "Error deleting account",
        duration: Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      body: Container(
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF00BCD4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 32,
              vertical: 20,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main Profile Card
                Container(
                  width: isSmallScreen ? screenWidth * 0.95 : screenWidth * 0.7,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white30, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      // Header Section with Edit Button in Top-Right
                      Column(
                        children: [
                          // Edit Button - Top Right aligned properly
                          Align(
                            alignment: Alignment.topRight,
                            child: PopupMenuButton<String>(
                              icon: const Icon(
                                FontAwesomeIcons.ellipsisV,
                                color: Colors.white,
                                size: 20,
                              ),
                              shadowColor: Colors.black.withOpacity(0.3),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _toggleEditing();
                                }
                              },
                              itemBuilder: (BuildContext context) {
                                return [
                                  PopupMenuItem<String>(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.blueAccent
                                                .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.edit,
                                            color: Colors.blueAccent,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Edit Profile',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ];
                              },
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Profile Image and Name - Centered
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                _isImageLoading
                                    ? CircleAvatar(
                                      radius: 50,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                    : CircleAvatar(
                                      radius: isSmallScreen ? 50 : 60,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.3,
                                      ),
                                      child:
                                          _profileImage != null && _isImageSaved
                                              ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(50),
                                                child: Image.file(
                                                  _profileImage!,
                                                  fit: BoxFit.cover,
                                                  width:
                                                      isSmallScreen ? 100 : 120,
                                                  height:
                                                      isSmallScreen ? 100 : 120,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return Text(
                                                      name.isNotEmpty
                                                          ? name[0]
                                                              .toUpperCase()
                                                          : 'U',
                                                      style: TextStyle(
                                                        fontSize:
                                                            isSmallScreen
                                                                ? 36
                                                                : 42,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )
                                              : Text(
                                                name.isNotEmpty
                                                    ? name[0].toUpperCase()
                                                    : 'U',
                                                style: TextStyle(
                                                  fontSize:
                                                      isSmallScreen ? 36 : 42,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                    ),
                                if (!_isImageLoading)
                                  const CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _isEditing
                              ? TextField(
                                controller: _nameController,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 22 : 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              )
                              : Text(
                                name,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 22 : 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                          const SizedBox(height: 12),
                        ],
                      ),

                      // Role Section
                      _isEditing
                          ? Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: DropdownButtonFormField<String>(
                              value: role,
                              decoration: InputDecoration(
                                labelText: 'Role',
                                labelStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.white30,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.white30,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                              ),
                              dropdownColor: Colors.blueGrey[800],
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white70,
                              ),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              onChanged: (String? newValue) async {
                                if (newValue == null) return;

                                // Update role locally
                                setState(() {
                                  role = newValue;
                                  _roleController.text = newValue;
                                });

                                // Save and update instantly
                                final prefs =
                                    await SharedPreferences.getInstance();

                                if (newValue == 'Photographer') {
                                  await prefs.setBool(
                                    '${widget.user.email}_rentalEnabled',
                                    true,
                                  );
                                  setState(() => _isRentalEnabled = true);
                                  widget.onRentalStatusChanged?.call();
                                } else {
                                  await prefs.setBool(
                                    '${widget.user.email}_rentalEnabled',
                                    false,
                                  );
                                  setState(() => _isRentalEnabled = false);
                                  widget.onRentalStatusChanged?.call();
                                }
                              },
                              items:
                                  roles.map<DropdownMenuItem<String>>((
                                    String value,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          )
                          : Container(
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            child: Chip(
                              avatar: CircleAvatar(
                                backgroundColor: Colors.blue.shade100
                                    .withOpacity(0.8),
                                child: Icon(
                                  Icons.work_outline,
                                  size: isSmallScreen ? 18 : 20,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              label: Text(
                                role,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              backgroundColor: Colors.blue.shade50.withOpacity(
                                0.9,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.blue.shade200.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),

                      const Divider(color: Colors.white30, height: 20),
                      const SizedBox(height: 20),

                      // Profile Information
                      _buildInfoSection(isSmallScreen),

                      // Rental Page Control Section - Only for Photographer role
                      if (role == 'Photographer' && !_isEditing) ...[
                        const SizedBox(height: 20),
                        const Divider(color: Colors.white30, height: 20),
                        _buildRentalControlSection(isSmallScreen),
                      ],

                      // Action Buttons when Editing
                      if (_isEditing) ...[
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _toggleEditing,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),

                // Bottom Action Buttons when Not Editing
                if (!_isEditing) ...[
                  const SizedBox(height: 30),
                  SizedBox(
                    width:
                        isSmallScreen ? screenWidth * 0.95 : screenWidth * 0.7,
                    child: Row(
                      children: [
                        Expanded(
                          child: _actionButton(
                            icon: Icons.logout,
                            text: "Logout",
                            color: Colors.white.withOpacity(0.15),
                            borderColor: Colors.white.withOpacity(0.5),
                            onTap: _logout,
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _actionButton(
                            icon: Icons.delete_forever,
                            text: "Delete",
                            color: Colors.red.shade600,
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade600,
                                Colors.red.shade800,
                              ],
                            ),
                            onTap: () => _showEnhancedDeleteDialog(context),
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(bool isSmallScreen) {
    return Column(
      children: [
        _buildInfoField(
          Icons.email,
          "Email",
          _emailController,
          email,
          isSmallScreen,
        ),
        const SizedBox(height: 16),
        _buildInfoField(
          Icons.phone,
          "Phone",
          _phoneController,
          phone,
          isSmallScreen,
        ),
        const SizedBox(height: 16),
        _buildInfoField(
          Icons.qr_code,
          "UPI ID",
          _upiController,
          upiId.isEmpty ? "No UPI ID" : upiId, // Show proper message when empty
          isSmallScreen,
        ),
        const SizedBox(height: 16),
        _glassInfoRow(Icons.location_city, 'Bangalore, India', isSmallScreen),
      ],
    );
  }

  Widget _buildRentalControlSection(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.white70, size: 22),
              const SizedBox(width: 12),
              Text(
                'Rental Page Control',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Manage rental page visibility in navigation',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
          const SizedBox(height: 16),

          // Status Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Status',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _isRentalEnabled ? 'Enabled' : 'Disabled',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        color:
                            _isRentalEnabled
                                ? const Color.fromARGB(255, 57, 130, 59)
                                : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _isRentalEnabled
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isRentalEnabled ? Colors.green : Colors.orange,
                    ),
                  ),
                  child: Text(
                    _isRentalEnabled ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      color: _isRentalEnabled ? Colors.white : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Enable/Disable Buttons
          Row(
            children: [
              Expanded(
                child: _rentalControlButton(
                  icon: Icons.check_circle,
                  text: "Enable",
                  color: const Color.fromARGB(255, 0, 255, 8),
                  isEnabled: !_isRentalEnabled,
                  onTap: _isRentalEnabled ? null : _enableRental,
                  isSmallScreen: isSmallScreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _rentalControlButton(
                  icon: Icons.remove_circle,
                  text: "Disable",
                  color: Colors.orange,
                  isEnabled: _isRentalEnabled,
                  onTap: _isRentalEnabled ? _disableRental : null,
                  isSmallScreen: isSmallScreen,
                ),
              ),
            ],
          ),

          // Info Message
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isRentalEnabled
                        ? 'Rental page is visible in navigation menu'
                        : 'Rental page is hidden from navigation menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 14 : 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rentalControlButton({
    required IconData icon,
    required String text,
    required Color color,
    required bool isEnabled,
    required Function? onTap,
    required bool isSmallScreen,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap != null ? () => onTap() : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color:
                isEnabled
                    ? color.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled ? color : Colors.grey.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isEnabled ? color : Colors.grey,
                size: isSmallScreen ? 24 : 28,
              ),
              const SizedBox(height: 8),
              Text(
                text,
                style: TextStyle(
                  color: isEnabled ? color : Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField(
    IconData icon,
    String label,
    TextEditingController controller,
    String value,
    bool isSmallScreen,
  ) {
    return _isEditing
        ? Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white30),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.white70, size: 22),
              hintText: value.isEmpty ? 'Enter your $label' : value,
              hintStyle: const TextStyle(color: Colors.white54),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
            ),
          ),
        )
        : _glassInfoRow(
          icon,
          value.isNotEmpty
              ? (label == "Phone" ? "+91 $value" : value)
              : "No $label",
          isSmallScreen,
        );
  }

  Widget _glassInfoRow(IconData icon, String text, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: isSmallScreen ? 16 : 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String text,
    required Color color,
    Gradient? gradient,
    Color borderColor = Colors.transparent,
    required Function onTap,
    required bool isSmallScreen,
  }) {
    return InkWell(
      onTap: () => onTap(),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow:
              gradient != null
                  ? [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: isSmallScreen ? 20 : 22),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: isSmallScreen ? 16 : 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEnhancedDeleteDialog(BuildContext context) async {
    bool confirmed = false;

    await showConfirmDialog(
      context: context,
      title: "Delete Account?",
      message:
          "This will permanently remove all your data.\nThis action cannot be undone.",
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.redAccent,
      onConfirm: () {
        confirmed = true;
      },
    );

    if (confirmed) {
      await deleteCurrentUser(widget.user.email);
    }
  }
}
