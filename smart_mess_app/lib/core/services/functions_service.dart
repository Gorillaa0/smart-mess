import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

final functionsServiceProvider = Provider<FunctionsService>((ref) => FunctionsService());

class FunctionsService {
  // Cloud Run backend URL — update this after deploying to Google Cloud Run
  static const String _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:3001',
  );

  final Dio _dio = Dio();

  /// Get the current user's Firebase ID token for auth headers
  Future<String?> _getToken() async {
    return await FirebaseAuth.instance.currentUser?.getIdToken();
  }

  /// Build authenticated headers
  Future<Map<String, String>> _authHeaders() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Mark mess-off for a meal
  Future<void> markMessOff(String mealId, String date) async {
    final headers = await _authHeaders();
    try {
      await _dio.post(
        '$_backendUrl/messoff/mark',
        data: {'mealId': mealId, 'date': date},
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to mark mess-off');
    }
  }

  /// Cancel an active mess-off
  Future<void> cancelMessOff(String messOffId) async {
    final headers = await _authHeaders();
    try {
      await _dio.post(
        '$_backendUrl/messoff/cancel',
        data: {'messOffId': messOffId},
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to cancel mess-off');
    }
  }

  /// Verify QR code scan for attendance
  Future<bool> verifyQR(String mealId, String token, String sessionId) async {
    final headers = await _authHeaders();
    try {
      final response = await _dio.post(
        '$_backendUrl/meals/verifyQR',
        data: {'mealId': mealId, 'token': token, 'sessionId': sessionId},
        options: Options(headers: headers),
      );
      return response.data['success'] ?? false;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'QR verification failed');
    }
  }
}
