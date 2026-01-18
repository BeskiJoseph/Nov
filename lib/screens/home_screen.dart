import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/post.dart';
import '../models/user_profile.dart';
import 'post_detail_screen.dart';
import 'new_post_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _creatorTabIndex = 0;

  Future<void> _logout() async {
    await AuthService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  Widget _buildPostList(String scope) {
    return StreamBuilder<List<Post>>(
      stream: FirestoreService.postsByScope(scope),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return const Center(
            child: Text('No posts yet'),
          );
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _postCard(post);
          },
        );
      },
    );
  }

  Widget _postCard(Post post) {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostDetailScreen(post: post),
            ),
          );
        },
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
              subtitle: Text(post.title),
              trailing: const Icon(Icons.more_vert),
            ),
            if (post.mediaUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  post.mediaUrl!,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                post.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.favorite, size: 18, color: Colors.red.shade400),
                  const SizedBox(width: 4),
                  Text(post.likeCount.toString()),
                  const SizedBox(width: 16),
                  const Icon(Icons.comment, size: 18),
                  const SizedBox(width: 4),
                  Text(post.commentCount.toString()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).primaryColor,
            child: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: 'Local'),
                Tab(text: 'National'),
                Tab(text: 'Global'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPostList('local'),
                _buildPostList('national'),
                _buildPostList('global'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorDashboard() {
    final user = AuthService.currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<UserProfile?>(
      stream: FirestoreService.userProfileStream(user.uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: profile?.profileImageUrl != null
                        ? NetworkImage(profile!.profileImageUrl!)
                        : null,
                    child: profile?.profileImageUrl == null
                        ? Text(
                            (profile?.username.isNotEmpty == true
                                    ? profile!.username[0]
                                    : user.email?[0] ?? '?')
                                .toUpperCase(),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.username.isNotEmpty == true
                              ? profile!.username
                              : (user.displayName ?? 'Creator'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Welcome to your channel',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statBox(
                    label: 'Subscribers',
                    value: profile?.subscribers ?? 0,
                  ),
                  _statBox(
                    label: 'Contents',
                    value: profile?.contents ?? 0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _creatorTabButton(0, 'About me'),
                  const SizedBox(width: 8),
                  _creatorTabButton(1, 'Subscribers'),
                  const SizedBox(width: 8),
                  _creatorTabButton(2, 'Contents'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildCreatorTabContent(user.uid, profile),
            ),
          ],
        );
      },
    );
  }

  Widget _statBox({required String label, required int value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _creatorTabButton(int index, String label) {
    final isSelected = _creatorTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _creatorTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade200,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreatorTabContent(String userId, UserProfile? profile) {
    if (_creatorTabIndex == 0) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          profile?.about ??
              'Share something about yourself and your content here.',
        ),
      );
    }

    if (_creatorTabIndex == 1) {
      return const Center(
        child: Text('Subscriber list will appear here'),
      );
    }

    return StreamBuilder<List<Post>>(
      stream: FirestoreService.postsByAuthor(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return const Center(
            child: Text('You have not posted any content yet'),
          );
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _postCard(post);
          },
        );
      },
    );
  }

  Widget _buildAccount() {
    final user = AuthService.currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<UserProfile?>(
      stream: FirestoreService.userProfileStream(user.uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: profile?.profileImageUrl != null
                          ? NetworkImage(profile!.profileImageUrl!)
                          : null,
                      child: profile?.profileImageUrl == null
                          ? Text(
                              (profile?.username.isNotEmpty == true
                                      ? profile!.username[0]
                                      : user.email?[0] ?? '?')
                                  .toUpperCase(),
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile?.username.isNotEmpty == true
                          ? profile!.username
                          : (user.displayName ?? ''),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.email ?? user.email ?? '',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Change profile picture'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text('Edit profile'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'My Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _accountTile('My Posts'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _accountTile('My Earnings'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _accountTile('My Subscribers'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Personal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _infoRow('Name',
                  '${profile?.firstName ?? ''} ${profile?.lastName ?? ''}'),
              _infoRow('Date of birth', profile?.dob ?? ''),
              _infoRow('Location', profile?.location ?? ''),
              _infoRow('Contact information', profile?.phone ?? ''),
              _infoRow('Email', profile?.email ?? user.email ?? ''),
            ],
          ),
        );
      },
    );
  }

  Widget _accountTile(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      alignment: Alignment.center,
      child: Text(title),
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget getCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return _buildFeed();
      case 1:
        return _buildCreatorDashboard();
      case 2:
        return _buildAccount();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LocalMe"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NewPostScreen(),
                ),
              );
            },
            tooltip: 'New Post',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: getCurrentTab(),

      // 🔻 Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.view_list),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_collection),
            label: 'Creator',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
