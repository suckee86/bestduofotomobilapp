import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.publishedAt,
    required this.isPublished,
    required this.notificationWasSent,
    this.imageUrl,
    this.imagePath,
    this.targetUrl,
  });

  factory Announcement.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return Announcement(
      id: document.id,
      title: data['title'] as String? ?? 'Best Duo Fotó',
      body: data['body'] as String? ?? '',
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
      isPublished: data['isPublished'] as bool? ?? false,
      notificationWasSent: data['notificationSentAt'] is Timestamp,
      imageUrl: data['imageUrl'] as String?,
      imagePath: data['imagePath'] as String?,
      targetUrl: data['targetUrl'] as String?,
    );
  }

  final String id;
  final String title;
  final String body;
  final DateTime? publishedAt;
  final bool isPublished;
  final bool notificationWasSent;
  final String? imageUrl;
  final String? imagePath;
  final String? targetUrl;
}
