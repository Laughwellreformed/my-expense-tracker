class Organization {
  final String id;
  final String name;
  final String? description;
  final String? contactEmail;
  final String? contactPhone;
  final DateTime createdAt;
  final double totalRefundsDue;
  final double totalRefunded;
  final List<String> refundExpenseIds;
  final List<String> refundedExpenseIds;

  Organization({
    required this.id,
    required this.name,
    this.description,
    this.contactEmail,
    this.contactPhone,
    required this.createdAt,
    this.totalRefundsDue = 0.0,
    this.totalRefunded = 0.0,
    this.refundExpenseIds = const [],
    this.refundedExpenseIds = const [],
  });

  double get totalPending => totalRefundsDue - totalRefunded;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'createdAt': createdAt.toIso8601String(),
      'totalRefundsDue': totalRefundsDue,
      'totalRefunded': totalRefunded,
      'refundExpenseIds': refundExpenseIds,
      'refundedExpenseIds': refundedExpenseIds,
    };
  }

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      createdAt: DateTime.parse(json['createdAt']),
      totalRefundsDue: (json['totalRefundsDue'] ?? 0.0).toDouble(),
      totalRefunded: (json['totalRefunded'] ?? 0.0).toDouble(),
      refundExpenseIds: List<String>.from(json['refundExpenseIds'] ?? []),
      refundedExpenseIds: List<String>.from(json['refundedExpenseIds'] ?? []),
    );
  }

  Organization copyWith({
    String? id,
    String? name,
    String? description,
    String? contactEmail,
    String? contactPhone,
    DateTime? createdAt,
    double? totalRefundsDue,
    double? totalRefunded,
    List<String>? refundExpenseIds,
    List<String>? refundedExpenseIds,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      createdAt: createdAt ?? this.createdAt,
      totalRefundsDue: totalRefundsDue ?? this.totalRefundsDue,
      totalRefunded: totalRefunded ?? this.totalRefunded,
      refundExpenseIds: refundExpenseIds ?? this.refundExpenseIds,
      refundedExpenseIds: refundedExpenseIds ?? this.refundedExpenseIds,
    );
  }
}
