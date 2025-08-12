import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';

import 'package:image/image.dart' as img;

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
  final watermarkedImagePaths =
      <String, String>{}.obs; // Store watermarked image paths
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
        // Process the image with watermark
        final watermarkedImage = await _processImageWithWatermark(image.path);

        if (watermarkedImage != null) {
          // Save original image for upload to Firebase
          if (index < images.length) {
            images[index] = image;
          } else {
            images.add(image);
          }

          // Store watermarked image path for later use
          watermarkedImagePaths[image.path] = watermarkedImage.path;

          // Save watermarked copy to gallery
          await GallerySaver.saveImage(
            watermarkedImage.path,
            albumName: 'BeReal Sites',
          );
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

  // New method to get watermarked image path
  Future<String?> getWatermarkedImagePath(String originalPath) async {
    // If we already have watermarked version, return it
    if (watermarkedImagePaths.containsKey(originalPath)) {
      return watermarkedImagePaths[originalPath];
    }

    // If not found, check if we need to generate one (this should not happen normally,
    // as we already generate it in pickImage, but just in case)
    final watermarkedImage = await _processImageWithWatermark(originalPath);
    if (watermarkedImage != null) {
      watermarkedImagePaths[originalPath] = watermarkedImage.path;
      return watermarkedImage.path;
    }

    return null;
  }

  // New method to process image with watermark
  Future<File?> _processImageWithWatermark(String imagePath) async {
    try {
      final File originalFile = File(imagePath);
      final Uint8List bytes = await originalFile.readAsBytes();

      final img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) throw Exception('Could not decode image');

      // Reduce strip height to 10% (min 50px instead of 60px)
      int stripHeight = (originalImage.height * 0.10).toInt();
      stripHeight = stripHeight < 50 ? 50 : stripHeight;

      // Blue strip at bottom
      img.fillRect(
        originalImage,
        x1: 0,
        y1: originalImage.height - stripHeight,
        x2: originalImage.width,
        y2: originalImage.height,
        color: img.ColorRgb8(33, 150, 243),
      );

      final now = DateTime.now();
      final String formattedDate = _formatDateTime(now);

      final String coordsText = latitude.value != 0 && longitude.value != 0
          ? 'Lat: ${latitude.value.toStringAsFixed(6)}, Lng: ${longitude.value.toStringAsFixed(6)}'
          : 'Location data not available';

      final String locationName = "Site ID: $siteId";

      // Larger font for better visibility
      final font = img.arial48; // Bigger font size

      // Adjust y positions to fit inside the smaller strip
      img.drawString(
        originalImage,
        formattedDate,
        font: font,
        x: 15,
        y: originalImage.height - stripHeight + 8,
        color: img.ColorRgb8(255, 255, 255),
      );

      img.drawString(
        originalImage,
        coordsText,
        font: font,
        x: 15,
        y: originalImage.height - stripHeight + 48,
        color: img.ColorRgb8(255, 255, 255),
      );

      img.drawString(
        originalImage,
        locationName,
        font: font,
        x: 15,
        y: originalImage.height - stripHeight + 88,
        color: img.ColorRgb8(255, 255, 255),
      );

      final watermarkedBytes = img.encodeJpg(originalImage, quality: 90);
      final tempDir = await getTemporaryDirectory();
      final watermarkedPath =
          '${tempDir.path}/watermarked_${now.millisecondsSinceEpoch}.jpg';
      final watermarkedFile = File(watermarkedPath);
      await watermarkedFile.writeAsBytes(watermarkedBytes);

      return watermarkedFile;
    } catch (e) {
      print('Error processing image with watermark: $e');
      return null;
    }
  }

  // Format date time as requested: "August 10, 2023 07:45 PM"
  String _formatDateTime(DateTime dateTime) {
    // Month names
    final List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    // Get components
    final int day = dateTime.day;
    final String month = months[dateTime.month - 1];
    final int year = dateTime.year;

    // Format hour for 12-hour clock with AM/PM
    int hour = dateTime.hour;
    final String amPm = hour >= 12 ? 'PM' : 'AM';
    hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    // Format minute with leading zero if needed
    final String minute = dateTime.minute.toString().padLeft(2, '0');

    return '$month $day, $year $hour:$minute $amPm';
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

  // Updated uploadData method to use watermarked images
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
      // Use watermarked images instead of originals
      for (XFile image in images) {
        String? watermarkedPath = await getWatermarkedImagePath(image.path);
        if (watermarkedPath != null) {
          filesToUpload.add(File(watermarkedPath));
        } else {
          // Fallback to original if watermarked version not available
          filesToUpload.add(File(image.path));
        }
      }

      if (video.value != null) {
        filesToUpload.add(File(video.value!.path));
      }

      final totalSize = await _calculateTotalSize(filesToUpload);
      double uploadedSize = 0;

      // Upload watermarked images
      List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        final XFile image = images[i];
        final String timestamp = DateTime.now().millisecondsSinceEpoch
            .toString();
        final String imagePath = 'sites/$siteId/images/img_$timestamp.jpg';
        final Reference ref = _storage.ref().child(imagePath);

        // Get watermarked image path
        String? watermarkedPath = await getWatermarkedImagePath(image.path);

        // Use watermarked image if available, otherwise use original
        final File imageFile = watermarkedPath != null
            ? File(watermarkedPath)
            : File(image.path);

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
        'status': 'completed',
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
