import 'package:flutter/foundation.dart';
import '../models/document_model.dart';

class DocumentProvider extends ChangeNotifier {
  List<Document> _documents = [];
  bool _isLoading = false;

  List<Document> get documents => _documents;
  bool get isLoading => _isLoading;

  List<Document> getDocumentsByType(DocumentType type) {
    return _documents.where((doc) => doc.type == type).toList();
  }

  List<Document> getExpiringDocuments() {
    return _documents.where((doc) => doc.isExpiringSoon).toList();
  }

  List<Document> getExpiredDocuments() {
    return _documents.where((doc) => doc.isExpired).toList();
  }

  Future<void> loadDocuments() async {
    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> uploadDocument(Document document) async {
    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    _documents.add(document);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteDocument(String id) async {
    _documents.removeWhere((doc) => doc.id == id);
    notifyListeners();
  }
}

