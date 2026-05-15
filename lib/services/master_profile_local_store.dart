import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/marketplace_project.dart';

class MasterProfileLocalStore {
  static String _photosKey(String masterId) => 'master_profile_photos_$masterId';
  static String _certsKey(String masterId) => 'master_profile_certs_$masterId';
  static String _reviewsKey(String masterId) => 'master_profile_reviews_$masterId';

  Future<List<String>> loadPortfolioPhotos(String masterId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_photosKey(masterId)) ?? <String>[];
  }

  Future<void> savePortfolioPhotos(String masterId, List<String> photos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_photosKey(masterId), photos);
  }

  Future<List<String>> loadCertificates(String masterId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_certsKey(masterId)) ?? <String>[];
  }

  Future<void> saveCertificates(String masterId, List<String> certs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_certsKey(masterId), certs);
  }

  Future<List<MasterReview>> loadReviews(String masterId, List<MasterReview> fallback) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_reviewsKey(masterId));
    if (raw == null || raw.isEmpty) return fallback;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(MasterReview.fromJson)
          .toList();
    } catch (_) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((e) => MasterReview.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  Future<void> saveReviews(String masterId, List<MasterReview> reviews) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(reviews.map((e) => e.toJson()).toList());
    await prefs.setString(_reviewsKey(masterId), raw);
  }
}
