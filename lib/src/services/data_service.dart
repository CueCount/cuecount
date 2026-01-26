// lib/services/data_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class DataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== CLUSTER QUERIES ==========

  /// Search clusters by tag name
  /// Called when search query starts with "#"
  Future<List<Map<String, dynamic>>> searchClustersByTag(String tagName) async {
    try {
      final querySnapshot = await _firestore
          .collection('clusters')
          .where('tag', isEqualTo: tagName)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error searching clusters by tag: $e');
      return [];
    }
  }

  /// Search clusters by name (partial match)
  /// Called when search query does NOT start with "#"
  Future<List<Map<String, dynamic>>> searchClustersByName(String searchTerm) async {
    try {
      // Firestore doesn't support native "contains" queries,
      // so we use a range query for prefix matching
      // For more complex search, consider Algolia or similar
      final querySnapshot = await _firestore
          .collection('clusters')
          .where('name', isGreaterThanOrEqualTo: searchTerm)
          .where('name', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error searching clusters by name: $e');
      return [];
    }
  }

  /// Combined search method that determines query type based on input
  /// - Starts with "#" → search by tag
  /// - No "#" → search by name
  Future<List<Map<String, dynamic>>> searchClusters(String query) async {
    if (query.isEmpty) {
      return [];
    }

    if (query.startsWith('#')) {
      // Remove the "#" and search by tag
      final tagName = query.substring(1).trim();
      if (tagName.isEmpty) return [];
      return searchClustersByTag(tagName);
    } else {
      // Search by name
      return searchClustersByName(query.trim());
    }
  }

  /// Get a single cluster by document ID
  Future<Map<String, dynamic>?> getClusterById(String clusterId) async {
    try {
      final docSnapshot = await _firestore
          .collection('clusters')
          .doc(clusterId)
          .get();

      if (docSnapshot.exists) {
        return {
          'id': docSnapshot.id,
          ...docSnapshot.data()!,
        };
      }
      return null;
    } catch (e) {
      print('Error fetching cluster by ID: $e');
      return null;
    }
  }

  /// Extract trend names from a cluster's data map
  /// Returns list of trend names (keys from the data map)
  List<String> getTrendNamesFromCluster(Map<String, dynamic> clusterData) {
    final data = clusterData['data'];
    if (data is Map) {
      return data.keys.map((key) => key.toString()).toList();
    }
    return [];
  }

  /// Get all clusters (optional - for loading all data)
  Future<List<Map<String, dynamic>>> getAllClusters() async {
    try {
      final querySnapshot = await _firestore
          .collection('clusters')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error fetching all clusters: $e');
      return [];
    }
  }

  /// Stream clusters by tag (for real-time updates)
  Stream<List<Map<String, dynamic>>> streamClustersByTag(String tagName) {
    return _firestore
        .collection('clusters')
        .where('tag', isEqualTo: tagName)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                ...data,
              };
            }).toList());
  }

  /// Stream clusters by name prefix (for real-time updates)
  Stream<List<Map<String, dynamic>>> streamClustersByName(String searchTerm) {
    return _firestore
        .collection('clusters')
        .where('name', isGreaterThanOrEqualTo: searchTerm)
        .where('name', isLessThanOrEqualTo: '$searchTerm\uf8ff')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                ...data,
              };
            }).toList());
  }

}