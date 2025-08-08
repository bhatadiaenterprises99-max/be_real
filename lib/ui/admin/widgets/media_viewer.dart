import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

enum MediaType { image, video }

class MediaViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  final MediaType mediaType;

  const MediaViewer({
    Key? key,
    required this.urls,
    required this.initialIndex,
    required this.mediaType,
  }) : super(key: key);

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  late PageController _pageController;
  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;

  // Add a map to track image load status
  final Map<String, bool> _imageLoadAttempts = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    if (widget.mediaType == MediaType.video) {
      _initializeVideo(widget.urls[widget.initialIndex]);
    }
  }

  Future<void> _initializeVideo(String url) async {
    _isVideoInitialized = false;
    if (_videoController != null) {
      await _videoController!.dispose();
    }
    if (_chewieController != null) {
      _chewieController!.dispose();
    }

    _videoController = VideoPlayerController.network(url);

    try {
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.white, size: 42),
                const SizedBox(height: 8),
                Text(
                  'Error: $errorMessage',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        },
      );

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }

  // Add a method to verify image URL before displaying
  Future<bool> _verifyImageUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error verifying image URL: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.mediaType == MediaType.image ? 'Image' : 'Video',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Media viewer
          PageView.builder(
            controller: _pageController,
            itemCount: widget.urls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });

              if (widget.mediaType == MediaType.video) {
                _initializeVideo(widget.urls[index]);
              }
            },
            itemBuilder: (context, index) {
              if (widget.mediaType == MediaType.image) {
                // Image viewer with improved error handling
                return _buildImageViewer(widget.urls[index]);
              } else {
                // Video player
                return Center(
                  child: _isVideoInitialized && _chewieController != null
                      ? Chewie(controller: _chewieController!)
                      : const CircularProgressIndicator(color: Colors.white),
                );
              }
            },
          ),

          // Counter indicator at the bottom
          if (widget.urls.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.urls.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Improved image viewer with better error handling
  Widget _buildImageViewer(String url) {
    // Clean the Firebase URL if needed
    String cleanUrl = url;
    if (url.contains('?')) {
      // Some encoding issues can happen with query parameters
      try {
        final uri = Uri.parse(url);
        cleanUrl = uri.toString();
      } catch (e) {
        print('Error parsing URL: $e');
      }
    }

    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 3.0,
        child: CachedNetworkImage(
          imageUrl: cleanUrl,
          progressIndicatorBuilder: (context, url, progress) => Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              value: progress.progress,
            ),
          ),
          errorWidget: (context, url, error) {
            print('Full screen image load error: $error for $url');

            // Track this URL as having an error
            _imageLoadAttempts[url] = true;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, size: 70, color: Colors.white70),
                const SizedBox(height: 16),
                Text(
                  'Failed to load image',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $error',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Try direct browser open as fallback
                    _launchUrlFallback(url);
                  },
                  child: const Text('Open in Browser'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    // Force a rebuild to try loading again
                    setState(() {
                      _imageLoadAttempts.remove(url);
                    });
                  },
                  child: const Text('Retry Loading'),
                ),
              ],
            );
          },
          fit: BoxFit.contain,
          fadeInDuration: const Duration(milliseconds: 300),
          memCacheHeight: 1024, // Limit cache size to avoid memory issues
          cacheKey: '$cleanUrl-cache-key', // Add a custom cache key
        ),
      ),
    );
  }

  // Method to open URL in browser as fallback
  void _launchUrlFallback(String url) async {
    if (kIsWeb) {
      // On web, open in new tab using JS interop or url_launcher_web
      // You can use url_launcher for both platforms.
      // Example:
      // import 'package:url_launcher/url_launcher.dart';
      // await launchUrl(Uri.parse(url));
      // For now, just show a message if url_launcher is not set up.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Open in browser is not supported in this build.'),
        ),
      );
    } else {
      // For non-web, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open URL directly on this platform')),
      );
    }
  }
}
