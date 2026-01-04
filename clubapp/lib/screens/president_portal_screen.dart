import 'package:flutter/material.dart';
import '../services/club_service.dart';

class PresidentPortalScreen extends StatefulWidget {
  static const route = '/president-portal';
  final Map<String, dynamic> clubData;

  const PresidentPortalScreen({super.key, required this.clubData});

  @override
  State<PresidentPortalScreen> createState() => _PresidentPortalScreenState();
}

class _PresidentPortalScreenState extends State<PresidentPortalScreen> {
  final ClubService _clubService = ClubService();
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _bannerUrlController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bannerUrlController.text = widget.clubData['bannerUrl'] ?? '';
    _keywordController.text = (widget.clubData['keywords'] as List? ?? []).join(', ');
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _bannerUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveBannerUrl() async {
    setState(() => _isSaving = true);
    try {
      await _clubService.updateClubBannerUrl(
        widget.clubData['id'],
        _bannerUrlController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner URL updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update URL: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveKeywords() async {
    final keywords = _keywordController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    await _clubService.updateClubKeywords(widget.clubData['id'], keywords);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keywords updated!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('President Portal')),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _clubService.getClubStream(widget.clubData['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final club = snapshot.data ?? widget.clubData;
          final bannerUrl = club['bannerUrl'];
          final keywordsInDb = List<String>.from(club['keywords'] ?? []);

          // Sync controllers only when not focused
          if (!FocusScope.of(context).hasFocus) {
            final newKeywordsText = keywordsInDb.join(', ');
            if (_keywordController.text != newKeywordsText) {
              _keywordController.text = newKeywordsText;
            }
            if (_bannerUrlController.text != (bannerUrl ?? '')) {
              _bannerUrlController.text = bannerUrl ?? '';
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  club['name'] ?? 'Club Management',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your club visual identity (100% Free)',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Banner Preview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 180,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: bannerUrl != null && bannerUrl.isNotEmpty
                      ? Image.network(
                          bannerUrl,
                          fit: BoxFit.cover,
                          key: ValueKey(bannerUrl),
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, color: Colors.grey),
                                  Text('Invalid Image URL',
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Banner Image Link',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Paste a link to any image (Pinterest, Google, etc.)',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bannerUrlController,
                  decoration: InputDecoration(
                    hintText: 'https://example.com/banner.jpg',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _isSaving
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.save, color: Colors.deepPurple),
                            onPressed: _saveBannerUrl,
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Search Keywords',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Events with these words in their title will show your banner (e.g. GFG, GeeksforGeeks).',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _keywordController,
                  decoration: InputDecoration(
                    hintText: 'Separate by commas',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.save, color: Colors.deepPurple),
                      onPressed: _saveKeywords,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Note: This method is 100% free and does not require a paid Firebase plan.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
