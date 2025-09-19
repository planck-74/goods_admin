import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class FCMTokenService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _tokensPath = 'admin_data';
  static const String _tokensDocument = 'tokens';

  /// Initialize FCM service - call this when app starts
  static Future<void> initialize() async {
    try {
      // Request notification permissions
      await _requestNotificationPermission();

      // Get and save token
      await _getAndSaveToken();

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
    } catch (e) {
      debugPrint('FCM initialization error: $e');
    }
  }

  /// Request notification permission from user
  static Future<bool> _requestNotificationPermission() async {
    try {
      // For iOS and Android 13+
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Additional permission check for Android
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        if (status.isDenied) {
          final result = await Permission.notification.request();
          return result.isGranted;
        }
        return status.isGranted;
      }

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('Permission request error: $e');
      return false;
    }
  }

  /// Get FCM token and save to Firestore
  static Future<void> _getAndSaveToken() async {
    try {
      final String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
        debugPrint('FCM Token saved: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      debugPrint('Get token error: $e');
    }
  }

  /// Save token to Firestore tokens list
  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      final DocumentReference tokensDoc =
          _firestore.collection(_tokensPath).doc(_tokensDocument);

      // Get current document
      final DocumentSnapshot snapshot = await tokensDoc.get();

      List<String> currentTokens = [];

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        currentTokens = List<String>.from(data['tokens'] ?? []);
      }

      // Add token if not already exists
      if (!currentTokens.contains(token)) {
        currentTokens.add(token);

        await tokensDoc.set({
          'tokens': currentTokens,
          'lastUpdated': FieldValue.serverTimestamp(),
          'totalTokens': currentTokens.length,
        }, SetOptions(merge: true));

        debugPrint(
            'Token added to Firestore. Total tokens: ${currentTokens.length}');
      } else {
        debugPrint('Token already exists in Firestore');
      }
    } catch (e) {
      debugPrint('Save token error: $e');
    }
  }

  /// Handle token refresh
  static Future<void> _onTokenRefresh(String token) async {
    debugPrint('FCM Token refreshed');
    await _saveTokenToFirestore(token);
  }

  /// Remove token from Firestore (call when user logs out)
  static Future<void> removeCurrentToken() async {
    try {
      final String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _removeTokenFromFirestore(token);
      }
    } catch (e) {
      debugPrint('Remove token error: $e');
    }
  }

  /// Remove specific token from Firestore
  static Future<void> _removeTokenFromFirestore(String token) async {
    try {
      final DocumentReference tokensDoc =
          _firestore.collection(_tokensPath).doc(_tokensDocument);

      final DocumentSnapshot snapshot = await tokensDoc.get();

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        List<String> currentTokens = List<String>.from(data['tokens'] ?? []);

        if (currentTokens.remove(token)) {
          await tokensDoc.update({
            'tokens': currentTokens,
            'lastUpdated': FieldValue.serverTimestamp(),
            'totalTokens': currentTokens.length,
          });

          debugPrint(
              'Token removed from Firestore. Remaining tokens: ${currentTokens.length}');
        }
      }
    } catch (e) {
      debugPrint('Remove token from Firestore error: $e');
    }
  }

  /// Clean up invalid tokens (call periodically)
  static Future<void> cleanupInvalidTokens() async {
    try {
      final DocumentReference tokensDoc =
          _firestore.collection(_tokensPath).doc(_tokensDocument);

      final DocumentSnapshot snapshot = await tokensDoc.get();

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        List<String> currentTokens = List<String>.from(data['tokens'] ?? []);

        // Here you could implement logic to test token validity
        // For now, we just remove duplicates
        final Set<String> uniqueTokens = currentTokens.toSet();

        if (uniqueTokens.length != currentTokens.length) {
          await tokensDoc.update({
            'tokens': uniqueTokens.toList(),
            'lastUpdated': FieldValue.serverTimestamp(),
            'totalTokens': uniqueTokens.length,
          });

          debugPrint(
              'Duplicate tokens cleaned. Unique tokens: ${uniqueTokens.length}');
        }
      }
    } catch (e) {
      debugPrint('Cleanup tokens error: $e');
    }
  }

  /// Get current FCM token
  static Future<String?> getCurrentToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('Get current token error: $e');
      return null;
    }
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('Check notifications enabled error: $e');
      return false;
    }
  }
}
