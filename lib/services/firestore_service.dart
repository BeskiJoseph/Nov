import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/post.dart';
import '../models/user_profile.dart';
import '../models/signup_data.dart';
import '../models/comment.dart';

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
    // Legacy support or specific scope query
    final query = _db.collection('posts').where('scope', isEqualTo: scope);
    if (kIsWeb) {
      return Stream.periodic(const Duration(seconds: 2))
          .asyncMap((_) => query.get())
          .map(_postsFromQuerySnapshot)
          .asBroadcastStream();
    }
    return query.snapshots().map(_postsFromQuerySnapshot);
  }

  static Stream<List<Post>> postsForFeed({
    required String feedType,
    String? userCity,
    String? userCountry,
  }) {
    Query<Map<String, dynamic>> query = _db.collection('posts');

    if (feedType == 'local' && userCity != null) {
      query = query.where('city', isEqualTo: userCity);
    } else if ((feedType == 'national' || feedType == 'global') && userCountry != null) {
      query = query.where('country', isEqualTo: userCountry);
    }
    // Else return all posts or empty (fallback)
    
    // Sort by createdAt desc - requires composite index if filtering by field
    // For now, we might rely on client side sort or simple query
    // Query: collection('posts').where('city', ==, 'City').orderBy('createdAt', descending: true)
    
    // query = query.orderBy('createdAt', descending: true); // Removing to avoid Index requirement for now

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
    String scope = 'local', // Legacy/Default
    
    // New fields
    double? latitude,
    double? longitude,
    String? city,
    String? country,
    String category = 'General',
    
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
      latitude: latitude,
      longitude: longitude,
      city: city,
      country: country,
      category: category,
    );

    await ref.set(post.toMap());
    await incrementContentCount(authorId);
    return ref.id;
  }

  static Future<void> toggleLikePost(String postId, String userId) async {
    final postRef = _db.collection('posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(userId);

    await _db.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      final postDoc = await transaction.get(postRef);

      if (!postDoc.exists) return;

      int currentLikes = postDoc.data()?['likeCount'] ?? 0;

      if (likeDoc.exists) {
        // Unlike
        transaction.delete(likeRef);
        transaction.update(postRef, {'likeCount': currentLikes > 0 ? currentLikes - 1 : 0});
      } else {
        // Like
        transaction.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
        transaction.update(postRef, {'likeCount': currentLikes + 1});
      }
    }).catchError((e) {
      if (kDebugMode) print("Like Error: $e");
       // Force the friendly message because 99% of errors here are permissions
      throw "Permission Denied. Please Check your Firebase Console > Firestore rules are published.";
    });
  }

  static Stream<bool> isPostLikedStream(String postId, String userId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  static Future<void> followUser(String currentUserId, String targetUserId) async {
    final currentUserRef = _db.collection('users').doc(currentUserId);
    final targetUserRef = _db.collection('users').doc(targetUserId);

    final followingRef = currentUserRef.collection('following').doc(targetUserId);
    final followersRef = targetUserRef.collection('followers').doc(currentUserId);

    await _db.runTransaction((transaction) async {
      final followingDoc = await transaction.get(followingRef);
      if (followingDoc.exists) return; // Already following

      transaction.set(followingRef, {'createdAt': FieldValue.serverTimestamp()});
      transaction.set(followersRef, {'createdAt': FieldValue.serverTimestamp()});

      // Update subscribers count
      final targetDoc = await transaction.get(targetUserRef);
      if (targetDoc.exists) {
         int subscribers = targetDoc.data()?['subscribers'] ?? 0;
         transaction.update(targetUserRef, {'subscribers': subscribers + 1});
      }
    }).catchError((e) {
      if (kDebugMode) print("Follow Error: $e");
      // Force the friendly message because 99% of errors here are permissions
      throw "Permission Denied. Please Check your Firebase Console > Firestore rules are published.";
    });
  }

  static Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    final currentUserRef = _db.collection('users').doc(currentUserId);
    final targetUserRef = _db.collection('users').doc(targetUserId);

    final followingRef = currentUserRef.collection('following').doc(targetUserId);
    final followersRef = targetUserRef.collection('followers').doc(currentUserId);

    await _db.runTransaction((transaction) async {
      final followingDoc = await transaction.get(followingRef);
      if (!followingDoc.exists) return; // Not following

      transaction.delete(followingRef);
      transaction.delete(followersRef);

       // Update subscribers count
      final targetDoc = await transaction.get(targetUserRef);
      if (targetDoc.exists) {
         int subscribers = targetDoc.data()?['subscribers'] ?? 0;
         transaction.update(targetUserRef, {'subscribers': subscribers > 0 ? subscribers - 1 : 0});
      }
    }).catchError((e) {
      if (kDebugMode) print("Unfollow Error: $e");
      String msg = e.toString().toLowerCase();
      if (msg.contains("permission-denied") || msg.contains("forbidden") || msg.contains("dart exception")) {
        throw "Permission Denied. Go to Firebase Console > Firestore > Rules and allow writes.";
      }
      throw e;
    });
  }

  static Stream<bool> isUserFollowedStream(String currentUserId, String targetUserId) {
    return _db
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // Comments
  static Stream<List<Comment>> commentsStream(String postId) {
    final query = _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true); // Newest first

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Comment.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  static Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    String? authorProfileImage,
    required String text,
  }) async {
    final postRef = _db.collection('posts').doc(postId);
    final commentsRef = postRef.collection('comments');

    await _db.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);
      if (!postDoc.exists) return;

      // Add comment
      final newCommentRef = commentsRef.doc();
      transaction.set(newCommentRef, {
        'postId': postId,
        'authorId': authorId,
        'authorName': authorName,
        'authorProfileImage': authorProfileImage,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update count
      int currentComments = postDoc.data()?['commentCount'] ?? 0;
      transaction.update(postRef, {'commentCount': currentComments + 1});
    }).catchError((e) {
      if (kDebugMode) print("Add Comment Error: $e");
       // Force the friendly message because 99% of errors here are permissions
      throw "Permission Denied. Please Check your Firebase Console > Firestore rules are published.";
    });
  }
}

