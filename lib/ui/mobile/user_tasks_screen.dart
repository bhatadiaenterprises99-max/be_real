import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserTasksScreen extends StatefulWidget {
  const UserTasksScreen({super.key});

  @override
  State<UserTasksScreen> createState() => _UserTasksScreenState();
}

class _UserTasksScreenState extends State<UserTasksScreen> {
  bool _showDetails = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Modern header with back button and title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Today's Tasks",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Task card
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Media preview
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.photo_camera_outlined,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Media Preview',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Campaign header
                                Text(
                                  'Campaign name',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Surf EW Rs.99 May',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF6C63FF,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Active',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF6C63FF),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Details grid
                                Column(
                                  children: [
                                    _buildDetailItem('City', 'Mahmudabad'),
                                    SizedBox(height: 8),
                                    _buildDetailItem(
                                      'Media type',
                                      'Wallbuffer',
                                    ),
                                    SizedBox(height: 8),
                                    _buildDetailItem('Size', '50x20'),
                                    SizedBox(height: 8),
                                    _buildDetailItem('Illumination', 'FL'),
                                    SizedBox(height: 8),
                                    _buildDetailItem('State', 'Uttar Pradesh'),
                                    SizedBox(height: 8),
                                    _buildLocationItem(),
                                  ],
                                ),
                                // GridView.count(
                                //   crossAxisCount: 2,
                                //   shrinkWrap: true,
                                //   physics: const NeverScrollableScrollPhysics(),
                                //   // childAspectRatio: 5,
                                //   // crossAxisSpacing: 16,
                                //   // mainAxisSpacing: 16,
                                //   children: [
                                //     _buildDetailItem('City', 'Mahmudabad'),
                                //     _buildDetailItem(
                                //       'Media type',
                                //       'Wallbuffer',
                                //     ),
                                //     _buildDetailItem('Size', '50x20'),
                                //     _buildDetailItem('Illumination', 'FL'),
                                //     _buildDetailItem('State', 'Uttar Pradesh'),
                                //     _buildLocationItem(),
                                //   ],
                                // ),
                                const SizedBox(height: 18),

                                // Expandable section
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _showDetails = !_showDetails;
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Text(
                                        _showDetails
                                            ? 'Less details'
                                            : 'More details',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF6C63FF),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Icon(
                                        _showDetails
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                        color: const Color(0xFF6C63FF),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Additional details (conditional)
                                if (_showDetails) ...[
                                  _buildAdditionalDetail(
                                    'Start Date',
                                    '08 May 2025',
                                  ),
                                  _buildAdditionalDetail(
                                    'End Date',
                                    '06 Jun 2025',
                                  ),
                                  _buildAdditionalDetail(
                                    'Task Date',
                                    '30 Jun 2025',
                                  ),
                                  _buildAdditionalDetail(
                                    'Site Id',
                                    'ST10240350',
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                // Action button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6C63FF),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.camera_alt_rounded),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Take Picture',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
        ),
        const SizedBox(width: 2),
        Text(
          ":",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationItem() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location :',
          style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
        ),
        const SizedBox(width: 4),

        Expanded(
          child: Text(
            'Various location',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.location_on_outlined,
            size: 20,
            color: Color(0xFF6C63FF),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalDetail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 15),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
