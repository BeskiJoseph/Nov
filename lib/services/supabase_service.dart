import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const supabaseUrl = 'https://jnohgpuwflmlyvgrvurt.supabase.co';
    const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impub2hncHV3ZmxtbHl2Z3J2dXJ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg3NTQ0NzYsImV4cCI6MjA4NDMzMDQ3Nn0.UAFOzdyR4BMt7bE4DVXPcKmIKkhyL7Qr4qDjmGGMbK0';

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    _initialized = true;
  }

  static Future<String?> uploadProfileImage({
    required String userId,
    required Uint8List data,
    String fileExtension = 'jpg',
  }) async {
    final fileName =
        'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

    final storage = client.storage.from('profile-images');

    await storage.uploadBinary(fileName, data);

    final url = storage.getPublicUrl(fileName);
    return url;
  }

  static Future<String?> uploadPostMedia({
    required String postId,
    required Uint8List data,
    String fileExtension = 'jpg',
    String mediaType = 'image', // 'image' or 'video'
  }) async {
    final fileName =
        'post_${postId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

    final storage = client.storage.from('post-media');
    
    // Determine content type
    String contentType = 'image/$fileExtension';
    if (mediaType == 'video') {
       contentType = 'video/$fileExtension'; // e.g. video/mp4
    }

    try {
      await storage.uploadBinary(
        fileName,
        data,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true,
        ),
      );
    } catch (e) {
      print('Supabase Storage Upload Error: $e');
      rethrow;
    }

    final url = storage.getPublicUrl(fileName);
    return url;
  }
}
