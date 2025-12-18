// Stub file for web platform when dart:io is not available
// This file is only used on web and provides placeholder types

class File {
  final String path;
  File(this.path);
  Future<bool> exists() => Future.value(false);
}

class Directory {
  final String path;
  Directory(this.path);
  Future<bool> exists() => Future.value(false);
  Future<Directory> create({bool recursive = false}) => Future.value(this);
}


