import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

enum MediaType { image, video }

class MediaViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  final MediaType mediaType;
  final double? latitude;
  final double? longitude;

  const MediaViewer({
    Key? key,
    required this.urls,
    required this.initialIndex,
    required this.mediaType,
    this.latitude,
    this.longitude,
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

  // Fixed: Save image with watermark
  Future<void> _saveImageWithWatermark(String url) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processing image, please wait...')),
      );

      // Download image bytes
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception('Failed to load image');
      Uint8List bytes = response.bodyBytes;

      // Decode image
      img.Image? original = img.decodeImage(bytes);
      if (original == null) throw Exception('Could not decode image');

      // Create watermark text
      String watermark = '';
      if (widget.latitude != null && widget.longitude != null) {
        watermark =
            'Lat: ${widget.latitude!.toStringAsFixed(6)}, Lng: ${widget.longitude!.toStringAsFixed(6)}';
      } else {
        watermark =
            'No Location Data | ${DateTime.now().toString().split('.')[0]}';
      }

      // Calculate strip height - 10% of image height but at least 40px
      int stripHeight = (original.height * 0.10).toInt();
      stripHeight = stripHeight < 40 ? 40 : stripHeight;

      // Add blue strip at bottom
      img.fillRect(
        original,
        x1: 0,
        y1: original.height - stripHeight,
        x2: original.width,
        y2: original.height,
        color: img.ColorRgb8(33, 150, 243), // Blue color
      );

      // Calculate font size based on image size
      int fontSize = (original.width / 40).round().clamp(12, 28);
      // Use a BitmapFont .fnt file (make sure you have a .fnt and corresponding .png in assets)
      final fontPath = 'assets/fonts/arial.fnt';

      // Draw text (white)
      img.drawString(
        original,
        watermark,
        font: img.arial24,
        x: 20,
        y: original.height - stripHeight + (stripHeight ~/ 3),
        color: img.ColorRgb8(255, 255, 255), // White
      );

      // Encode back to jpg
      final watermarkedBytes = img.encodeJpg(original, quality: 90);

      // Save to gallery
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/watermarked_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);
      await file.writeAsBytes(watermarkedBytes);

      await GallerySaver.saveImage(file.path, albumName: 'BeReal Sites');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image saved to gallery with watermark!'),
          ),
        );
      }
    } catch (e) {
      print('Error saving image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save image: $e')));
      }
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
        actions: [
          if (widget.mediaType == MediaType.image)
            IconButton(
              icon: const Icon(Icons.save_alt, color: Colors.white),
              tooltip: 'Save to Gallery with Watermark',
              onPressed: () {
                final url = widget.urls[_currentIndex];
                _saveImageWithWatermark(url);
              },
            ),
        ],
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
                // Image viewer
                return Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Image.network(
                      widget.urls[index],
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.broken_image,
                              size: 70,
                              color: Colors.white70,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        );
                      },
                      fit: BoxFit.contain,
                    ),
                  ),
                );
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

          // Counter indicator
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
}
