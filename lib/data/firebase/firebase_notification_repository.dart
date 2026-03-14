import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/notification_model.dart';
import '../../core/enums/enums.dart';
import 'firebase_service.dart';

class FirebaseNotificationRepository {
  final _service = FirebaseService();

  DatabaseReference _userRef(String userId) =>
      _service.notificationsRef.child(userId);

  Future<void> createNotification(NotificationModel notification) async {
    try {
      final ref = _userRef(notification.recipientId).push();
      await ref.set(_toMap(notification));
    } catch (_) {
      // Best-effort: don't break the caller if notification write fails
    }
  }

  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _userRef(userId)
        .orderByChild('createdAt')
        .onValue
        .map((event) => _parseSnapshot(event.snapshot));
  }

  Stream<int> streamUnreadCount(String userId) {
    return _userRef(userId).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return 0;
      final map = Map<String, dynamic>.from(event.snapshot.value as Map);
      return map.values.where((v) {
        final data = Map<String, dynamic>.from(v as Map);
        return data['isRead'] != true;
      }).length;
    });
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    await _userRef(userId).child(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final snap = await _userRef(userId).get();
    if (!snap.exists || snap.value == null) return;
    final map = Map<String, dynamic>.from(snap.value as Map);
    final updates = <String, dynamic>{};
    for (final key in map.keys) {
      updates['$key/isRead'] = true;
    }
    await _userRef(userId).update(updates);
  }

  List<NotificationModel> _parseSnapshot(DataSnapshot snapshot) {
    if (!snapshot.exists || snapshot.value == null) return [];
    final map = Map<String, dynamic>.from(snapshot.value as Map);
    final list = map.entries.map((e) {
      final data = Map<String, dynamic>.from(e.value as Map);
      return _fromMap(e.key, data);
    }).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Map<String, dynamic> _toMap(NotificationModel n) {
    return {
      'recipientId': n.recipientId,
      'type': n.type.name,
      'title': n.title,
      'message': n.message,
      'isRead': n.isRead,
      'createdAt': n.createdAt.millisecondsSinceEpoch,
      'referenceId': n.referenceId ?? '',
    };
  }

  NotificationModel _fromMap(String key, Map<String, dynamic> data) {
    return NotificationModel(
      id: key,
      recipientId: data['recipientId'] as String? ?? '',
      type: NotificationType.values.byName(data['type'] as String),
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      isRead: data['isRead'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
      referenceId: _nullIfEmpty(data['referenceId']),
    );
  }

  String? _nullIfEmpty(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    return s.isEmpty ? null : s;
  }
}
