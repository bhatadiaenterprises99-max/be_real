import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../controller/site_view_controller.dart'; // Import the controller

class AdminSiteUploadDialog extends StatefulWidget {
  final String siteId;
  final String siteName;
  final Map<String, dynamic> existingData;

  const AdminSiteUploadDialog({
    Key? key,
    required this.siteId,
    required this.siteName,
    required this.existingData,
  }) : super(key: key);

  @override
  State<AdminSiteUploadDialog> createState() => _AdminSiteUploadDialogState();
}

class _AdminSiteUploadDialogState extends State<AdminSiteUploadDialog> {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _noteController = TextEditingController();

  final _isUploading = false.obs;
  final _uploadProgress = 0.0.obs;
  final _selectedImages = <Uint8List>[].obs;
  final _selectedVideos = <Uint8List>[].obs;
  final _selectedImageNames = <String>[].obs;
  final _selectedVideoNames = <String>[].obs;

  // Keep track of existing data
  final _existingImages = <String>[].obs;
  final _existingVideos = <String>[].obs;

  @override
  void initState() {
    super.initState();

    // Initialize with existing note if any
    if (widget.existingData['note'] != null) {
      _noteController.text = widget.existingData['note'] as String;
    }

    // Store existing images and videos
    if (widget.existingData['images'] != null) {
      _existingImages.value = List<String>.from(
        widget.existingData['images'] ?? [],
      );
    }

    if (widget.existingData['videos'] != null) {
      _existingVideos.value = List<String>.from(
        widget.existingData['videos'] ?? [],
      );
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (!kIsWeb) {
      Get.snackbar(
        'Platform Warning',
        'Image picking is optimized for web platform',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (var file in result.files) {
          if (file.bytes != null) {
            _selectedImages.add(file.bytes!);
            _selectedImageNames.add(file.name);
          }
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick images: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _pickVideos() async {
    if (!kIsWeb) {
      Get.snackbar(
        'Platform Warning',
        'Video picking is optimized for web platform',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (var file in result.files) {
          if (file.bytes != null) {
            _selectedVideos.add(file.bytes!);
            _selectedVideoNames.add(file.name);
          }
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick videos: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  void _removeImage(int index) {
    _selectedImages.removeAt(index);
    _selectedImageNames.removeAt(index);
  }

  void _removeVideo(int index) {
    _selectedVideos.removeAt(index);
    _selectedVideoNames.removeAt(index);
  }

  Future<void> _uploadData() async {
    if (_selectedImages.isEmpty &&
        _selectedVideos.isEmpty &&
        _noteController.text.isEmpty) {
      Get.snackbar(
        'Warning',
        'Please add at least one image, video, or note',
        backgroundColor: Colors.amber.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    _isUploading.value = true;
    _uploadProgress.value = 0.0;

    try {
      // Calculate total number of uploads
      final totalUploads = _selectedImages.length + _selectedVideos.length;
      int completedUploads = 0;

      // Prepare lists to hold the URLs
      final List<String> imageUrls = [..._existingImages];
      final List<String> videoUrls = [..._existingVideos];

      // Upload images
      for (int i = 0; i < _selectedImages.length; i++) {
        final imageData = _selectedImages[i];
        final fileName = _selectedImageNames[i];
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = 'sites/${widget.siteId}/images/${timestamp}_$fileName';

        final ref = _storage.ref().child(path);

        // Create upload task
        final uploadTask = ref.putData(
          imageData,
          SettableMetadata(contentType: 'image/${fileName.split('.').last}'),
        );

        // Track progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          double progress = snapshot.bytesTransferred / snapshot.totalBytes;
          // Update overall progress based on this file's progress
          _uploadProgress.value = (completedUploads + progress) / totalUploads;
        });

        // Wait for upload to complete
        await uploadTask;

        // Get download URL
        final downloadUrl = await ref.getDownloadURL();
        imageUrls.add(downloadUrl);

        completedUploads++;
      }

      // Upload videos
      for (int i = 0; i < _selectedVideos.length; i++) {
        final videoData = _selectedVideos[i];
        final fileName = _selectedVideoNames[i];
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = 'sites/${widget.siteId}/videos/${timestamp}_$fileName';

        final ref = _storage.ref().child(path);

        // Create upload task
        final uploadTask = ref.putData(
          videoData,
          SettableMetadata(contentType: 'video/${fileName.split('.').last}'),
        );

        // Track progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          double progress = snapshot.bytesTransferred / snapshot.totalBytes;
          // Update overall progress based on this file's progress
          _uploadProgress.value = (completedUploads + progress) / totalUploads;
        });

        // Wait for upload to complete
        await uploadTask;

        // Get download URL
        final downloadUrl = await ref.getDownloadURL();
        videoUrls.add(downloadUrl);

        completedUploads++;
      }

      // Update Firestore document with the new data
      await _firestore.collection('sites').doc(widget.siteId).update({
        'monitorUploads': {
          'images': imageUrls,
          'videos': videoUrls,
          'note': _noteController.text,
          'latitude': widget.existingData['latitude'],
          'longitude': widget.existingData['longitude'],
          'lastUpdatedBy': 'admin',
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        },
      });

      Get.snackbar(
        'Success',
        'Site data uploaded successfully',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );

      Get.back(); // Close the dialog

      // Refresh site details and show updated dialog
      final controller = Get.find<SiteViewController>();
      await controller.refreshSiteData(widget.siteId);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to upload data: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      _isUploading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload Site Data',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Site: ${widget.siteName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Upload content (scrollable)
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Existing images
                      if (_existingImages.isNotEmpty) ...[
                        const Text(
                          'Existing Images',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _existingImages.length,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.shade200,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _existingImages[index],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // New images
                      Row(
                        children: [
                          const Text(
                            'Images',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(
                              Icons.add_photo_alternate,
                              size: 18,
                            ),
                            label: const Text('Add Images'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => _selectedImages.isEmpty
                            ? Container(
                                height: 100,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: const Center(
                                  child: Text('No images selected'),
                                ),
                              )
                            : SizedBox(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _selectedImages.length,
                                  itemBuilder: (context, index) {
                                    return Stack(
                                      children: [
                                        Container(
                                          width: 100,
                                          height: 100,
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            image: DecorationImage(
                                              image: MemoryImage(
                                                _selectedImages[index],
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 8,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.6,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                              onPressed: () =>
                                                  _removeImage(index),
                                              constraints: const BoxConstraints(
                                                minHeight: 24,
                                                minWidth: 24,
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Existing videos
                      if (_existingVideos.isNotEmpty) ...[
                        const Text(
                          'Existing Videos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _existingVideos.length,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade800,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // New videos
                      Row(
                        children: [
                          const Text(
                            'Videos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _pickVideos,
                            icon: const Icon(Icons.video_library, size: 18),
                            label: const Text('Add Videos'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => _selectedVideos.isEmpty
                            ? Container(
                                height: 100,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: const Center(
                                  child: Text('No videos selected'),
                                ),
                              )
                            : SizedBox(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _selectedVideos.length,
                                  itemBuilder: (context, index) {
                                    return Stack(
                                      children: [
                                        Container(
                                          width: 100,
                                          height: 100,
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade800,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.video_file,
                                                color: Colors.white,
                                                size: 36,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _selectedVideoNames[index]
                                                            .length >
                                                        10
                                                    ? '${_selectedVideoNames[index].substring(0, 10)}...'
                                                    : _selectedVideoNames[index],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 8,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.6,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                              onPressed: () =>
                                                  _removeVideo(index),
                                              constraints: const BoxConstraints(
                                                minHeight: 24,
                                                minWidth: 24,
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Add any notes about the site...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Upload button and progress
              Obx(
                () => _isUploading.value
                    ? Column(
                        children: [
                          LinearProgressIndicator(
                            value: _uploadProgress.value,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Uploading... ${(_uploadProgress.value * 100).toInt()}%',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _uploadData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Upload Data',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
