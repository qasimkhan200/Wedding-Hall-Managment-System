import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;

  // Streams
  Stream<List<CategoryModel>> get categoryTreeStream =>
      CategoryService.getCategoriesStream();

  Stream<List<Map<String, dynamic>>> get pendingApplicationsStream =>
      CategoryService.getPendingApplications();

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  // Load all categories
  void loadCategories() {
    CategoryService.getCategoriesStream().listen((categories) {
      _categories = categories;
      notifyListeners();
    }, onError: (e) {
      setError(e.toString());
    });
  }

  // Create category
  Future<bool> createCategory(CategoryModel category) async {
    try {
      setLoading(true);
      await CategoryService.createCategory(category);
      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  // Update category
  Future<bool> updateCategory(CategoryModel category) async {
    try {
      setLoading(true);
      await CategoryService.updateCategory(category);
      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  // Delete category
  Future<bool> deleteCategory(String id) async {
    try {
      setLoading(true);
      await CategoryService.deleteCategory(id);
      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  // Helper getters
  List<CategoryModel> get featuredCategories =>
      _categories.where((c) => c.isFeatured).toList();

  List<CategoryModel> get emergencyCategories =>
      _categories.where((c) => c.emergencyDeliveryMinutes <= 60).toList();

  List<CategoryModel> get restrictedCategories => _categories
      .where((c) =>
          c.tier == CategoryTier.restricted || c.tier == CategoryTier.licensed)
      .toList();
}
