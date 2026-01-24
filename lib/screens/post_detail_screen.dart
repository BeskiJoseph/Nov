import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/auth_service.dart';

import '../models/post.dart';
import '../models/comment.dart';
import '../services/firestore_service.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  VideoPlayerController? _videoController;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _isVideo = widget.post.mediaType == 'video' &&
        widget.post.mediaUrl != null &&
        widget.post.mediaUrl!.isNotEmpty;
    if (_isVideo) {
      _videoController = VideoPlayerController.network(widget.post.mediaUrl!)
        ..initialize().then((_) {
          setState(() {});
        })
        ..setLooping(true);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      appBar: AppBar(
        title: Text(post.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        post.authorName.isNotEmpty
                            ? post.authorName[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(post.authorName),
                    subtitle: Text(post.scope.toUpperCase()),
                  ),
                  if (post.mediaUrl != null)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _isVideo && _videoController != null
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                VideoPlayer(_videoController!),
                                IconButton(
                                  icon: Icon(
                                    _videoController!.value.isPlaying
                                        ? Icons.pause_circle
                                        : Icons.play_circle,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (_videoController!.value.isPlaying) {
                                        _videoController!.pause();
                                      } else {
                                        _videoController!.play();
                                      }
                                    });
                                  },
                                ),
                              ],
                            )
                          : Image.network(
                              post.mediaUrl!,
                              fit: BoxFit.cover,
                            ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(post.body),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLikeButton(),
                        _actionButton(Icons.share_outlined, 'Share', () {}),
                        _buildSubscribeButton(),
                        _actionButton(Icons.mode_comment_outlined, 'Comment', () {
                          // Scroll to bottom or focus
                        }),
                        _actionButton(Icons.flag_outlined, 'Report', () {}),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Comments Section Header
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Comments",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildCommentsList(),

                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Recommended',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 190,
                    child: StreamBuilder<List<Post>>(
                      stream: FirestoreService.postsByScope(post.scope),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final items = (snapshot.data ?? [])
                            .where((p) => p.id != post.id)
                            .take(10)
                            .toList();

                        if (items.isEmpty) {
                          return const Center(
                            child: Text('No recommendations yet'),
                          );
                        }

                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return SizedBox(
                              width: 140,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: AspectRatio(
                                      aspectRatio: 4 / 3,
                                      child: item.mediaUrl != null
                                          ? Image.network(
                                              item.mediaUrl!,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: Colors.grey.shade200,
                                              alignment: Alignment.center,
                                              child: const Icon(Icons.image),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.authorName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return StreamBuilder<List<Comment>>(
      stream: FirestoreService.commentsStream(widget.post.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final comments = snapshot.data ?? [];
        if (comments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text("No comments yet. Be the first!")),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: comments.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final comment = comments[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 18,
                backgroundImage: comment.authorProfileImage != null 
                    ? NetworkImage(comment.authorProfileImage!) 
                    : null,
                child: comment.authorProfileImage == null 
                    ? Text(comment.authorName[0].toUpperCase())
                    : null,
              ),
              title: Text(
                comment.authorName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Text(comment.text),
              trailing: Text(
                _formatDate(comment.createdAt),
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            );
          },
        );
      },
    );
  }
  
  String _formatDate(DateTime date) {
    // Simple date formatting
    return "${date.day}/${date.month} ${date.hour}:${date.minute}";
  }

  Widget _buildCommentInput() {
    final TextEditingController commentController = TextEditingController();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: "Add a comment...",
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: () async {
                final text = commentController.text.trim();
                final user = AuthService.currentUser;
                
                if (text.isNotEmpty && user != null) {
                   // Optimistic update or just clear
                   commentController.clear();
                   FocusScope.of(context).unfocus();
                   
                   // Fetch simple profile info or just use User object
                   // Ideally we get profile from Firestore, but for speed using Auth
                   await FirestoreService.addComment(
                     postId: widget.post.id,
                     authorId: user.uid,
                     authorName: user.displayName ?? "User",
                     authorProfileImage: user.photoURL,
                     text: text,
                   );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }


  Widget _buildLikeButton() {
    final user = AuthService.currentUser;
    if (user == null) {
      return _actionButton(Icons.thumb_up_alt_outlined, 'Like', () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login to like posts")),
        );
      });
    }

    return StreamBuilder<bool>(
      stream: FirestoreService.isPostLikedStream(widget.post.id, user.uid),
      builder: (context, snapshot) {
        final isLiked = snapshot.data ?? false;
        return _actionButton(
          isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
          'Like',
          () async {
            try {
              await FirestoreService.toggleLikePost(widget.post.id, user.uid);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Like failed: $e")),
                );
              }
            }
          },
        );
      },
    );
  }

  Widget _buildSubscribeButton() {
    final user = AuthService.currentUser;
    if (user == null || user.uid == widget.post.authorId) {
      return _actionButton(Icons.subscriptions_outlined, 'Subscribe', () {
         if (user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please login to subscribe")),
            );
         }
      });
    }

    return StreamBuilder<bool>(
      stream: FirestoreService.isUserFollowedStream(user.uid, widget.post.authorId),
      builder: (context, snapshot) {
        final isFollowed = snapshot.data ?? false;
        return _actionButton(
          isFollowed ? Icons.check_circle : Icons.add_circle_outline,
          isFollowed ? 'Subscribed' : 'Subscribe',
          () async {
            try {
              if (isFollowed) {
                await FirestoreService.unfollowUser(user.uid, widget.post.authorId);
              } else {
                await FirestoreService.followUser(user.uid, widget.post.authorId);
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Subscribe failed: $e")),
                );
              }
            }
          },
        );
      },
    );
  }
}
