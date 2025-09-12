import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import 'package:streamshort/features/auth/data/models/auth_models.dart';

class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _tokenExpiryKey = 'token_expiry';

  // Save authentication data
  static Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required User user,
    required int expiresIn,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_userDataKey, jsonEncode(user.toJson()));
    
    // Calculate expiry time (current time + expires_in seconds)
    final expiryTime = DateTime.now().add(Duration(seconds: expiresIn)).millisecondsSinceEpoch;
    await prefs.setInt(_tokenExpiryKey, expiryTime);
  }

  // Get access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  // Get refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // Get user data
  static Future<User?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userDataKey);
    
    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return User.fromJson(userMap);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Check if token is expired
  static Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryTime = prefs.getInt(_tokenExpiryKey);
    
    if (expiryTime == null) return true;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    return now >= expiryTime;
  }

  // Check if user is authenticated (has valid token)
  static Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    final isExpired = await isTokenExpired();
    
    return accessToken != null && !isExpired;
  }

  // Clear all authentication data
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_tokenExpiryKey);
  }

  // Update access token (for token refresh)
  static Future<void> updateAccessToken({
    required String accessToken,
    required int expiresIn,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_accessTokenKey, accessToken);
    
    // Update expiry time
    final expiryTime = DateTime.now().add(Duration(seconds: expiresIn)).millisecondsSinceEpoch;
    await prefs.setInt(_tokenExpiryKey, expiryTime);
  }

  // Update user data (for role changes, etc.)
  static Future<void> updateUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(user.toJson()));
  }
}
