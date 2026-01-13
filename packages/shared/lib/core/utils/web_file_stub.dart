// Stub for web platform - File operations are not available on web
// This file provides a minimal stub to allow conditional compilation
// On web, file operations should use file.bytes directly from FilePicker
import 'dart:typed_data';

class File {
  final String path;
  File(this.path);
  Future<bool> exists() async => false;
  Future<Uint8List> readAsBytes() async => Uint8List(0);
}

