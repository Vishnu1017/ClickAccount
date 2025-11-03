import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:click_account/models/user_model.dart';
import 'login_screen.dart';

class ProfilePage extends StatefulWidget {
  final User user;

  const ProfilePage({super.key, required this.user});

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
    name = widget.user.name;
    email = widget.user.email;
    phone = widget.user.phone;
    role = widget.user.role;
    upiId = widget.user.upiId;

    _nameController = TextEditingController(text: name);
    _roleController = TextEditingController(text: role);
    _emailController = TextEditingController(text: email);
    _phoneController = TextEditingController(text: phone);
    _upiController = TextEditingController(text: upiId);

    _loadImage();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session error. Please login again.')),
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

  Future<void> _pickImage() async {
    try {
      final status = await Permission.photos.request();

      if (!status.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied. Please allow access to gallery.'),
          ),
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile image updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Image picking error: $e');
      setState(() => _isImageLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}')),
      );
    }
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _nameController.text = name;
        _roleController.text = role;
        _emailController.text = email;
        _phoneController.text = phone;
        _upiController.text = upiId;
      }
    });
  }

  Future<void> _saveProfile() async {
    final box = Hive.box<User>('users');
    final userKey = box.keys.firstWhere(
      (key) => box.get(key)?.email == widget.user.email,
      orElse: () => null,
    );

    if (userKey != null) {
      final updatedUser = User(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        role: _roleController.text,
        password: widget.user.password,
        upiId: _upiController.text,
      );

      await box.put(userKey, updatedUser);

      setState(() {
        name = _nameController.text;
        role = _roleController.text;
        email = _emailController.text;
        phone = _phoneController.text;
        upiId = _upiController.text;
        _isEditing = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    } finally {
      setState(() => _isLoggingOut = false);
    }
  }

  Future<void> deleteCurrentUser(String email) async {
    try {
      final box = Hive.box<User>('users');
      final userKey = box.keys.firstWhere(
        (key) => box.get(key)?.email == email,
        orElse: () => null,
      );

      if (userKey != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('${widget.user.email}_profileImagePath');

        await box.delete(userKey);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account deleted successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User not found"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Delete user error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error deleting account"),
          backgroundColor: Colors.red,
        ),
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
                              onChanged: (String? newValue) {
                                setState(() {
                                  role = newValue!;
                                  _roleController.text = newValue;
                                });
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
          upiId,
          isSmallScreen,
        ),
        const SizedBox(height: 16),
        _glassInfoRow(Icons.location_city, 'Bangalore, India', isSmallScreen),
      ],
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
    final shouldDelete = await showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Delete Account?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "This will permanently remove all your data. This action cannot be undone.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          "Cancel",
                          style: TextStyle(color: Colors.grey.shade800),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [Colors.red.shade600, Colors.red.shade800],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            "Delete Forever",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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

    if (shouldDelete == true) {
      await deleteCurrentUser(widget.user.email);
    }
  }
}
