import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "Vishnu Chandan";
  String role = "Photographer";
  File? _profileImage;
  final picker = ImagePicker();
  bool _isImageLoaded = false; // added flag

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadImage());
  }

  Future<void> _loadImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? path = prefs.getString('profileImagePath');
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        setState(() {
          _profileImage = file;
        });
      }
    }
    setState(() {
      _isImageLoaded = true;
    });
  }

  Future<void> _pickImage() async {
    var status = await Permission.photos.request();

    if (status.isGranted) {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final file = File(picked.path);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImagePath', picked.path);
        setState(() {
          _profileImage = file;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permission denied. Please allow access to gallery.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body:
          !_isImageLoaded
              ? Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  // Background Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A237E), Color(0xFF00BCD4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),

                  // Profile Card
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.85,
                          padding: EdgeInsets.all(20),
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
                              GestureDetector(
                                onTap: _pickImage,
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundImage:
                                          _profileImage != null
                                              ? FileImage(_profileImage!)
                                              : AssetImage('assets/profile.jpg')
                                                  as ImageProvider,
                                    ),
                                    CircleAvatar(
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
                              SizedBox(height: 16),
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                role,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              SizedBox(height: 20),
                              Divider(color: Colors.white30),
                              _glassRow(
                                Icons.email,
                                'shutterlifephotography10@gmail.com',
                              ),
                              SizedBox(height: 12),
                              _glassRow(Icons.phone, '+91 63601 20253'),
                              SizedBox(height: 12),
                              _glassRow(
                                Icons.location_city,
                                'Bangalore, India',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _glassRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        SizedBox(width: 10),
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
