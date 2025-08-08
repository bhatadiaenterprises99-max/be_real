import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:be_real/ui/controllers/upload_controller.dart';
import 'package:be_real/widgets/common_button.dart';

class UploadMediaScreen extends StatefulWidget {
  final String siteId;
  final String siteName;

  const UploadMediaScreen({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  @override
  State<UploadMediaScreen> createState() => _UploadMediaScreenState();
}

class _UploadMediaScreenState extends State<UploadMediaScreen> {
  late final UploadController uploadController;

  @override
  void initState() {
    super.initState();
    uploadController = Get.put(UploadController(siteId: widget.siteId));
    uploadController.checkAndRequestLocationPermission().then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UploadController>(
      init: UploadController(siteId: widget.siteId),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Upload Media for ${widget.siteName}'),
            backgroundColor: Colors.blue,
            elevation: 0,
          ),
          body: controller.isCheckingLocation.value
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Checking location services...'),
                    ],
                  ),
                )
              : !controller.isLocationEnabled.value
              ? _buildLocationError(controller)
              : _buildUploadForm(context, controller),
          bottomNavigationBar: controller.isLocationEnabled.value
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Obx(
                      () => controller.isUploading.value
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LinearProgressIndicator(
                                  value: controller.uploadProgress.value,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Uploading... ${(controller.uploadProgress.value * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            )
                          : CommonButton(
                              text: 'Upload Data',
                              onPressed: () => controller.uploadData(),
                              isDisabled:
                                  controller.images.isEmpty &&
                                  controller.video.value == null,
                            ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildLocationError(UploadController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Location services are required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'We need to record your current location for this site. Please enable location services to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.checkAndRequestLocationPermission(),
              icon: const Icon(Icons.refresh),
              label: const Text('Enable Location'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadForm(BuildContext context, UploadController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location status
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(
                    () => Text(
                      'Location: ${controller.latitude.value != 0 ? '${controller.latitude.value.toStringAsFixed(6)}, ${controller.longitude.value.toStringAsFixed(6)}' : 'Getting location...'}',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Images section
          const Text(
            'Images (Maximum 3)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please upload clear images of the site',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Image grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (int i = 0; i < 3; i++)
                Obx(() => _buildImageContainer(i, controller)),
            ],
          ),

          const SizedBox(height: 24),

          // Video section
          const Text(
            'Video (Optional)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a short video of the site (up to 30 seconds)',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Video container
          SizedBox(
            height: 150,
            child: Obx(() => _buildVideoContainer(controller)),
          ),

          const SizedBox(height: 24),

          // Notes section
          const Text(
            'Notes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller.noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add notes about the site (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildImageContainer(int index, UploadController controller) {
    final hasImage = controller.images.length > index;

    return GestureDetector(
      onTap: () {
        if (hasImage) {
          // Show option to remove or replace image
          Get.bottomSheet(
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text('Replace Image'),
                    onTap: () {
                      Get.back();
                      controller.pickImage(index);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Remove Image',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Get.back();
                      controller.removeImage(index);
                    },
                  ),
                ],
              ),
            ),
          );
        } else {
          controller.pickImage(index);
        }
      },
      child: hasImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(controller.images[index].path),
                fit: BoxFit.cover,
              ),
            )
          : DottedBorder(
              // borderType: BorderType.RRect,
              // radius: const Radius.circular(12),
              // dashPattern: const [8, 4],
              // color: Colors.grey.shade400,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 36,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add Image',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildVideoContainer(UploadController controller) {
    final hasVideo = controller.video.value != null;

    return GestureDetector(
      onTap: () {
        if (hasVideo) {
          // Show option to remove or replace video
          Get.bottomSheet(
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text('Replace Video'),
                    onTap: () {
                      Get.back();
                      controller.pickVideo();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Remove Video',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Get.back();
                      controller.removeVideo();
                    },
                  ),
                ],
              ),
            ),
          );
        } else {
          controller.pickVideo();
        }
      },
      child: hasVideo
          ? Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withOpacity(0.1),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: controller.videoThumbnail.value != null
                        ? Image.file(
                            File(controller.videoThumbnail.value!),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.black,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                  ),
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.black.withOpacity(0.5),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        controller.videoSize.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : DottedBorder(
              // borderType: BorderType.RRect,
              // radius: const Radius.circular(12),
              // dashPattern: const [8, 4],
              // color: Colors.grey.shade400,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam, size: 36, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'Add Video',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
