import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/admin_site_upload_dialog.dart';
import '../widgets/media_viewer.dart'; // We'll create this file next

class SiteDetailDialog extends StatefulWidget {
  final Map<String, dynamic> site;
  final String companyName;
  final Color statusColor;

  const SiteDetailDialog({
    super.key,
    required this.site,
    required this.companyName,
    required this.statusColor,
  });

  @override
  State<SiteDetailDialog> createState() => _SiteDetailDialogState();
}

class _SiteDetailDialogState extends State<SiteDetailDialog> {
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    final monitorUploads =
        widget.site['monitorUploads'] as Map<String, dynamic>? ?? {};
    final images = List<String>.from(monitorUploads['images'] ?? []);
    final videos = List<String>.from(monitorUploads['videos'] ?? []);
    final note = monitorUploads['note'] as String? ?? '';
    final latitude = monitorUploads['latitude'];
    final longitude = monitorUploads['longitude'];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isWide ? 800 : 500,
          maxHeight: 600,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${widget.site['location'] ?? 'Site Details'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Add upload button here
                TextButton.icon(
                  onPressed: () {
                    Get.back(); // Close current dialog
                    // Show upload dialog
                    Get.dialog(
                      AdminSiteUploadDialog(
                        siteId: widget.site['id'],
                        siteName: widget.site['location'] ?? 'Unknown Site',
                        existingData: monitorUploads,
                      ),
                      barrierDismissible: false,
                    );
                  },
                  icon: const Icon(Icons.cloud_upload, color: Colors.blue),
                  label: const Text(
                    'Upload Data',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 4),

            Text(
              widget.companyName,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),

            const SizedBox(height: 16),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.statusColor.withOpacity(0.5)),
              ),
              child: Text(
                widget.site['status'] ?? 'pending',
                style: TextStyle(
                  color: widget.statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Site details scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic info section
                    _buildSectionHeader('Site Information'),
                    const SizedBox(height: 16),

                    // Location details
                    _buildInfoGrid(context, [
                      {'label': 'State', 'value': widget.site['state'] ?? '-'},
                      {
                        'label': 'District',
                        'value': widget.site['district'] ?? '-',
                      },
                      {
                        'label': 'City/Town',
                        'value': widget.site['cityTown'] ?? '-',
                      },
                      {
                        'label': 'Location',
                        'value': widget.site['location'] ?? '-',
                      },
                    ]),

                    const SizedBox(height: 20),

                    // Media details
                    _buildInfoGrid(context, [
                      {'label': 'Type', 'value': widget.site['type'] ?? '-'},
                      {'label': 'Media', 'value': widget.site['media'] ?? '-'},
                      {
                        'label': 'Units',
                        'value': widget.site['units']?.toString() ?? '-',
                      },
                      {'label': 'Facia', 'value': widget.site['facia'] ?? '-'},
                      {
                        'label': 'Dimensions',
                        'value':
                            '${widget.site['width'] ?? '-'} x ${widget.site['height'] ?? '-'}',
                      },
                    ]),

                    const SizedBox(height: 24),

                    // Monitor uploads section
                    _buildSectionHeader('Monitor Uploads'),
                    const SizedBox(height: 16),

                    // Images
                    if (images.isNotEmpty) ...[
                      const Text(
                        'Images',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                // Show full-screen image viewer
                                Get.dialog(
                                  MediaViewer(
                                    urls: images,
                                    initialIndex: index,
                                    mediaType: MediaType.image,
                                  ),
                                  useSafeArea: false,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: images[index],
                                    height: 120,
                                    width: 160,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      height: 120,
                                      width: 160,
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) {
                                      // Log error for debugging
                                      print(
                                        'Image load error: $error for $url',
                                      );
                                      return Container(
                                        height: 120,
                                        width: 160,
                                        color: Colors.grey.shade200,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.broken_image,
                                                  size: 40,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Image error',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Positioned(
                                              bottom: 4,
                                              right: 4,
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.refresh,
                                                  size: 20,
                                                ),
                                                onPressed: () {
                                                  // Clear cache and force reload
                                                  CachedNetworkImage.evictFromCache(
                                                    url,
                                                  );
                                                  setState(() {});
                                                },
                                                color: Colors.blue,
                                                tooltip: 'Reload image',
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    // Add key to force refresh when needed
                                    key: ValueKey(
                                      '${images[index]}-${DateTime.now().millisecondsSinceEpoch}',
                                    ),
                                    // Improve caching
                                    memCacheHeight: 240,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Videos
                    if (videos.isNotEmpty) ...[
                      const Text(
                        'Videos',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: videos.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                // Show full-screen video player
                                Get.dialog(
                                  MediaViewer(
                                    urls: videos,
                                    initialIndex: index,
                                    mediaType: MediaType.video,
                                  ),
                                  useSafeArea: false,
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 160,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade800,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Try to show a thumbnail if available
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        color: Colors.black,
                                        height: 120,
                                        width: 160,
                                      ),
                                    ),
                                    // Play button
                                    const Icon(
                                      Icons.play_circle_fill,
                                      size: 50,
                                      color: Colors.white70,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Note
                    if (note.isNotEmpty) ...[
                      const Text(
                        'Note',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(note),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // GPS Coordinates
                    if (latitude != null && longitude != null) ...[
                      const Text(
                        'GPS Coordinates',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              'Latitude',
                              latitude.toString(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoItem(
                              'Longitude',
                              longitude.toString(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Created date and other metadata
                    if (widget.site['createdAt'] != null) ...[
                      Text(
                        'Created: ${DateFormat('MMM d, yyyy').format(widget.site['createdAt'])}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Divider(color: Colors.grey.shade300),
      ],
    );
  }

  Widget _buildInfoGrid(BuildContext context, List<Map<String, String>> items) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: items.map((item) {
        return SizedBox(
          width: isWide ? 220 : 140,
          child: _buildInfoItem(item['label']!, item['value']!),
        );
      }).toList(),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}


// rules_version = '2';

// // Craft rules based on data in your Firestore database
// // allow write: if firestore.get(
// //    /databases/(default)/documents/users/$(request.auth.uid)).data.isAdmin;
// service firebase.storage {
//   match /b/{bucket}/o {

//     // This rule allows anyone with your Storage bucket reference to view, edit,
//     // and delete all data in your Storage bucket. It is useful for getting
//     // started, but it is configured to expire after 30 days because it
//     // leaves your app open to attackers. At that time, all client
//     // requests to your Storage bucket will be denied.
//     //
//     // Make sure to write security rules for your app before that time, or else
//     // all client requests to your Storage bucket will be denied until you Update
//     // your rules
//     match /{allPaths=**} {
//       allow read, write: if request.time < timestamp.date(2025, 8, 25);
//     }
//   }
// }