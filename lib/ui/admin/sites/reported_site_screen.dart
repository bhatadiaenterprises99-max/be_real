import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/site_view_controller.dart';
import '../widgets/site_table.dart';

class ReportedSiteScreen extends StatelessWidget {
  const ReportedSiteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return GetBuilder<SiteViewController>(
      init: SiteViewController(),
      builder: (controller) {
        // Initialize with onlyActive=true for this screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.sites.isEmpty) {
            controller.fetchSites(onlyActive: true);
          }
        });

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Text(
                  'Active Sites',
                  style: TextStyle(
                    fontSize: isWide ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'View and manage active installation sites',
                  style: TextStyle(
                    fontSize: isWide ? 16 : 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // Filter section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Filter options in row or column based on screen width
                        isWide
                            ? Row(
                                children: [
                                  // Company dropdown
                                  Expanded(
                                    child: _buildCompanyDropdown(controller),
                                  ),
                                  const SizedBox(width: 16),
                                  // Search field
                                  Expanded(
                                    child: _buildSearchField(controller),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildCompanyDropdown(controller),
                                  const SizedBox(height: 16),
                                  _buildSearchField(controller),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Active sites info banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Showing sites with status: Pending or Ongoing',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Sites table/list
                Expanded(
                  child: Obx(() {
                    // Show loading state
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final sites = controller.filteredSites;

                    // Show empty state
                    if (sites.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No active sites found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'All sites for this company are completed or expired',
                              style: TextStyle(color: Colors.grey.shade500),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    // Show sites table
                    return SiteTable(
                      sites: sites,
                      getCompanyName: controller.getCompanyName,
                      getStatusColor: controller.getStatusColor,
                      onViewSiteDetails: (siteId) {
                        controller.viewSiteDetails(siteId);
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompanyDropdown(SiteViewController controller) {
    return Obx(() {
      if (controller.companies.isEmpty) {
        return const SizedBox(
          height: 56,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Select Company',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          prefixIcon: const Icon(Icons.business),
        ),
        value: controller.selectedCompanyId.value.isEmpty
            ? null
            : controller.selectedCompanyId.value,
        items: controller.companies.map((company) {
          return DropdownMenuItem<String>(
            value: company['id'],
            child: Text(company['name']),
          );
        }).toList(),
        onChanged: (value) {
          controller.setSelectedCompany(value ?? '', onlyActive: true);
        },
        hint: const Text('Select a company'),
        isExpanded: true,
      );
    });
  }

  Widget _buildSearchField(SiteViewController controller) {
    return TextField(
      controller: controller.searchController,
      decoration: InputDecoration(
        labelText: 'Search sites',
        hintText: 'Enter location, state, district...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Obx(() {
          return controller.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.searchController.clear();
                    controller.updateSearch('');
                  },
                )
              : const SizedBox.shrink();
        }),
      ),
      onChanged: controller.updateSearch,
    );
  }
}
