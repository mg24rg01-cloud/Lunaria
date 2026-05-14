import 'package:flutter/material.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String password;
  final String currency;
  final String themePreference;
  final String language;

  User({
    required this.id, 
    required this.name, 
    required this.email, 
    required this.password,
    this.currency = 'MXN', 
    this.themePreference = 'light',
    this.language = 'es',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'currency': currency,
      'themePreference': themePreference,
      'language': language,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      currency: map['currency'] ?? 'MXN',
      themePreference: map['themePreference'] ?? 'light',
      language: map['language'] ?? 'es',
    );
  }
}

class Account {
  final String id;
  final String userId;
  final String name;
  final String type;
  final double balance;
  final int? cutOffDay;
  final int? paymentDay;
  final Color color;

  Account({required this.id, required this.userId, required this.name, required this.type, required this.balance, this.cutOffDay, this.paymentDay, required this.color});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type,
      'balance': balance,
      'cutOffDay': cutOffDay,
      'paymentDay': paymentDay,
      'color': color.value,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      type: map['type'],
      balance: (map['balance'] ?? 0.0).toDouble(),
      cutOffDay: map['cutOffDay'],
      paymentDay: map['paymentDay'],
      color: Color(map['color']),
    );
  }
}

class Notebook {
  final String id;
  final String userId;
  final String name;
  final String description;
  final String type;
  final Color color;
  final IconData icon;
  final double? targetAmount;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? month;
  final int? year;

  Notebook({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.type,
    required this.color,
    required this.icon,
    this.targetAmount,
    this.startDate,
    this.endDate,
    this.month,
    this.year,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'type': type,
      'color': color.value,
      'icon': icon.codePoint,
      'targetAmount': targetAmount,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'month': month,
      'year': year,
    };
  }

  factory Notebook.fromMap(Map<String, dynamic> map) {
    return Notebook(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      description: map['description'],
      type: map['type'],
      color: Color(map['color']),
      icon: IconData(map['icon'], fontFamily: 'MaterialIcons'),
      targetAmount: map['targetAmount'],
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      month: map['month'],
      year: map['year'],
    );
  }
}

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String type;
  final String? parentId;
  final double? budgetLimit;

  Category({required this.id, required this.name, required this.icon, required this.color, required this.type, this.parentId, this.budgetLimit});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'color': color.value,
      'type': type,
      'parentId': parentId,
      'budgetLimit': budgetLimit,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      icon: IconData(map['icon'], fontFamily: 'MaterialIcons'),
      color: Color(map['color']),
      type: map['type'],
      parentId: map['parentId'],
      budgetLimit: map['budgetLimit'],
    );
  }
}

class Entry {
  final String id;
  final String notebookId;
  final String accountId;
  final String type;
  final double amount;
  final String categoryId;
  final DateTime date;
  final String notes;
  final List<String> tags;
  final String paymentMethod;
  final bool isReconciled;

  Entry({
    required this.id,
    required this.notebookId,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.notes,
    this.tags = const [],
    this.paymentMethod = 'card',
    this.isReconciled = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notebookId': notebookId,
      'accountId': accountId,
      'type': type,
      'amount': amount,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'notes': notes,
      'tags': tags.join(','),
      'paymentMethod': paymentMethod,
      'isReconciled': isReconciled ? 1 : 0,
    };
  }

  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id: map['id'],
      notebookId: map['notebookId'],
      accountId: map['accountId'],
      type: map['type'],
      amount: map['amount'],
      categoryId: map['categoryId'],
      date: DateTime.parse(map['date']),
      notes: map['notes'],
      tags: map['tags'] != null && map['tags'].toString().isNotEmpty ? map['tags'].toString().split(',') : [],
      paymentMethod: map['paymentMethod'],
      isReconciled: map['isReconciled'] == 1,
    );
  }
}

class Subscription {
  final String id;
  final String notebookId;
  final String name;
  final double amount;
  final String frequency; // 'monthly', 'yearly'
  final DateTime nextBillingDate;
  final bool isActive;
  final String categoryId;
  final String accountId;
  final DateTime? lastProcessed; // To avoid duplicate processing
  final String? classification; // 'Entretenimiento', 'Educación', etc.

