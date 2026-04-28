enum ExpenseType { personal, companyRefund }

class Expense {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final ExpenseType type;
  final String? organizationId;
  final String? organizationName;
  final String? description;
  final String? receiptUrl;
  final bool isRefunded;

  Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
    this.organizationId,
    this.organizationName,
    this.description,
    this.receiptUrl,
    this.isRefunded = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.toString(),
      'organizationId': organizationId,
      'organizationName': organizationName,
      'description': description,
      'receiptUrl': receiptUrl,
      'isRefunded': isRefunded,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      title: json['title'] ?? '',
      category: json['category'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      type: json['type']?.toString().contains('personal') == true
          ? ExpenseType.personal
          : ExpenseType.companyRefund,
      organizationId: json['organizationId'],
      organizationName: json['organizationName'],
      description: json['description'],
      receiptUrl: json['receiptUrl'],
      isRefunded: json['isRefunded'] ?? false,
    );
  }
}
