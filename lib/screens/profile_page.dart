import 'dart:io';
import 'dart:ui';
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

  const ProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String name;
  late String role;
  late String email;
  late String phone;
  File? _profileImage;
  final picker = ImagePicker();
  bool _isImageLoading = false;
  final bool _isImageSaved = false;
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

  @override
  void initState() {
    super.initState();
    name = widget.user.name;
    email = widget.user.email;
    phone = widget.user.phone;
    role = widget.user.role;

    _nameController = TextEditingController(text: name);
    _roleController = TextEditingController(text: role);
    _emailController = TextEditingController(text: email);
    _phoneController = TextEditingController(text: phone);

    _loadImage();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    setState(() => _isImageLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profileImagePath');

    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        setState(() => _profileImage = file);
      }
    }
    setState(() => _isImageLoading = false);
  }

  Future<void> _pickImage() async {
    final status = await Permission.photos.request();

    if (status.isGranted) {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _isImageLoading = true);
        final file = File(picked.path);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImagePath', picked.path);
        setState(() {
          _profileImage = file;
          _isImageLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission denied. Please allow access to gallery.'),
        ),
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
      }
    });
  }

  Future<void> _saveProfile() async {
    final box = Hive.box<User>('users');
    final userKey = box.keys.firstWhere(
      (key) => box.get(key)!.email == widget.user.email,
      orElse: () => null,
    );

    if (userKey != null) {
      final updatedUser = User(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        role: _roleController.text,
        password: widget.user.password,
      );

      await box.put(userKey, updatedUser);

      setState(() {
        name = _nameController.text;
        role = _roleController.text;
        email = _emailController.text;
        phone = _phoneController.text;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  Future<void> deleteCurrentUser(String email) async {
    final box = Hive.box<User>('users');
    final userKey = box.keys.firstWhere(
      (key) => box.get(key)!.email == email,
      orElse: () => null,
    );

    if (userKey != null) {
      await box.delete(userKey);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Account deleted successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User not found"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1A237E), Color(0xFF00BCD4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 8.0,
                                  sigmaY: 8.0,
                                ),
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.9,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white30,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Align(
                                        alignment: Alignment.topRight,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: Colors.white30,
                                              width: 1,
                                            ),
                                          ),
                                          child: PopupMenuButton<String>(
                                            icon: const Icon(
                                              FontAwesomeIcons.ellipsisV,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              side: BorderSide(
                                                color: Colors.white.withOpacity(
                                                  0.2,
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                            color: Colors.blueGrey[800]
                                                ?.withOpacity(0.95),
                                            elevation: 8,
                                            shadowColor: Colors.black
                                                .withOpacity(0.3),
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _toggleEditing();
                                              }
                                            },
                                            itemBuilder: (
                                              BuildContext context,
                                            ) {
                                              return [
                                                PopupMenuItem<String>(
                                                  value: 'edit',
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 4,
                                                          vertical: 4,
                                                        ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                6,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors
                                                                .blueAccent
                                                                .withOpacity(
                                                                  0.2,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          child: const Icon(
                                                            Icons.edit,
                                                            color:
                                                                Colors
                                                                    .blueAccent,
                                                            size: 20,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        const Text(
                                                          'Edit Profile',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ];
                                            },
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: _pickImage,
                                        child: Stack(
                                          alignment: Alignment.bottomRight,
                                          children: [
                                            _isImageLoading
                                                ? const CircleAvatar(
                                                  radius: 50,
                                                  child: Padding(
                                                    padding: EdgeInsets.all(
                                                      16.0,
                                                    ),
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Colors.white,
                                                        ),
                                                  ),
                                                )
                                                : CircleAvatar(
                                                  radius: 50,
                                                  backgroundColor: Colors.white
                                                      .withOpacity(0.3),
                                                  child:
                                                      _profileImage != null &&
                                                              _isImageSaved
                                                          ? ClipRRect(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  50,
                                                                ),
                                                            child: Image.file(
                                                              _profileImage!,
                                                              fit: BoxFit.cover,
                                                              width: 100,
                                                              height: 100,
                                                            ),
                                                          )
                                                          : Text(
                                                            name.isNotEmpty
                                                                ? name[0]
                                                                    .toUpperCase()
                                                                : 'U',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 36,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      Colors
                                                                          .white,
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
                                      const SizedBox(height: 16),
                                      _isEditing
                                          ? TextField(
                                            controller: _nameController,
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            textAlign: TextAlign.center,
                                          )
                                          : Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                      const SizedBox(height: 4),
                                      _isEditing
                                          ? Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 40,
                                              vertical: 8,
                                            ),
                                            child: DropdownButtonFormField<
                                              String
                                            >(
                                              value: role,
                                              decoration: InputDecoration(
                                                labelText: 'Role',
                                                labelStyle: TextStyle(
                                                  color: Colors.white70,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                    color: Colors.white30,
                                                  ),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: Colors.white30,
                                                      ),
                                                    ),
                                                filled: true,
                                                fillColor: Colors.white
                                                    .withOpacity(0.1),
                                              ),
                                              dropdownColor:
                                                  Colors.blueGrey[800],
                                              icon: Icon(
                                                Icons.arrow_drop_down,
                                                color: Colors.white70,
                                              ),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue.shade900,
                                              ),
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  role = newValue!;
                                                  _roleController.text =
                                                      newValue;
                                                });
                                              },
                                              items:
                                                  roles.map<
                                                    DropdownMenuItem<String>
                                                  >((String value) {
                                                    return DropdownMenuItem<
                                                      String
                                                    >(
                                                      value: value,
                                                      child: Text(
                                                        value,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                            ),
                                          )
                                          : Chip(
                                            avatar: CircleAvatar(
                                              backgroundColor: Colors
                                                  .blue
                                                  .shade100
                                                  .withOpacity(0.8),
                                              child: Icon(
                                                Icons.work_outline,
                                                size: 16,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                            label: Text(
                                              role,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue.shade900,
                                              ),
                                            ),
                                            backgroundColor: Colors.blue.shade50
                                                .withOpacity(0.9),
                                            elevation: 0,
                                            shadowColor: Colors.transparent,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              side: BorderSide(
                                                color: Colors.blue.shade200
                                                    .withOpacity(0.5),
                                                width: 1,
                                              ),
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                      const SizedBox(height: 20),
                                      const Divider(color: Colors.white30),
                                      const SizedBox(height: 6),
                                      _isEditing
                                          ? Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white30,
                                                width: 1,
                                              ),
                                            ),
                                            child: TextField(
                                              controller: _emailController,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                              decoration: InputDecoration(
                                                prefixIcon: Icon(
                                                  Icons.email,
                                                  size: 20,
                                                  color: Colors.white70,
                                                ),
                                                border: InputBorder.none,
                                              ),
                                            ),
                                          )
                                          : _glassRow(
                                            Icons.email,
                                            email.isNotEmpty
                                                ? email
                                                : "No email",
                                          ),
                                      const SizedBox(height: 12),
                                      _isEditing
                                          ? Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white30,
                                                width: 1,
                                              ),
                                            ),
                                            child: TextField(
                                              controller: _phoneController,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                              decoration: InputDecoration(
                                                prefixIcon: Icon(
                                                  Icons.phone,
                                                  size: 20,
                                                  color: Colors.white70,
                                                ),
                                                border: InputBorder.none,
                                              ),
                                            ),
                                          )
                                          : _glassRow(
                                            Icons.phone,
                                            phone.isNotEmpty
                                                ? phone
                                                : "No phone",
                                          ),
                                      const SizedBox(height: 12),
                                      _glassRow(
                                        Icons.location_city,
                                        'Bangalore, India',
                                      ),
                                      if (_isEditing) ...[
                                        const SizedBox(height: 24),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 40,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: _toggleEditing,
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.white,
                                                    side: BorderSide(
                                                      color: Colors.white
                                                          .withOpacity(0.5),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 14,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: _saveProfile,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.blueAccent,
                                                    foregroundColor:
                                                        Colors.white,
                                                    elevation: 2,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 14,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    shadowColor: Colors
                                                        .blueAccent
                                                        .withOpacity(0.3),
                                                  ),
                                                  child: const Text(
                                                    'Save Changes',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          if (!_isEditing)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: _logout,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white.withOpacity(0.15),
                                              Colors.white.withOpacity(0.05),
                                            ],
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.logout,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Logout",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: InkWell(
                                      onTap:
                                          () => _showEnhancedDeleteDialog(
                                            context,
                                          ),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.red.shade600,
                                              Colors.red.shade800,
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.red.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 8,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.delete_forever,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Delete",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showEnhancedDeleteDialog(BuildContext context) async {
    final shouldDelete = await showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.all(24),
            child: Container(
              padding: EdgeInsets.all(24),
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
                  SizedBox(height: 16),
                  Text(
                    "Delete Account?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "This will permanently remove all your data. This action cannot be undone.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
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
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
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

  Widget _glassRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
