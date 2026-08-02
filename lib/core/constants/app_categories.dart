import 'package:flutter/material.dart';

/// Static category / source / payment-method data used across the app.
///
/// Kept as plain constant lists so dropdowns, filters, analytics and seed
/// data all reference a single source of truth.
class AppCategories {
  const AppCategories._();

  /// Expense categories from the PRD (§5.2).
  static const List<String> expense = <String>[
    'Food',
    'Travel',
    'Fuel',
    'Shopping',
    'PG',
    'Rent',
    'Electricity',
    'Water Bill',
    'Internet',
    'Mobile Recharge',
    'Entertainment',
    'Gym',
    'Education',
    'Medical',
    'Investment',
    'Insurance',
    'Subscription',
    'EMI',
    'Gifts',
    'Others',
  ];

  /// Income sources from the PRD (§5.3).
  static const List<String> income = <String>[
    'Salary',
    'Freelancing',
    'Business',
    'Bonus',
    'Investment Return',
    'Gift',
    'Refund',
    'Others',
  ];

  /// Payment methods from the PRD (§5.10).
  static const List<String> paymentMethods = <String>[
    'Cash',
    'UPI',
    'Credit Card',
    'Debit Card',
    'Net Banking',
    'Wallet',
  ];

  /// Icon lookup for expense categories; falls back to a generic icon.
  static IconData expenseIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Travel':
        return Icons.flight_takeoff;
      case 'Fuel':
        return Icons.local_gas_station;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'PG':
        return Icons.night_shelter;
      case 'Rent':
        return Icons.home;
      case 'Electricity':
        return Icons.bolt;
      case 'Water Bill':
        return Icons.water_drop;
      case 'Internet':
        return Icons.wifi;
      case 'Mobile Recharge':
        return Icons.smartphone;
      case 'Entertainment':
        return Icons.movie;
      case 'Gym':
        return Icons.fitness_center;
      case 'Education':
        return Icons.school;
      case 'Medical':
        return Icons.local_hospital;
      case 'Investment':
        return Icons.trending_up;
      case 'Insurance':
        return Icons.shield;
      case 'Subscription':
        return Icons.subscriptions;
      case 'EMI':
        return Icons.account_balance;
      case 'Gifts':
        return Icons.card_giftcard;
      default:
        return Icons.receipt_long;
    }
  }

  /// Icon lookup for income sources.
  static IconData incomeIcon(String source) {
    switch (source) {
      case 'Salary':
        return Icons.payments;
      case 'Freelancing':
        return Icons.laptop_mac;
      case 'Business':
        return Icons.storefront;
      case 'Bonus':
        return Icons.emoji_events;
      case 'Investment Return':
        return Icons.trending_up;
      case 'Gift':
        return Icons.card_giftcard;
      case 'Refund':
        return Icons.replay;
      default:
        return Icons.attach_money;
    }
  }

  /// Icon lookup for a payment method.
  static IconData paymentIcon(String method) {
    switch (method) {
      case 'Cash':
        return Icons.money;
      case 'UPI':
        return Icons.qr_code;
      case 'Credit Card':
        return Icons.credit_card;
      case 'Debit Card':
        return Icons.credit_card;
      case 'Net Banking':
        return Icons.account_balance;
      case 'Wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }
}
