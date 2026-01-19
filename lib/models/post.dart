import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String title;
  final String body;
  final String scope;
  final String? mediaUrl;
  final String mediaType;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? country;
  final String category;

  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.body,
    required this.scope,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    this.latitude,
    this.longitude,
    this.city,
    this.country,
    this.category = 'General',
  });

  factory Post.fromMap(String id, Map<String, dynamic> data) {
    final rawCreatedAt = data['createdAt'];
    DateTime created;
    if (rawCreatedAt is Timestamp) {
      created = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      created = rawCreatedAt;
    } else {
      created = DateTime.tryParse(rawCreatedAt?.toString() ?? '') ??
          DateTime.now();
    }

    return Post(
      id: id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      scope: data['scope'] as String? ?? 'local',
      mediaUrl: data['mediaUrl'] as String?,
      mediaType: data['mediaType'] as String? ?? 'image',
      createdAt: created,
      likeCount: data['likeCount'] as int? ?? 0,
      commentCount: data['commentCount'] as int? ?? 0,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      city: data['city'] as String?,
      country: data['country'] as String?,
      category: data['category'] as String? ?? 'General',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'title': title,
      'body': body,
      'scope': scope,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'createdAt': createdAt,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'country': country,
      'category': category,
    };
  }
}
