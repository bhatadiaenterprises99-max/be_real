import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:data_table_2/data_table_2.dart';
import '../controller/upload_site_controller.dart';

class UploadSiteScreen extends StatelessWidget {
  const UploadSiteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return GetBuilder<UploadSiteController>(
      init: UploadSiteController(),
      builder: (controller) {
        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                const Text(
                  'Upload Site Data',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Import installation site data from Excel files',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),

                // Main content with responsive layout
                isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildCompanySection(controller),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: _buildFileUploadSection(controller),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildCompanySection(controller),
                          const SizedBox(height: 24),
                          _buildFileUploadSection(controller),
                        ],
                      ),

                const SizedBox(height: 24),

                // Preview section
                _buildDataPreviewSection(controller),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompanySection(UploadSiteController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Company Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 20),

            // Company selection dropdown
            Obx(
              () => DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select Company',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                value: controller.selectedCompanyId.value.isEmpty
                    ? null
                    : controller.selectedCompanyId.value,
                items: [
                  const DropdownMenuItem<String>(
                    value: 'new',
                    child: Text('+ Add New Company'),
                  ),
                  ...controller.companies.map(
                    (company) => DropdownMenuItem<String>(
                      value: company['id'] as String,
                      child: Text(company['name'] as String),
                    ),
                  ),
                ],
                onChanged: controller.onCompanySelected,
                isExpanded: true,
                hint: const Text('Select existing or add new'),
              ),
            ),

            const SizedBox(height: 24),

            // New company form - only visible if "Add New Company" is selected
            Obx(
              () => AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: controller.showNewCompanyForm.value
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'New Company Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Company name field
                          TextFormField(
                            controller: controller.companyNameController,
                            decoration: InputDecoration(
                              labelText: 'Company Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              prefixIcon: const Icon(Icons.business),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Contact person field
                          TextFormField(
                            controller: controller.contactPersonController,
                            decoration: InputDecoration(
                              labelText: 'Contact Person',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              prefixIcon: const Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Contact number field
                          TextFormField(
                            controller: controller.contactNumberController,
                            decoration: InputDecoration(
                              labelText: 'Contact Number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              prefixIcon: const Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadSection(UploadSiteController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Excel File Upload',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Upload an Excel (.xlsx) file with site data. The file should contain columns for Sr No., State, District, City/Town, Media, Location, Type, Units, Facia, W, and H.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // File Upload Section
            Obx(
              () => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    // File name display or upload prompt
                    controller.selectedFileName.isEmpty
                        ? Column(
                            children: [
                              Icon(
                                Icons.upload_file,
                                size: 48,
                                color: Colors.blue.shade300,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Drag & drop an Excel file here or click to browse',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.file_present,
                                    color: Colors.green.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      controller.selectedFileName.value,
                                      style: TextStyle(
                                        color: Colors.green.shade600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: controller.clearSelectedFile,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ),

                    const SizedBox(height: 24),

                    // Upload button
                    ElevatedButton.icon(
                      onPressed: controller.pickExcelFile,
                      icon: const Icon(Icons.file_upload),
                      label: Text(
                        controller.selectedFileName.isEmpty
                            ? 'Choose Excel File'
                            : 'Change File',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Date selection section
            const Text(
              'Campaign Schedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Set start and end dates for all sites in this upload',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Date selection rows
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => ListTile(
                      title: const Text('Start Date'),
                      subtitle: Text(
                        controller.startDate.value != null
                            ? '${controller.startDate.value!.day}/${controller.startDate.value!.month}/${controller.startDate.value!.year}'
                            : 'Select start date',
                      ),
                      leading: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: Get.context!,
                          initialDate:
                              controller.startDate.value ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 30),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          controller.startDate.value = date;
                        }
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Obx(
                    () => ListTile(
                      title: const Text('End Date'),
                      subtitle: Text(
                        controller.endDate.value != null
                            ? '${controller.endDate.value!.day}/${controller.endDate.value!.month}/${controller.endDate.value!.year}'
                            : 'Select end date',
                      ),
                      leading: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: Get.context!,
                          initialDate:
                              controller.endDate.value ??
                              (controller.startDate.value?.add(
                                    const Duration(days: 30),
                                  ) ??
                                  DateTime.now().add(const Duration(days: 30))),
                          firstDate:
                              controller.startDate.value ?? DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 2),
                          ),
                        );
                        if (date != null) {
                          controller.endDate.value = date;
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => ElevatedButton.icon(
                      onPressed: controller.selectedFileName.isEmpty
                          ? null
                          : controller.previewExcelData,
                      icon: controller.isLoadingPreview.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.preview),
                      label: const Text('Preview File'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(
                    () => ElevatedButton.icon(
                      onPressed:
                          (!controller.dataPreviewReady.value ||
                              controller.isUploading.value ||
                              controller.parsedSites.isEmpty)
                          ? null
                          : controller.uploadSites,
                      icon: controller.isUploading.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.cloud_upload),
                      label: const Text('Upload Sites'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataPreviewSection(UploadSiteController controller) {
    return Obx(
      () => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: controller.dataPreviewReady.value
            ? Card(
                key: const ValueKey('preview-card'),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Data Preview',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey,
                            ),
                          ),
                          Text(
                            '${controller.parsedSites.length} sites found',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Data Table
                      SizedBox(
                        height: 400, // Fixed height for the table
                        child: DataTable2(
                          columnSpacing: 12,
                          horizontalMargin: 12,
                          minWidth: 900,
                          smRatio: 0.75,
                          lmRatio: 1.5,
                          columns: const [
                            DataColumn2(
                              label: Text('Sr. No.'),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text('State'),
                              size: ColumnSize.M,
                            ),
                            DataColumn2(
                              label: Text('District'),
                              size: ColumnSize.M,
                            ),
                            DataColumn2(
                              label: Text('City/Town'),
                              size: ColumnSize.M,
                            ),
                            DataColumn2(
                              label: Text('Media'),
                              size: ColumnSize.M,
                            ),
                            DataColumn2(
                              label: Text('Location'),
                              size: ColumnSize.L,
                            ),
                            DataColumn2(
                              label: Text('Type'),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text('Units'),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text('Facia'),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(label: Text('W'), size: ColumnSize.S),
                            DataColumn2(label: Text('H'), size: ColumnSize.S),
                          ],
                          rows: List<DataRow>.generate(
                            controller.parsedSites.length > 100
                                ? 100
                                : controller.parsedSites.length,
                            (index) {
                              final site = controller.parsedSites[index];
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text('${site['srNo'] ?? index + 1}'),
                                  ),
                                  DataCell(Text('${site['state'] ?? ''}')),
                                  DataCell(Text('${site['district'] ?? ''}')),
                                  DataCell(Text('${site['cityTown'] ?? ''}')),
                                  DataCell(Text('${site['media'] ?? ''}')),
                                  DataCell(Text('${site['location'] ?? ''}')),
                                  DataCell(Text('${site['type'] ?? ''}')),
                                  DataCell(Text('${site['units'] ?? ''}')),
                                  DataCell(Text('${site['facia'] ?? ''}')),
                                  DataCell(Text('${site['width'] ?? ''}')),
                                  DataCell(Text('${site['height'] ?? ''}')),
                                ],
                              );
                            },
                          ),
                        ),
                      ),

                      if (controller.parsedSites.length > 100)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            'Showing 100 of ${controller.parsedSites.length} rows',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
