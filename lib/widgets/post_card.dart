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

    return Container(
      // Spec 4: Margin 12px vertical. (Horizontal not specified, adhering to 16px safe width or implicit).
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Spec: 16px
        boxShadow: [
          // Spec: Color #0000001A (approx 0.1 opacity), Blur 20, Offset (0, 6)
          BoxShadow(
            color: const Color(0x1A000000), 
            offset: const Offset(0, 6),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostDetailScreen(post: widget.post),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14), // Spec: 14px
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 5️⃣ User Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    width: 40, 
                    height: 40,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4C5EFF), // Spec: #4C5EFF
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      widget.post.authorName.isNotEmpty
                          ? widget.post.authorName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600, // Spec: 600
                        fontSize: 18, // Spec: 18px
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12), // Spacing not strictly specified but standard
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username
                        Text(
                          widget.post.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600, // Spec: 600
                            fontSize: 15, // Spec: 15px
                            color: Color(0xFF1C1C1E), // Spec: #1C1C1E
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Meta Text
                        Text(
                          _formatTimeAgo(widget.post.createdAt),
                          style: const TextStyle(
                            color: Color(0xFF8E8E93), // Spec: #8E8E93
                            fontSize: 12, // Spec: 12px
                            fontWeight: FontWeight.w400, // Spec: 400
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Menu Icon
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    color: const Color(0xFF8E8E93), // Spec: #8E8E93
                    iconSize: 18, // Spec: 18px
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              
              // 6️⃣ Post Content Text
              Text(
                widget.post.body,
                maxLines: 5, // Spec: 5
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14, // Spec: 14px
                  fontWeight: FontWeight.w400, // Spec: 400
                  color: Color(0xFF2C2C2E), // Spec: #2C2C2E
                  height: 1.4, // Spec: Line Height 1.4
                  fontFamily: 'Inter',
                ),
              ),

              // 7️⃣ Post Image
              if (widget.post.mediaUrl != null) ...[
                const SizedBox(height: 12), // Spec: Margin Top 12px
                ClipRRect(
                  borderRadius: BorderRadius.circular(14), // Spec: 14px
                  child: AspectRatio(
                    aspectRatio: 16 / 9, // Spec: 16:9
                    child: Image.network(
                      widget.post.mediaUrl!,
                      fit: BoxFit.cover, // Spec: Cover
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade100,
                        alignment: Alignment.center,
                        child: Icon(Icons.broken_image, 
                          color: Colors.grey.shade300, 
                          size: 50
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16), // Spec says "Between actions: 16px". Assuming this means between action row items or padding? 
              // Usually spacing above actions.

              // 8️⃣ Action Row
              StreamBuilder<bool>(
                stream: user != null
                    ? FirestoreService.isPostLikedStream(widget.post.id, user.uid)
                    : Stream.value(false),
                builder: (context, snapshot) {
                  final streamLiked = snapshot.data ?? false;
                  final streamCount = widget.post.likeCount;
                  
                  if (_optimisticLiked == streamLiked) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _optimisticLiked != null) {
                          setState(() {
                            _optimisticLiked = null;
                            _optimisticLikeCount = null; 
                          });
                        }
                      });
                  }

                  final isLiked = _optimisticLiked ?? streamLiked;
                  final displayCount = _optimisticLikeCount ?? streamCount;

                  return Row(
                    children: [
                      // Like Action
                      Row(
                        children: [
                          InkWell(
                            onTap: user == null
                                ? null
                                : () => _toggleLike(user.uid, streamLiked, streamCount),
                            child: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 20, // Spec: 20px
                              color: isLiked 
                                ? const Color(0xFFFF4D4D) // Spec: Active #FF4D4D
                                : const Color(0xFF8E8E93), // Spec: Inactive #8E8E93
                            ),
                          ),
                          const SizedBox(width: 6), // Spec: Icon <-> Text 6px
                          Text(
                            displayCount.toString(),
                            style: const TextStyle(
                              color: Color(0xFF3A3A3C), // Spec: #3A3A3C
                              fontWeight: FontWeight.w500, // Spec: 500
                              fontSize: 13, // Spec: 13px
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(width: 16), // Spec: Between actions 16px

                      // Comment Action
                      Row(
                        children: [
                          const Icon(
                             Icons.chat_bubble_outline, 
                             size: 20, // Spec 20px
                             color: Color(0xFF8E8E93), // Spec #8E8E93
                          ),
                           const SizedBox(width: 6), // Spec 6px
                          Text(
                            widget.post.commentCount.toString(),
                            style: const TextStyle(
                              color: Color(0xFF3A3A3C), // Spec: #3A3A3C
                              fontWeight: FontWeight.w500, // Spec: 500
                              fontSize: 13, // Spec: 13px
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
