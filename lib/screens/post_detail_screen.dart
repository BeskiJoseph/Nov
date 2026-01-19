import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/auth_service.dart';

import '../models/post.dart';
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
      body: SingleChildScrollView(
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
                  _actionButton(Icons.mode_comment_outlined, 'Comment', () {}),
                  _actionButton(Icons.flag_outlined, 'Report', () {}),
                ],
              ),
            ),
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
      return _actionButton(Icons.thumb_up_alt_outlined, 'Like', () {});
    }

    return StreamBuilder<bool>(
      stream: FirestoreService.isPostLikedStream(widget.post.id, user.uid),
      builder: (context, snapshot) {
        final isLiked = snapshot.data ?? false;
        return _actionButton(
          isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
          'Like',
          () => FirestoreService.toggleLikePost(widget.post.id, user.uid),
        );
      },
    );
  }

  Widget _buildSubscribeButton() {
    final user = AuthService.currentUser;
    if (user == null || user.uid == widget.post.authorId) {
      return _actionButton(Icons.subscriptions_outlined, 'Subscribe', () {});
    }

    return StreamBuilder<bool>(
      stream: FirestoreService.isUserFollowedStream(user.uid, widget.post.authorId),
      builder: (context, snapshot) {
        final isFollowed = snapshot.data ?? false;
        return _actionButton(
          isFollowed ? Icons.check_circle : Icons.add_circle_outline,
          isFollowed ? 'Subscribed' : 'Subscribe',
          () {
            if (isFollowed) {
              FirestoreService.unfollowUser(user.uid, widget.post.authorId);
            } else {
              FirestoreService.followUser(user.uid, widget.post.authorId);
            }
          },
        );
      },
    );
  }
}
