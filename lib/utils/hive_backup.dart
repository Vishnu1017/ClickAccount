import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> backupHiveToLocal() async {
  final status = await Permission.storage.request();
  if (!status.isGranted) return;

  final appDir = await getApplicationDocumentsDirectory();
  final hiveFile = File(
    '${appDir.path}/sales.hive',
  ); // Replace with your actual box file name
  if (!hiveFile.existsSync()) return;

  final downloadsDir = Directory('/storage/emulated/0/Download/Click Account');
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
