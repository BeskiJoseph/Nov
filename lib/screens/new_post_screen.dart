import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../services/firestore_service.dart';

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  String _scope = 'local';
  Uint8List? _mediaBytes;
  String? _mediaExtension;
  String _mediaType = 'image';
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickMedia() async {
    final XFile? file =
        await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      _mediaBytes = bytes;
      _mediaExtension = 'jpg';
      _mediaType = 'image';
    });
  }

  Future<void> _submit() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    if (_titleController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and description are required')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? mediaUrl;

      if (_mediaBytes != null) {
        mediaUrl = await SupabaseService.uploadPostMedia(
          postId: user.uid,
          data: _mediaBytes!,
          fileExtension: _mediaExtension ?? 'jpg',
        );
      }

      await FirestoreService.createPost(
        authorId: user.uid,
        authorName: user.displayName ?? user.email ?? 'Creator',
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        scope: _scope,
        mediaUrl: mediaUrl,
        mediaType: _mediaType,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Content title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Scope:'),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Local'),
                  selected: _scope == 'local',
                  onSelected: (_) {
                    setState(() {
                      _scope = 'local';
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('National'),
                  selected: _scope == 'national',
                  onSelected: (_) {
                    setState(() {
                      _scope = 'national';
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Global'),
                  selected: _scope == 'global',
                  onSelected: (_) {
                    setState(() {
                      _scope = 'global';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _pickMedia,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Add image'),
                  ),
                ),
                const SizedBox(height: 8),
                if (_mediaBytes != null)
                  const Text(
                    'Media selected',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text('Publish'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
