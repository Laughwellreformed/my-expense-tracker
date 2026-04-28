enum AccountType { main, savings, investment, emergency, custom }

class Account {
  final String id;
  final String name;
  final AccountType type;
  final double balance;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Account({
    required this.id,
    required this.name,
    required this.type,
    this.balance = 0.0,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'balance': balance,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      name: json['name'],
      type: AccountType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => AccountType.custom,
      ),
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? balance,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AccountTransaction {
  final String id;
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final String? note;
  final DateTime timestamp;

  AccountTransaction({
    required this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    this.note,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      'amount': amount,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AccountTransaction.fromJson(Map<String, dynamic> json) {
    return AccountTransaction(
      id: json['id'],
      fromAccountId: json['fromAccountId'],
      toAccountId: json['toAccountId'],
      amount: (json['amount'] as num).toDouble(),
      note: json['note'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
