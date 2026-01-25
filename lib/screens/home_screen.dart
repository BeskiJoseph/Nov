import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/post.dart';
import '../models/user_profile.dart';
import 'new_post_screen.dart';
import 'welcome_screen.dart';
import '../widgets/post_card.dart';
import 'package:geolocator/geolocator.dart';
import '../services/geocoding_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _creatorTabIndex = 0;
  String? _currentCity;
  String? _currentCountry;
  bool _isLoadingLocation = true;

  String? _locationError;

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'Location services are disabled.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _isLoadingLocation = false;
            _locationError = 'Location permissions are denied.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _isLoadingLocation = false;
          _locationError =
              'Location permissions are permanently denied. Please enable them in your browser/device settings.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      
      final place = await GeocodingService.getPlace(
        position.latitude, 
        position.longitude
      );

      if (!mounted) return;

      if (place['city'] != null || place['country'] != null) {
        setState(() {
          _currentCity = place['city'];
          _currentCountry = place['country'];
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _currentCity = 'Unknown City';
          _currentCountry = 'Unknown Country';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      debugPrint('Error detecting location: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'Error: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _logout() async {
    await AuthService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  Widget _buildPostList(String feedType) {
    if (_isLoadingLocation) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_locationError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                _locationError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _detectLocation,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Location'),
              ),
            ],
          ),
        ),
      );
    }

    if (feedType == 'local' && _currentCity == null) {
      return const Center(
        child: Text('Waiting for location...'),
      );
    }
    if ((feedType == 'national' || feedType == 'global') && _currentCountry == null) {
      return const Center(
        child: Text('Waiting for location...'),
      );
    }

    return StreamBuilder<List<Post>>(
      stream: FirestoreService.postsForFeed(
        feedType: feedType,
        userCity: _currentCity,
        userCountry: _currentCountry,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
             child: Padding(
               padding: const EdgeInsets.all(16.0),
               child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
             ),
          );
        }

        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No posts yet in this area'),
                const SizedBox(height: 8),
                Text(
                  'City: $_currentCity, Country: $_currentCountry',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return PostCard(post: post);
          },
        );
      },
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
            return PostCard(post: post);
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

  // 🔻 Custom App Bar
  Widget _buildCustomAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Invisible icon for balance if needed, or just spacer
           const SizedBox(width: 40),
          
          const Text(
            "LocalMe",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'Inter',
            ),
          ),

          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.black),
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
                icon: const Icon(Icons.logout, color: Colors.black),
                onPressed: _logout,
                tooltip: 'Logout',
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFeed() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // 🔻 Tab Bar (Spec Point 3)
          Container(
            width: double.infinity,
            height: 48, // Spec: 48px
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4C5EFF), Color(0xFF6A5CFF)], // Spec: Gradient
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.zero, // Spec: Radius 0
            ),
            child: const TabBar(
              indicatorColor: Colors.white,
              // Spec: Indicator Height 3px, Width 24px, Radius 2px.
              // Flutter's default indicator is full width. using TabBarIndicatorSize.label helps but width is dynamic.
              // To get EXACT specific width 24px is hard with standard TabBar without custom Painter.
              // We will approximate with label size and padding, or custom indicator if requested. 
              // For now, I will use UnderlineTabIndicator with specific insets to try and conform.
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 3.0, color: Colors.white),
                borderRadius: BorderRadius.all(Radius.circular(2)),
                insets: EdgeInsets.symmetric(horizontal: 40), // Force it smaller? Approximation.
              ),
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Colors.white,
              unselectedLabelColor: Color(0xFFE0E3FF), // Spec: #E0E3FF
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600, // Spec: Active 600
                fontSize: 15,
                fontFamily: 'Inter',
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w500, // Spec: Inactive 500
                fontSize: 15,
                fontFamily: 'Inter',
              ),
              dividerColor: Colors.transparent,
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



  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB), // Spec 1
      body: SafeArea(
        top: true,
        bottom: false, // Let bottom nav handle safe area
        child: Column(
          children: [
            _buildCustomAppBar(),
            Expanded(
              child: getCurrentTab(),
            ),
          ],
        ),
      ),

      // 🔻 Bottom Navigation (Spec Point 9)
      bottomNavigationBar: Container(
        // height: 80, // Removed to prevent overflow on small screens/large font settings
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18), // Spec: 18px
            topRight: Radius.circular(18),
          ),
          boxShadow: [
             BoxShadow(
               color: Color(0x1E000000), // #00000012 is roughly 12% opacity. 0x1E is ~12%. 
               blurRadius: 16,
               offset: Offset(0, -4),
             )
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
             topLeft: Radius.circular(18),
             topRight: Radius.circular(18),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: const Color(0xFF4C5EFF), // Spec: Active
            unselectedItemColor: const Color(0xFF9A9A9D), // Spec: Inactive
            selectedLabelStyle: const TextStyle(
              fontSize: 11, // Spec: 11px
              fontWeight: FontWeight.w500, // Spec: 500
              fontFamily: 'Inter',
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded, size: 24), // Spec: 24px
                label: 'Feed',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.video_library_rounded, size: 24),
                label: 'Creator',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded, size: 24),
                label: 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
