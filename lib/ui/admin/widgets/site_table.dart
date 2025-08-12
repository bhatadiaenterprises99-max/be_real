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
  final VoidCallback? onRefresh;

  const SiteTable({
    super.key,
    required this.sites,
    required this.getCompanyName,
    required this.getStatusColor,
    required this.onViewSiteDetails,
    this.getMonitorName,
    this.onAssignMonitor,
    this.monitors,
    this.onRefresh,
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
        // New order: site ID, media, state, city, location, start date, end date, company name, status, monitor, actions
        const DataColumn2(label: Text('Site ID'), size: ColumnSize.S),
        const DataColumn2(label: Text('Media'), size: ColumnSize.M),
        const DataColumn2(label: Text('State'), size: ColumnSize.M),
        const DataColumn2(label: Text('City/Town'), size: ColumnSize.M),
        const DataColumn2(label: Text('Location'), size: ColumnSize.L),
        const DataColumn2(label: Text('Start Date'), size: ColumnSize.M),
        const DataColumn2(label: Text('End Date'), size: ColumnSize.M),
        const DataColumn2(label: Text('Company'), size: ColumnSize.M),
        // const DataColumn2(label: Text('Type'), size: ColumnSize.S),
        const DataColumn2(label: Text('Units'), size: ColumnSize.S),
        const DataColumn2(label: Text('Dimensions'), size: ColumnSize.S),
        const DataColumn2(label: Text('Status'), size: ColumnSize.S),
        // Add Monitor column if monitor functions are provided
        if (getMonitorName != null)
          const DataColumn2(label: Text('Monitor'), size: ColumnSize.M),
        const DataColumn2(label: Text('Actions'), size: ColumnSize.S),
      ],
      rows: sites.map((site) {
        final startDate = site['startDate'] != null
            ? _formatDate(site['startDate'])
            : 'Not set';
        final endDate = site['endDate'] != null
            ? _formatDate(site['endDate'])
            : 'Not set';

        return DataRow(
          cells: [
            // New order of cells to match column order
            DataCell(Text(site['id']?.toString().substring(0, 6) ?? 'N/A')),
            DataCell(Text(site['media'] ?? '')),
            DataCell(Text(site['state'] ?? '')),
            DataCell(Text(site['cityTown'] ?? '')),
            DataCell(Text(site['location'] ?? '')),
            DataCell(Text(startDate)),
            DataCell(Text(endDate)),
            DataCell(Text(getCompanyName(site['companyId'] ?? ''))),
            // DataCell(Text(site['type'] ?? '')),
            DataCell(Text(site['units']?.toString() ?? '')),
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
              IconButton(
                onPressed: () => onViewSiteDetails(site['id']),
                icon: const Icon(Icons.visibility, size: 18),
                tooltip: 'View Details',
                color: Colors.blue,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not set';

    try {
      if (date is DateTime) {
        return DateFormat('MMM d, yyyy').format(date);
      } else if (date.runtimeType.toString().contains('Timestamp')) {
        final timestamp = date.toDate();
        return DateFormat('MMM d, yyyy').format(timestamp);
      } else {
        return 'Invalid date';
      }
    } catch (e) {
      return 'Invalid date';
    }
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
                  onRefresh: onRefresh,
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

        final startDate = site['startDate'] != null
            ? _formatDate(site['startDate'])
            : 'Not set';
        final endDate = site['endDate'] != null
            ? _formatDate(site['endDate'])
            : 'Not set';

        return ExpansionTile(
          title: Row(
            children: [
              // Show site ID and media in title
              Text(
                '#${site['id']?.toString().substring(0, 6) ?? 'N/A'} - ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site['location'] ?? 'Unknown Location',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        Text(
                          '${site['media'] ?? 'Unknown'} | ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${site['cityTown'] ?? ''}, ${site['state'] ?? ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Company: ${getCompanyName(site['companyId'] ?? '')}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'Period: $startDate - $endDate',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInfoRow('Site ID', site['id']?.toString() ?? 'N/A'),
                  _buildInfoRow('Media', site['media'] ?? ''),
                  _buildInfoRow('State', site['state'] ?? ''),
                  _buildInfoRow('City/Town', site['cityTown'] ?? ''),
                  _buildInfoRow('Location', site['location'] ?? ''),
                  _buildInfoRow('Start Date', startDate),
                  _buildInfoRow('End Date', endDate),
                  _buildInfoRow(
                    'Company',
                    getCompanyName(site['companyId'] ?? ''),
                  ),
                  _buildInfoRow('Type', site['type'] ?? ''),
                  _buildInfoRow('Units', site['units']?.toString() ?? ''),
                  _buildInfoRow(
                    'Dimensions',
                    '${site['width'] ?? ''} x ${site['height'] ?? ''}',
                  ),

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
                                onRefresh: onRefresh,
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
          const SizedBox(
            width: 100,
            child: Text(
              'Monitor:',
              style: TextStyle(fontWeight: FontWeight.w500),
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
