import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "Vishnu Chandan";
  String role = "Photographer";
  File? _profileImage;
  final picker = ImagePicker();
  bool _isImageLoading = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 50),
              child: Column(
                children: [
                  // Main Profile Container
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.9,
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
                              GestureDetector(
                                onTap: _pickImage,
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    _isImageLoading
                                        ? const CircleAvatar(
                                          radius: 50,
                                          child: Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                        : CircleAvatar(
                                          radius: 50,
                                          backgroundImage:
                                              _profileImage != null
                                                  ? FileImage(_profileImage!)
                                                  : const AssetImage(
                                                        'assets/profile.jpg',
                                                      )
                                                      as ImageProvider,
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
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                role,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Divider(color: Colors.white30),
                              _glassRow(
                                Icons.email,
                                'shutterlifephotography10@gmail.com',
                              ),
                              const SizedBox(height: 12),
                              _glassRow(Icons.phone, '+91 63601 20253'),
                              const SizedBox(height: 12),
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
                  const SizedBox(height: 24),
                  // 🔵 Backup and Restore buttons outside the main container
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Container(
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                await backupHiveToLocal();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Backup Successful")),
                                );
                              },
                              borderRadius: BorderRadius.circular(
                                12,
                              ), // All corners will have 12 radius
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ), // All corners will have 12 radius
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.backup, color: Colors.white),
                                    Text(
                                      "Backup",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                await restoreHiveFromLocalBackup();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Restore Complete")),
                                );
                              },
                              borderRadius: BorderRadius.circular(
                                12,
                              ), // All corners will have 12 radius,
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ), // All corners will have 12 radius,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.restore, color: Colors.white),
                                    Text(
                                      "Restore",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
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
        ],
      ),
    );
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

// ✅ Backup & Restore Functions (No change to any existing logic)
Future<void> backupHiveToLocal() async {
  final status = await Permission.storage.request();
  if (!status.isGranted) return;

  final appDir = await getApplicationDocumentsDirectory();
  final hiveFile = File('${appDir.path}/sales.hive'); // change if needed
  if (!hiveFile.existsSync()) return;

  final downloadsDir = Directory('/storage/emulated/0/Download');
  final backupFile = File('${downloadsDir.path}/sales_backup.hive');
  await hiveFile.copy(backupFile.path);
}

Future<void> restoreHiveFromLocalBackup() async {
  final status = await Permission.storage.request();
  if (!status.isGranted) return;

  final downloadsDir = Directory('/storage/emulated/0/Download/Click Account');
  final backupFile = File('${downloadsDir.path}/sales_backup.hive');
  if (!backupFile.existsSync()) return;

  final appDir = await getApplicationDocumentsDirectory();
  final restoredFile = File('${appDir.path}/sales.hive');
  await backupFile.copy(restoredFile.path);
}
