// lib/providers/environment_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnvironmentProvider extends ChangeNotifier {
  
  // ========== STATE ==========
  String? _currentEnvironmentId;
  String? _currentEnvironmentName;
  Map<String, dynamic>? _environmentData;
  bool _isLoading = false;

  // ========== GETTERS ==========
  String? get currentEnvironmentId => _currentEnvironmentId;
  String? get currentEnvironmentName => _currentEnvironmentName;
  Map<String, dynamic>? get environmentData => _environmentData;
  bool get isLoading => _isLoading;

  // ========== SETTERS ==========
  void setCurrentEnvironment(String id, String name) {
    _currentEnvironmentId = id;
    _currentEnvironmentName = name;
    notifyListeners();
  }

  void setEnvironmentData(Map<String, dynamic> data) {
    _environmentData = data;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // ========== QUERY FUNCTIONS ==========
  // TODO: Add Firebase queries

  // ========== SAVE FUNCTIONS ==========
  // TODO: Add save to Firebase

  // ========== CLEAR ==========
  void clear() {
    _currentEnvironmentId = null;
    _currentEnvironmentName = null;
    _environmentData = null;
    _isLoading = false;
    notifyListeners();
  }
}