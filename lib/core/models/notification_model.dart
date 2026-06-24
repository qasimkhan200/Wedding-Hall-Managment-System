/// Mirrors the NotificationPayload from the backend.
/// All FCM data fields arrive as strings — we parse them here.
class NotificationModel {
  final String type;
  final String title;
  final String body;
  final String? imageUrl;
  final String? screen;
  final Map<String, String> data;

  const NotificationModel({
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.screen,
    this.data = const {},
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    // FCM data payload — all values are strings
    final raw = Map<String, String>.from(
      (map['data'] as Map?)
              ?.map((k, v) => MapEntry(k.toString(), v.toString())) ??
          {},
    );

    return NotificationModel(
      type: raw['type'] ?? map['type']?.toString() ?? 'general',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      imageUrl: raw['imageUrl'] ?? map['imageUrl']?.toString(),
      screen: raw['screen']?.isNotEmpty == true ? raw['screen'] : null,
      data: raw,
    );
  }

  /// Build from a raw FCM data-only message (no notification block).
  factory NotificationModel.fromData(Map<String, dynamic> data) {
    return NotificationModel(
      type: data['type']?.toString() ?? 'general',
      title: data['title']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString(),
      screen: data['screen']?.toString().isNotEmpty == true
          ? data['screen']?.toString()
          : null,
      data: Map<String, String>.from(
        data.map((k, v) => MapEntry(k.toString(), v.toString())),
      ),
    );
  }
}
