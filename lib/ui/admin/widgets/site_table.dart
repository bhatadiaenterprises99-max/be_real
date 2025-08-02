import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import '../widgets/site_detail_dialog.dart';
import '../widgets/monitor_assignment_dialog.dart';
import 'package:get/get.dart';

class SiteTable extends StatelessWidget {
  final List<Map<String, dynamic>> sites;
  final String Function(String) getCompanyName;
  final Color Function(String) getStatusColor;
  final Function(String) onViewSiteDetails;
  final String Function(String)? getMonitorName;
  final Function(String, String)? onAssignMonitor;
  final List<Map<String, dynamic>>? monitors;
  final VoidCallback? onRefresh; // Add refresh callback

  const SiteTable({
    super.key,
    required this.sites,
    required this.getCompanyName,
    required this.getStatusColor,
    required this.onViewSiteDetails,
    this.getMonitorName,
    this.onAssignMonitor,
    this.monitors,
    this.onRefresh, // Add this parameter
  });

  @override
  Widget build(BuildContext context) {
    // Check if we're on a narrow screen
    final isNarrow = MediaQuery.of(context).size.width < 900;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table header with counts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sites (${sites.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade700,
                  ),
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(DateTime.now()),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // Sites table
            Expanded(
              child: isNarrow
                  ? _buildListView() // Use list view on narrow screens
                  : _buildDataTable(), // Use data table on wider screens
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 12,
      minWidth: 900,
      columns: [
        const DataColumn2(label: Text('State'), size: ColumnSize.M),
        const DataColumn2(label: Text('District'), size: ColumnSize.M),
        const DataColumn2(label: Text('City/Town'), size: ColumnSize.M),
        const DataColumn2(label: Text('Location'), size: ColumnSize.L),
        const DataColumn2(label: Text('Type'), size: ColumnSize.S),
        const DataColumn2(label: Text('Media'), size: ColumnSize.M),
        const DataColumn2(label: Text('Units'), size: ColumnSize.S),
        const DataColumn2(label: Text('Facia'), size: ColumnSize.S),
        const DataColumn2(label: Text('W x H'), size: ColumnSize.S),
        const DataColumn2(label: Text('Status'), size: ColumnSize.S),
        // Add Monitor column if monitor functions are provided
        if (getMonitorName != null)
          const DataColumn2(label: Text('Monitor'), size: ColumnSize.M),
        const DataColumn2(label: Text('Actions'), size: ColumnSize.M),
      ],
      rows: sites.map((site) {
        return DataRow(
          cells: [
            DataCell(Text(site['state'] ?? '')),
            DataCell(Text(site['district'] ?? '')),
            DataCell(Text(site['cityTown'] ?? '')),
            DataCell(Text(site['location'] ?? '')),
            DataCell(Text(site['type'] ?? '')),
            DataCell(Text(site['media'] ?? '')),
            DataCell(Text(site['units']?.toString() ?? '')),
            DataCell(Text(site['facia'] ?? '')),
            DataCell(Text('${site['width'] ?? ''} x ${site['height'] ?? ''}')),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: getStatusColor(site['status']).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  site['status'] ?? 'pending',
                  style: TextStyle(
                    color: getStatusColor(site['status']),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // Add Monitor cell if monitor functions are provided
            if (getMonitorName != null) DataCell(_buildMonitorAssignment(site)),
            DataCell(
              TextButton.icon(
                onPressed: () => onViewSiteDetails(site['id']),
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('View Details'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMonitorAssignment(Map<String, dynamic> site) {
    final monitorId = site['monitorId'];
    final hasMonitor = monitorId != null && monitorId.toString().isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasMonitor)
          Flexible(
            child: Text(
              getMonitorName!(monitorId),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            hasMonitor ? Icons.edit : Icons.person_add,
            color: hasMonitor ? Colors.orange : Colors.blue,
            size: 20,
          ),
          tooltip: hasMonitor ? 'Change Monitor' : 'Assign Monitor',
          onPressed: () {
            if (onAssignMonitor != null) {
              // Show monitor assignment dialog
              Get.dialog(
                MonitorAssignmentDialog(
                  siteId: site['id'],
                  currentMonitorId: monitorId,
                  onAssign: (selectedMonitorId) {
                    onAssignMonitor!(site['id'], selectedMonitorId);
                  },
                  onRefresh: onRefresh, // Pass the refresh callback
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildListView() {
    return ListView.separated(
      itemCount: sites.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final site = sites[index];
        return ExpansionTile(
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site['location'] ?? 'Unknown Location',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${site['district'] ?? ''}, ${site['state'] ?? ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: getStatusColor(site['status']).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  site['status'] ?? 'pending',
                  style: TextStyle(
                    color: getStatusColor(site['status']),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            'Company: ${getCompanyName(site['companyId'] ?? '')}',
            style: const TextStyle(fontSize: 12),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInfoRow('Type', site['type'] ?? ''),
                  _buildInfoRow('Media', site['media'] ?? ''),
                  _buildInfoRow('Units', site['units']?.toString() ?? ''),
                  _buildInfoRow('Facia', site['facia'] ?? ''),
                  _buildInfoRow(
                    'Dimensions',
                    '${site['width'] ?? ''} x ${site['height'] ?? ''}',
                  ),
                  _buildInfoRow('City/Town', site['cityTown'] ?? ''),

                  // Add monitor information if available
                  if (getMonitorName != null) _buildMonitorInfoRow(site),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => onViewSiteDetails(site['id']),
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('View Full Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),

                      // Add assign monitor button if monitor functions are provided
                      if (onAssignMonitor != null)
                        ElevatedButton.icon(
                          onPressed: () {
                            Get.dialog(
                              MonitorAssignmentDialog(
                                siteId: site['id'],
                                currentMonitorId: site['monitorId'],
                                onAssign: (selectedMonitorId) {
                                  onAssignMonitor!(
                                    site['id'],
                                    selectedMonitorId,
                                  );
                                },
                                onRefresh:
                                    onRefresh, // Pass the refresh callback
                              ),
                            );
                          },
                          icon: Icon(
                            site['monitorId'] != null
                                ? Icons.edit
                                : Icons.person_add,
                            size: 18,
                          ),
                          label: Text(
                            site['monitorId'] != null
                                ? 'Change Monitor'
                                : 'Assign Monitor',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: site['monitorId'] != null
                                ? Colors.orange
                                : Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildMonitorInfoRow(Map<String, dynamic> site) {
    final monitorId = site['monitorId'];
    final hasMonitor = monitorId != null && monitorId.toString().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              'Monitor:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: hasMonitor
                ? Text(getMonitorName!(monitorId))
                : const Text(
                    'Not assigned',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
