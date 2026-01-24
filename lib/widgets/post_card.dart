import 'dart:async';
import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../screens/post_detail_screen.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  // Optimistic state overrides
  bool? _optimisticLiked;
  int? _optimisticLikeCount;
  Timer? _debounceTimer;

  void _toggleLike(String userId, bool streamLiked, int streamCount) {
     // 1. Determine target state based on CURRENT optimistic state (or stream if null)
    final bool currentOptimistic = _optimisticLiked ?? streamLiked;
    final bool newTarget = !currentOptimistic;

    // 2. Count Logic
    // If our new target matches the stream, count should be the stream count.
    // If new target is TRUE (and stream is FALSE), count = stream + 1
    // If new target is FALSE (and stream is TRUE), count = stream - 1
    final int newCount;
    if (newTarget == streamLiked) {
      newCount = streamCount;
    } else if (newTarget) {
      newCount = streamCount + 1;
    } else {
      newCount = streamCount > 0 ? streamCount - 1 : 0;
    }

    // 3. Apply optimistic update immediately
    setState(() {
      _optimisticLiked = newTarget;
      _optimisticLikeCount = newCount;
    });

    // 4. Debounce Network Request
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      // Check if the FINAL desired state differs from the server state
      // Even if it doesn't differ in our local view, we can send the Idempotent request to be sure,
      // but saving bandwidth is better.
      // However, if we think newTarget != streamLiked, we MUST set it.
      if (newTarget != streamLiked) {
         // USE IDEMPOTENT SET
         FirestoreService.setPostLike(widget.post.id, userId, newTarget).catchError((e) {
           if (mounted) {
             // If failed, revert UI
             setState(() {
               _optimisticLiked = null; // Revert to stream source
               _optimisticLikeCount = null;
             });
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text("Failed to like post. Check connection.")),
             );
           }
         });
      }
      _debounceTimer = null;
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostDetailScreen(post: widget.post),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                child: Text(
                  widget.post.authorName.isNotEmpty
                      ? widget.post.authorName[0].toUpperCase()
                      : '?',
                ),
              ),
              title: Text(widget.post.authorName),
              subtitle: Text(widget.post.title),
              trailing: const Icon(Icons.more_vert),
            ),
            if (widget.post.mediaUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  widget.post.mediaUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image, size: 50),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                widget.post.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                   // We need the stream to know the "Server Truth"
                  StreamBuilder<bool>(
                    stream: user != null
                        ? FirestoreService.isPostLikedStream(widget.post.id, user.uid)
                        : Stream.value(false),
                    builder: (context, snapshot) {
                      // Server Truth
                      final streamLiked = snapshot.data ?? false;
                      // We can assume the passed-in post.likeCount is the "server truth" for count
                      // UNTIL real-time count updates are wired up via stream for the post itself.
                      // Note: In a real app, you'd likely listen to the Post document stream too,
                      // but here we only have isPostLikedStream.
                      // So we use widget.post.likeCount as the base.
                      final streamCount = widget.post.likeCount;

                      // Check if our optimistic state matches the stream (eventual consistency achieved)
                      // If stream has caught up, we can clear our override to reset to single source of truth
                      if (_optimisticLiked == streamLiked) {
                         // This safely resets the override only when data matches, preventing "jump back"
                         // Schedule this for next frame to avoid setState during build
                         WidgetsBinding.instance.addPostFrameCallback((_) {
                           if (mounted && _optimisticLiked != null) {
                             setState(() {
                               _optimisticLiked = null;
                               // We might not want to reset count yet if we don't have a live stream for it,
                               // but usually if like state matches, count is likely updated or close enough.
                               // meaningful only if we have a real-time post stream.
                               _optimisticLikeCount = null; 
                             });
                           }
                         });
                      }

                      // Display Logic: Prefer Optimistic -> Stream -> Default
                      final isLiked = _optimisticLiked ?? streamLiked;
                      
                      // For count, we need to be careful.
                      // If we have an optimistic count, use it.
                      // If not, use the widget data.
                      // IMPORTANT: Since we don't have a live stream for the specific Post document here
                      // (only the 'isLiked' subcollection), the 'widget.post.likeCount' acts as a static snapshot
                      // that only updates when the parent list rebuilds.
                      // So our optimistic count is VERY important to keep until parent refresh.
                      final displayCount = _optimisticLikeCount ?? streamCount;

                      return IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 24,
                          color: isLiked ? Colors.red.shade400 : Colors.grey,
                        ),
                        onPressed: user == null
                            ? null
                            : () => _toggleLike(user.uid, streamLiked, streamCount),
                        tooltip: 'Like',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  // Display the calculated count
                  Text((_optimisticLikeCount ?? widget.post.likeCount).toString()),
                  const SizedBox(width: 24),
                  const Icon(Icons.comment, size: 24, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(widget.post.commentCount.toString()),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
