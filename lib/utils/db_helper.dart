import 'package:hive_flutter/hive_flutter.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    
    // Open boxes (like tables)
    await Hive.openBox('users');
    await Hive.openBox('accounts');
    await Hive.openBox('notebooks');
    await Hive.openBox('categories');
    await Hive.openBox('entries');
    await Hive.openBox('subscriptions');
    await Hive.openBox('monthly_plans');
    final boxes = ['users', 'accounts', 'notebooks', 'categories', 'entries', 'subscriptions', 'monthly_plans', 'debts'];
    await Hive.openBox('debts');
    
    _initialized = true;
  }

  // Generic CRUD
  Future<void> insert(String table, Map<String, dynamic> data) async {
    await init();
    final box = Hive.box(table);
    await box.put(data['id'], data);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    await init();
    final box = Hive.box(table);
    return box.values.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<void> update(String table, Map<String, dynamic> data, String id) async {
    await init();
    final box = Hive.box(table);
    await box.put(id, data);
  }

  Future<void> delete(String table, String id) async {
    await init();
    final box = Hive.box(table);
    await box.delete(id);
  }

  // Clear all data
  Future<void> clearDatabase() async {
    await init();
    await Hive.box('users').clear();
    await Hive.box('accounts').clear();
    await Hive.box('notebooks').clear();
    await Hive.box('categories').clear();
    await Hive.box('entries').clear();
    await Hive.box('subscriptions').clear();
    await Hive.box('monthly_plans').clear();
    await Hive.box('debts').clear();
  }
}
