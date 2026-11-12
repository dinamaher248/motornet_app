import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:motorent/firebase_options.dart';

/// Marks Firebase ride chat rooms as closed so messaging stops after order end.
class RideChatLock {
  RideChatLock._();

  static Future<void> _ensureFirebase() async {
    try {
      Firebase.app();
    } catch (_) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  static FirebaseDatabase _db() {
    return FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: DefaultFirebaseOptions.databaseUrl,
    );
  }

  static Future<void> _closePath(String roomKey) async {
    final id = roomKey.trim();
    if (id.isEmpty || id == 'null' || id == '0') return;
    await _db().ref('ride_chats/$id').update({
      'isClosed': true,
      'closedAt': ServerValue.timestamp,
      'updatedAt': ServerValue.timestamp,
    });
  }

  /// [roomId] يمكن أن يكون `bidding_trip_12` أو رقم قديم أو `ride_12`.
  static Future<void> closeRoom(String? roomId, {String? orderType, int? orderId}) async {
    try {
      await _ensureFirebase();
      final keys = <String>{};

      final raw = (roomId ?? '').trim();
      if (raw.isNotEmpty && raw != 'null' && raw != '0') {
        if (raw.startsWith('ride_') || raw.contains('_')) {
          keys.add(raw);
        } else {
          keys.add('ride_$raw');
          if (orderType != null && orderType.isNotEmpty) {
            keys.add('${orderType}_$raw');
          }
        }
      }

      if (orderType != null &&
          orderType.isNotEmpty &&
          orderId != null &&
          orderId > 0) {
        keys.add('${orderType}_$orderId');
        keys.add('ride_$orderId');
      }

      for (final key in keys) {
        try {
          await _closePath(key);
        } catch (e) {
          debugPrint('RideChatLock.closeRoom path $key skipped: $e');
        }
      }
    } catch (e) {
      debugPrint('RideChatLock.closeRoom skipped: $e');
    }
  }
}
