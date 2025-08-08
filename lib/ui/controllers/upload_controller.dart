import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'package:video_compress/video_compress.dart';

class UploadController extends GetxController {
  final String siteId;

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Image picker
  final ImagePicker _picker = ImagePicker();

  // Form controllers
  final noteController = TextEditingController();

  // Observable variables
  final images = <XFile>[].obs;
  final video = Rxn<XFile>();
  final videoThumbnail = Rxn<String>();
  final videoSize = ''.obs;

  final isUploading = false.obs;
  final uploadProgress = 0.0.obs;

  // Location variables
  final isCheckingLocation = true.obs;
  final isLocationEnabled = false.obs;
  final latitude = 0.0.obs;
  final longitude = 0.0.obs;
  Position? currentPosition;

  UploadController({required this.siteId});

  // @override
  // void onInit() {
  //   super.onInit();
  //   checkAndRequestLocationPermission();
  // }

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }

  // Existing location methods (unchanged)
  Future<void> checkAndRequestLocationPermission() async {
    isCheckingLocation.value = true;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      isLocationEnabled.value = false;
      isCheckingLocation.value = false;
      Get.dialog(
        AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text('Please enable location services to continue.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Get.back();
                await Geolocator.openLocationSettings();
                Future.delayed(const Duration(seconds: 3), () {
                  checkAndRequestLocationPermission();
                });
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        isLocationEnabled.value = false;
        isCheckingLocation.value = false;
        Get.dialog(
          AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'Location permission is required to upload site data.',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                  checkAndRequestLocationPermission();
                },
                child: const Text('Request Again'),
              ),
            ],
          ),
          barrierDismissible: false,
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      isLocationEnabled.value = false;
      isCheckingLocation.value = false;
      Get.dialog(
        AlertDialog(
          title: const Text('Permission Permanently Denied'),
          content: const Text(
            'Location permissions are permanently denied. Please enable in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Get.back();
                await openAppSettings();
                Future.delayed(const Duration(seconds: 3), () {
                  checkAndRequestLocationPermission();
                });
              },
              child: const Text('Open App Settings'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
      return;
    }

    try {
      currentPosition =
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Location fetch timed out');
            },
          );
      latitude.value = currentPosition!.latitude;
      longitude.value = currentPosition!.longitude;
      isLocationEnabled.value = true;
    } catch (e) {
      print('Error getting location: $e');
      Get.snackbar(
        'Error',
        'Failed to get current location: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      isLocationEnabled.value = false;
    }

    isCheckingLocation.value = false;
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  // Existing media methods (unchanged)
  Future<void> pickImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        if (index < images.length) {
          images[index] = image;
        } else {
          images.add(image);
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      Get.snackbar(
        'Error',
        'Failed to capture image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void removeImage(int index) {
    if (index < images.length) {
      images.removeAt(index);
    }
  }

  Future<void> pickVideo() async {
    try {
      final XFile? pickedVideo = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 30),
      );

      if (pickedVideo != null) {
        video.value = pickedVideo;
        final File videoFile = File(pickedVideo.path);
        final int fileSizeInBytes = await videoFile.length();
        final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);
        videoSize.value = '${fileSizeInMB.toStringAsFixed(2)} MB';
        generateVideoThumbnail(pickedVideo.path);
      }
    } catch (e) {
      print('Error picking video: $e');
      Get.snackbar(
        'Error',
        'Failed to capture video: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> generateVideoThumbnail(String videoPath) async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        quality: 50,
      );

      if (thumbnailPath != null) {
        videoThumbnail.value = thumbnailPath;
      }
    } catch (e) {
      print('Error generating thumbnail: $e');
    }
  }

  void removeVideo() {
    video.value = null;
    videoThumbnail.value = null;
    videoSize.value = '';
  }

  // Updated uploadData method
  Future<void> uploadData() async {
    if (images.isEmpty && video.value == null) {
      Get.snackbar(
        'Missing Media',
        'Please add at least one image or video',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.amber,
        colorText: Colors.white,
      );
      return;
    }

    if (latitude.value == 0 || longitude.value == 0) {
      Get.snackbar(
        'Location Required',
        'We need your current location. Please ensure location services are enabled.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isUploading.value = true;
    uploadProgress.value = 0;

    try {
      // Calculate total upload size for progress tracking
      final List<File> filesToUpload = [];
      for (XFile image in images) {
        filesToUpload.add(File(image.path));
      }
      if (video.value != null) {
        filesToUpload.add(File(video.value!.path));
      }
      final totalSize = await _calculateTotalSize(filesToUpload);
      double uploadedSize = 0;

      // Upload images
      List<String> imageUrls = [];
      for (XFile image in images) {
        final String timestamp = DateTime.now().millisecondsSinceEpoch
            .toString();
        final String imagePath = 'sites/$siteId/images/img_$timestamp.jpg';
        final Reference ref = _storage.ref().child(imagePath);
        final File imageFile = File(image.path);
        final int fileSize = await imageFile.length();

        final UploadTask uploadTask = ref.putFile(imageFile);
        uploadTask.snapshotEvents.listen(
          (TaskSnapshot snapshot) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            uploadedSize +=
                (snapshot.bytesTransferred -
                    uploadedSize / filesToUpload.length) /
                totalSize;
            uploadProgress.value = uploadedSize.clamp(
              0.0,
              0.95,
            ); // Reserve 5% for Firestore update
          },
          onError: (e) {
            print('Image upload error: $e');
            throw Exception('Failed to upload image: $e');
          },
        );

        final snapshot = await uploadTask.timeout(const Duration(minutes: 5));
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      // Upload video
      List<String> videoUrls = [];
      if (video.value != null) {
        final String timestamp = DateTime.now().millisecondsSinceEpoch
            .toString();
        final String videoPath = 'sites/$siteId/videos/vid_$timestamp.mp4';
        File videoFile = File(video.value!.path);
        final int fileSizeInBytes = await videoFile.length();
        final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        // Compress video if needed
        if (fileSizeInMB > 10) {
          Get.snackbar(
            'Compressing Video',
            'Video size exceeds 10MB. Compressing...',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.blue,
            colorText: Colors.white,
          );
          try {
            final MediaInfo? compressedInfo = await VideoCompress.compressVideo(
              videoFile.path,
              quality: VideoQuality.MediumQuality,
              deleteOrigin: false,
            ).timeout(const Duration(minutes: 5));

            if (compressedInfo?.file != null) {
              videoFile = compressedInfo!.file!;
            } else {
              throw Exception('Video compression failed');
            }
          } catch (e) {
            print('Video compression error: $e');
            throw Exception('Failed to compress video: $e');
          }
        }

        final Reference ref = _storage.ref().child(videoPath);
        final UploadTask uploadTask = ref.putFile(videoFile);
        uploadTask.snapshotEvents.listen(
          (TaskSnapshot snapshot) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            uploadedSize +=
                (snapshot.bytesTransferred -
                    uploadedSize / filesToUpload.length) /
                totalSize;
            uploadProgress.value = uploadedSize.clamp(0.0, 0.95);
          },
          onError: (e) {
            print('Video upload error: $e');
            throw Exception('Failed to upload video: $e');
          },
        );

        final snapshot = await uploadTask.timeout(const Duration(minutes: 10));
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        videoUrls.add(downloadUrl);
      }

      // Update Firestore document
      await _firestore.collection('sites').doc(siteId).update({
        'monitorUploads': {
          'images': imageUrls,
          'videos': videoUrls,
          'note': noteController.text,
          'latitude': latitude.value,
          'longitude': longitude.value,
          'uploadedAt': FieldValue.serverTimestamp(),
        },
        'status': 'reported',
      });

      uploadProgress.value = 1.0;

      Get.snackbar(
        'Success',
        'Site data uploaded successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.back();
    } catch (e) {
      print('Error uploading data: $e');
      Get.snackbar(
        'Error',
        'Failed to upload data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isUploading.value = false;
      uploadProgress.value = 0;
    }
  }

  // Helper method to calculate total size of files to upload
  Future<double> _calculateTotalSize(List<File> files) async {
    double totalSize = 0;
    for (File file in files) {
      totalSize += await file.length();
    }
    return totalSize;
  }
}
