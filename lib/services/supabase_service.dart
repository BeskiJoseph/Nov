import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const supabaseUrl = 'https://jnohgpwflmlygvurvt.supabase.co';
    const supabaseAnonKey = 'sb_publishable_yoYDo3YyybgqkF-oBLzCAA_bgoYAS9e';

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
  }) async {
    final fileName =
        'post_${postId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

    final storage = client.storage.from('post-media');

    await storage.uploadBinary(fileName, data);

    final url = storage.getPublicUrl(fileName);
    return url;
  }
}
