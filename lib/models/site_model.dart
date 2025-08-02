import 'package:cloud_firestore/cloud_firestore.dart';

enum SiteStatus { pending, ongoing, completed }

class SiteModel {
  final String? id;
  final String companyName;
  final String clientName;
  final String productName;
  final String estimate;
  final String city;
  final String location;
  final String supplier;
  final String campaign;
  final String process;
  final SiteStatus status;
  final DateTime createdAt;
  final bool isReported;

  SiteModel({
    this.id,
    required this.companyName,
    required this.clientName,
    required this.productName,
    required this.estimate,
    required this.city,
    required this.location,
    required this.supplier,
    required this.campaign,
    required this.process,
    this.status = SiteStatus.pending,
    DateTime? createdAt,
    this.isReported = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'clientName': clientName,
      'productName': productName,
      'estimate': estimate,
      'city': city,
      'location': location,
      'supplier': supplier,
      'campaign': campaign,
      'process': process,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'isReported': isReported,
    };
  }

  factory SiteModel.fromMap(Map<String, dynamic> map, String id) {
    return SiteModel(
      id: id,
      companyName: map['companyName'] ?? '',
      clientName: map['clientName'] ?? '',
      productName: map['productName'] ?? '',
      estimate: map['estimate'] ?? '',
      city: map['city'] ?? '',
      location: map['location'] ?? '',
      supplier: map['supplier'] ?? '',
      campaign: map['campaign'] ?? '',
      process: map['process'] ?? '',
      status: SiteStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => SiteStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isReported: map['isReported'] ?? false,
    );
  }

  SiteModel copyWith({
    String? id,
    String? companyName,
    String? clientName,
    String? productName,
    String? estimate,
    String? city,
    String? location,
    String? supplier,
    String? campaign,
    String? process,
    SiteStatus? status,
    DateTime? createdAt,
    bool? isReported,
  }) {
    return SiteModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      clientName: clientName ?? this.clientName,
      productName: productName ?? this.productName,
      estimate: estimate ?? this.estimate,
      city: city ?? this.city,
      location: location ?? this.location,
      supplier: supplier ?? this.supplier,
      campaign: campaign ?? this.campaign,
      process: process ?? this.process,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isReported: isReported ?? this.isReported,
    );
  }
}
