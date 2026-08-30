class AppNotificationModel {
  final String notificationId;
  final String vanityItemId;
  final DateTime notifyDate;
  final String type; // 'expiring_soon' | 'expired'
  final bool sent;

  const AppNotificationModel({
    required this.notificationId,
    required this.vanityItemId,
    required this.notifyDate,
    required this.type,
    this.sent = false,
  });

  factory AppNotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return AppNotificationModel(
      notificationId: id,
      vanityItemId: map['vanity_item_id'] as String? ?? '',
      notifyDate: map['notify_date'] != null
          ? DateTime.parse(map['notify_date'] as String)
          : DateTime.now(),
      type: map['type'] as String? ?? 'expiring_soon',
      sent: map['sent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notification_id': notificationId,
      'vanity_item_id': vanityItemId,
      'notify_date': notifyDate.toIso8601String(),
      'type': type,
      'sent': sent,
    };
  }
}
