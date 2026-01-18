import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/post.dart';
import '../models/user_profile.dart';
import '../models/signup_data.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static List<Post> _postsFromQuerySnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final posts = snapshot.docs
        .map((doc) => Post.fromMap(doc.id, doc.data()))
        .toList();
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  static Stream<List<Post>> postsByScope(String scope) {
    final query =
        _db.collection('posts').where('scope', isEqualTo: scope);

    if (kIsWeb) {
      return Stream.periodic(const Duration(seconds: 2))
          .asyncMap((_) => query.get())
          .map(_postsFromQuerySnapshot)
          .asBroadcastStream();
    }

    return query.snapshots().map(_postsFromQuerySnapshot);
  }

  static Stream<List<Post>> postsByAuthor(String authorId) {
    final query =
        _db.collection('posts').where('authorId', isEqualTo: authorId);

    if (kIsWeb) {
      return Stream.periodic(const Duration(seconds: 2))
          .asyncMap((_) => query.get())
          .map(_postsFromQuerySnapshot)
          .asBroadcastStream();
    }

    return query.snapshots().map(_postsFromQuerySnapshot);
  }

  static Stream<UserProfile?> userProfileStream(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromMap(doc.id, doc.data()!);
    });
  }

  static Future<UserProfile?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.id, doc.data()!);
  }

  static Future<void> createUserProfile({
    required User user,
    required SignupData data,
    String? profileImageUrl,
  }) async {
    final profile = UserProfile(
      id: user.uid,
      email: user.email ?? data.email ?? '',
      username: data.username ?? user.displayName ?? '',
      firstName: data.firstName,
      lastName: data.lastName,
      location: data.location,
      dob: data.dob,
      phone: null,
      gender: null,
      about: null,
      profileImageUrl: profileImageUrl ?? user.photoURL,
      subscribers: 0,
      contents: 0,
    );

    await _db.collection('users').doc(user.uid).set(profile.toMap());
  }

  static Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? about,
    String? profileImageUrl,
  }) async {
    final Map<String, dynamic> data = {};
    if (displayName != null) {
      data['username'] = displayName;
    }
    if (about != null) {
      data['about'] = about;
    }
    if (profileImageUrl != null) {
      data['profileImageUrl'] = profileImageUrl;
    }

    if (data.isEmpty) return;

    await _db.collection('users').doc(userId).update(data);
  }

  static Future<void> incrementContentCount(String userId) async {
    final userRef = _db.collection('users').doc(userId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;
      final current = snapshot.get('contents') as int? ?? 0;
      transaction.update(userRef, {'contents': current + 1});
    });
  }

  static Future<String> createPost({
    required String authorId,
    required String authorName,
    required String title,
    required String body,
    required String scope,
    String? mediaUrl,
    String mediaType = 'image',
  }) async {
    final ref = _db.collection('posts').doc();
    final post = Post(
      id: ref.id,
      authorId: authorId,
      authorName: authorName,
      title: title,
      body: body,
      scope: scope,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      createdAt: DateTime.now(),
      likeCount: 0,
      commentCount: 0,
    );

    await ref.set(post.toMap());
    await incrementContentCount(authorId);
    return ref.id;
  }
}