  Subscription({
    required this.id,
    required this.notebookId,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.nextBillingDate,
    this.isActive = true,
    required this.categoryId,
    required this.accountId,
    this.lastProcessed,
    this.classification,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notebookId': notebookId,
      'name': name,
      'amount': amount,
      'frequency': frequency,
      'nextBillingDate': nextBillingDate.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'categoryId': categoryId,
      'accountId': accountId,
      'lastProcessed': lastProcessed?.toIso8601String(),
      'classification': classification,
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'],
      notebookId: map['notebookId'],
      name: map['name'],
      amount: map['amount'],
      frequency: map['frequency'],
      nextBillingDate: DateTime.parse(map['nextBillingDate']),
      isActive: map['isActive'] == 1,
      categoryId: map['categoryId'],
      accountId: map['accountId'],
      lastProcessed: map['lastProcessed'] != null ? DateTime.parse(map['lastProcessed']) : null,
      classification: map['classification'],
    );
  }

  double get monthlyEquivalent {
    if (frequency == 'yearly') return amount / 12;
    return amount;
  }
}

class MonthlyPlan {
  final String id;
  final String notebookId;
  final int month;
  final int year;
  final double expectedIncome;
  final double targetSavings;
  final Map<String, double> categoryLimits; // categoryId -> amount

  MonthlyPlan({
    required this.id,
    required this.notebookId,
    required this.month,
    required this.year,
    required this.expectedIncome,
    required this.targetSavings,
    required this.categoryLimits,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notebookId': notebookId,
      'month': month,
      'year': year,
      'expectedIncome': expectedIncome,
      'targetSavings': targetSavings,
      'categoryLimits': categoryLimits,
    };
  }

  factory MonthlyPlan.fromMap(Map<dynamic, dynamic> map) {
    return MonthlyPlan(
      id: map['id'],
      notebookId: map['notebookId'],
      month: map['month'],
      year: map['year'],
      expectedIncome: (map['expectedIncome'] ?? 0).toDouble(),
      targetSavings: (map['targetSavings'] ?? 0).toDouble(),
      categoryLimits: Map<String, double>.from(map['categoryLimits'] ?? {}),
    );
  }
}

class Debt {
  final String id;
  final String notebookId;
  final String name;
  final double totalAmount;
  final double currentBalance;
  final double interestRate; // Annual %
  final double minimumPayment;
  final DateTime dueDate;
  final String type; // card, loan, etc.
  final String status; // active, paid

  Debt({
    required this.id,
    required this.notebookId,
    required this.name,
    required this.totalAmount,
    required this.currentBalance,
    required this.interestRate,
    required this.minimumPayment,
    required this.dueDate,
    required this.type,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notebookId': notebookId,
      'name': name,
      'totalAmount': totalAmount,
      'currentBalance': currentBalance,
      'interestRate': interestRate,
      'minimumPayment': minimumPayment,
      'dueDate': dueDate.toIso8601String(),
      'type': type,
      'status': status,
    };
  }

  factory Debt.fromMap(Map<dynamic, dynamic> map) {
    DateTime parsedDate;
    var rawDate = map['dueDate'];
    if (rawDate is String) {
      parsedDate = DateTime.parse(rawDate);
    } else if (rawDate is int) {
      // Migration: convert old day-of-month to a DateTime
      final now = DateTime.now();
      parsedDate = DateTime(now.year, now.month, rawDate);
    } else {
      parsedDate = DateTime.now();
    }

    return Debt(
      id: map['id'],
      notebookId: map['notebookId'],
      name: map['name'],
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      currentBalance: (map['currentBalance'] ?? 0).toDouble(),
      interestRate: (map['interestRate'] ?? 0).toDouble(),
      minimumPayment: (map['minimumPayment'] ?? 0).toDouble(),
      dueDate: parsedDate,
      type: map['type'] ?? 'tarjeta',
      status: map['status'] ?? 'active',
    );
  }

  double get progress => totalAmount > 0 ? (totalAmount - currentBalance) / totalAmount : 0;
  double get monthlyInterestAmount => currentBalance * (interestRate / 100 / 12);
}
