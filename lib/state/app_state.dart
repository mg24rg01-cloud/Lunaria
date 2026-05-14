import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/schema.dart';
import '../utils/db_helper.dart';
import '../services/csv_import_service.dart';

class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final DBHelper _dbHelper = DBHelper();

  final ValueNotifier<User?> user = ValueNotifier(null);
  final ValueNotifier<List<Notebook>> notebooks = ValueNotifier([]);
  final ValueNotifier<List<Entry>> entries = ValueNotifier([]);
  final ValueNotifier<List<Category>> categories = ValueNotifier([]);
  final ValueNotifier<List<Account>> accounts = ValueNotifier([]);
  final ValueNotifier<List<Subscription>> subscriptions = ValueNotifier([]);
  final ValueNotifier<List<MonthlyPlan>> monthlyPlans = ValueNotifier([]);
  final ValueNotifier<List<Debt>> debts = ValueNotifier([]);

  final ValueNotifier<bool> isLoading = ValueNotifier(true);
  final ValueNotifier<String?> budgetAlert = ValueNotifier(null);
  final ValueNotifier<bool> isAuthenticated = ValueNotifier(false);

  Future<void> init() async {
    isLoading.value = true;
    await _dbHelper.init();

    final usersData = await _dbHelper.queryAll('users');
    if (usersData.isNotEmpty) {
      // User exists, but we wait for login
      // We don't load data yet until authenticated
    } else {
      // No user, AuthScreen will handle signup
    }

    isLoading.value = false;
  }

  Future<void> _syncNotebookStyles() async {
    if (user.value == null) return;
    bool changed = false;
    final List<Notebook> currentNotebooks = List.from(notebooks.value);

    for (int i = 0; i < currentNotebooks.length; i++) {
      final nb = currentNotebooks[i];
      Color? newColor;
      IconData? newIcon;

      if (nb.type == 'Control Mensual') {
        newColor = const Color(0xFFD4A5A5);
        newIcon = Icons.menu_book;
      } else if (nb.type == 'Suscripciones') {
        newColor = const Color(0xFF9E9E9E);
        newIcon = Icons.autorenew;
      } else if (nb.type == 'Ahorro') {
        newColor = const Color(0xFF81C784);
        newIcon = Icons.savings;
      } else if (nb.type == 'Deudas') {
        newColor = const Color(0xFFE57373);
        newIcon = Icons.credit_score;
      }

      if (newColor != null &&
          (nb.color.value != newColor.value || nb.icon != newIcon)) {
        final updatedNb = Notebook(
            id: nb.id,
            userId: nb.userId,
            name: nb.name,
            description: nb.description,
            type: nb.type,
            color: newColor,
            icon: newIcon!,
            targetAmount: nb.targetAmount,
            month: nb.month,
            year: nb.year);
        await _dbHelper.update('notebooks', updatedNb.toMap(), nb.id);
        currentNotebooks[i] = updatedNb;
        changed = true;
      }
    }

    if (changed) {
      notebooks.value = currentNotebooks;
    }
  }

  Future<void> _ensureStandardAccounts() async {
    if (user.value == null) return;
    
    // Consultamos la base de datos directamente para evitar problemas con el estado en memoria desactualizado
    final accData = await _dbHelper.queryAll('accounts');
    final existingNames = accData
        .where((m) => m['userId'] == user.value!.id)
        .map((m) => m['name'] as String)
        .toList();
        
    bool added = false;

    if (!existingNames.contains('Tarjeta de Crédito')) {
      await _dbHelper.insert(
          'accounts',
          Account(
                  id: 'acc_credit_${DateTime.now().millisecondsSinceEpoch}',
                  userId: user.value!.id,
                  name: 'Tarjeta de Crédito',
                  type: 'credit',
                  balance: 0.0,
                  color: Colors.orange)
              .toMap());
      added = true;
    }
    if (!existingNames.contains('Efectivo')) {
      await _dbHelper.insert(
          'accounts',
          Account(
                  id: 'acc_cash_${DateTime.now().millisecondsSinceEpoch}',
                  userId: user.value!.id,
                  name: 'Efectivo',
                  type: 'cash',
                  balance: 0.0,
                  color: Colors.green)
              .toMap());
      added = true;
    }
    if (!existingNames.contains('Tarjeta de Débito')) {
      await _dbHelper.insert(
          'accounts',
          Account(
                  id: 'acc_debit_${DateTime.now().millisecondsSinceEpoch}',
                  userId: user.value!.id,
                  name: 'Tarjeta de Débito',
                  type: 'debit',
                  balance: 0.0,
                  color: Colors.blue)
              .toMap());
      added = true;
    }

    if (added) {
      await _loadFromDB();
    } else {
      // Incluso si las cuentas ya existen, verificamos si alguna tiene el balance de 5000 para corregirlo inmediatamente
      await _loadFromDB(); 
    }
  }

  Future<void> _initMocks() async {
    final mockCategories = [
      Category(
          id: 'c1',
          name: 'Alimentos',
          type: 'expense',
          icon: Icons.fastfood,
          color: Colors.orange,
          budgetLimit: 0),
      Category(
          id: 'c2',
          name: 'Transporte',
          type: 'expense',
          icon: Icons.directions_car,
          color: Colors.blue,
          budgetLimit: 0),
      Category(
          id: 'c3',
          name: 'Suscripciones',
          type: 'expense',
          icon: Icons.movie,
          color: Colors.red,
          budgetLimit: 0),
      Category(
          id: 'c4',
          name: 'Salario',
          type: 'income',
          icon: Icons.attach_money,
          color: Colors.green),
      Category(
          id: 'c5',
          name: 'Deudas',
          type: 'expense',
          icon: Icons.money_off,
          color: Colors.purple,
          budgetLimit: 0),
      Category(
          id: 'c6',
          name: 'Hogar',
          type: 'expense',
          icon: Icons.home,
          color: Colors.indigo,
          budgetLimit: 0),
      Category(
          id: 'c7',
          name: 'Salud',
          type: 'expense',
          icon: Icons.medical_services,
          color: Colors.teal,
          budgetLimit: 0),
      Category(
          id: 'c8',
          name: 'Otros',
          type: 'expense',
          icon: Icons.more_horiz,
          color: Colors.grey,
          budgetLimit: 0),
    ];

    for (var c in mockCategories) {
      final exists = categories.value.any((cat) => cat.name == c.name);
      if (!exists) await _dbHelper.insert('categories', c.toMap());
    }

    await _loadFromDB();
  }

  Future<void> _loadFromDB() async {
    final currentUserId = user.value?.id;
    if (currentUserId == null) return;

    final catData = await _dbHelper.queryAll('categories');
    categories.value = catData.map((m) => Category.fromMap(m)).toList();

    final accData = await _dbHelper.queryAll('accounts');
    final myAccounts = accData
        .where((m) => m['userId'] == currentUserId)
        .map((m) => Account.fromMap(m))
        .toList();

    // Corrección Nuclear Extrema: Limpiar balances residuales y vinculaciones fantasma
    bool corrected = false;
    for (int i = 0; i < myAccounts.length; i++) {
      final acc = myAccounts[i];
      // Si el balance es 5000 o el nombre sugiere vinculación externa residual
      if (acc.balance == 5000.0 || acc.name.toLowerCase().contains('vincul')) {
        final correctedAcc = Account(
          id: acc.id,
          userId: acc.userId,
          name: acc.name.toLowerCase().contains('vincul') ? 'Cuenta Corregida' : acc.name,
          type: acc.type,
          balance: 0.0,
          color: acc.color,
          cutOffDay: acc.cutOffDay,
          paymentDay: acc.paymentDay,
        );
        await _dbHelper.update('accounts', correctedAcc.toMap(), correctedAcc.id);
        myAccounts[i] = correctedAcc;
        corrected = true;
      }
    }
    accounts.value = myAccounts;
    if (corrected) {
      debugPrint('Se detectó y eliminó una vinculación o balance residual de \$5,000.00');
    }

    final nbData = await _dbHelper.queryAll('notebooks');
    notebooks.value = nbData
        .where((m) => m['userId'] == currentUserId)
        .map((m) => Notebook.fromMap(m))
        .toList();

    final entData = await _dbHelper.queryAll('entries');
    final myNotebookIds = notebooks.value.map((n) => n.id).toSet();
    entries.value = entData
        .map((m) => Entry.fromMap(m))
        .where((e) => myNotebookIds.contains(e.notebookId))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final subData = await _dbHelper.queryAll('subscriptions');
    subscriptions.value = subData
        .where((m) => m['userId'] == currentUserId)
        .map((m) => Subscription.fromMap(m))
        .toList();

    final planData = await _dbHelper.queryAll('monthly_plans');
    monthlyPlans.value = planData
        .map((m) => MonthlyPlan.fromMap(m))
        .where((p) => myNotebookIds.contains(p.notebookId))
        .toList();

    final debtData = await _dbHelper.queryAll('debts');
    debts.value = debtData
        .map((m) => Debt.fromMap(m))
        .where((d) => myNotebookIds.contains(d.notebookId))
        .toList();
  }

  // Auth Methods (OTP Flow)
  // Auth Methods
  Future<void> signup(String nickname, String password) async {
    final newUser = User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: nickname,
      email: '',
      password: password,
    );
    await _dbHelper.insert('users', newUser.toMap());
    user.value = newUser;
    isAuthenticated.value = true;
    
    await _initMocks();
    await _ensureStandardAccounts();
    
    // Cuaderno por defecto: Control Mensual
    final defaultNotebook = Notebook(
      id: 'nb_default_${DateTime.now().millisecondsSinceEpoch}',
      userId: newUser.id,
      name: 'Control Mensual',
      description: 'Mi presupuesto del mes',
      type: 'Control Mensual',
      color: const Color(0xFFD4A5A5),
      icon: Icons.menu_book,
      month: DateTime.now().month,
      year: DateTime.now().year,
    );
    await addNotebook(defaultNotebook);
    
    await _loadFromDB();
  }

  Future<void> login(String password) async {
    final usersData = await _dbHelper.queryAll('users');
    if (usersData.isEmpty) throw Exception('No hay usuario registrado');
    
    final userData = usersData.first;
    if (userData['password'] == password) {
      user.value = User.fromMap(userData);
      isAuthenticated.value = true;
      await _loadFromDB();
      await _syncNotebookStyles();
      await checkAndProcessSubscriptions();
    } else {
      throw Exception('Contraseña incorrecta');
    }
  }

  Future<void> logout() async {
    user.value = null;
    isAuthenticated.value = false;
    notebooks.value = [];
    entries.value = [];
    accounts.value = [];
    subscriptions.value = [];
    monthlyPlans.value = [];
    debts.value = [];
  }

  Future<void> updateProfile({String? name, String? theme, String? language}) async {
    if (user.value == null) return;
    final updatedUser = User(
      id: user.value!.id,
      name: name ?? user.value!.name,
      email: user.value!.email,
      password: user.value!.password,
      currency: user.value!.currency,
      themePreference: theme ?? user.value!.themePreference,
      language: language ?? user.value!.language,
    );
    await _dbHelper.update('users', updatedUser.toMap(), updatedUser.id);
    user.value = updatedUser;
  }

  Future<bool> userExists() async {
    final usersData = await _dbHelper.queryAll('users');
    return usersData.isNotEmpty;
  }

  Future<void> clearAllData() async {
    await _dbHelper.clearDatabase();
    await logout();
    await init();
  }

  // Entry Methods
  Future<void> addEntry(Entry entry) async {
    await _dbHelper.insert('entries', entry.toMap());
    entries.value = [entry, ...entries.value];
    await _updateAccountBalance(entry.accountId, entry.type, entry.amount,
        isAddition: true);

    final account = getAccount(entry.accountId);
    if (entry.type == 'expense' && account.type == 'credit') {
      await _handleCreditDebt(entry);
    }
    _checkBudgetAlert(entry);
  }

  Future<void> _handleCreditDebt(Entry entry) async {
    Notebook? debtNotebook;
    try {
      debtNotebook = notebooks.value.firstWhere(
          (n) => n.type == 'Deudas' || n.name.toLowerCase().contains('deuda'));
    } catch (e) {
      debtNotebook = Notebook(
        id: 'debt_nb_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.value?.id ?? 'guest',
        name: 'Control de Deudas',
        description: 'Registro automático de compras a crédito',
        type: 'Deudas',
        icon: Icons.credit_score, // Icono de Estado de Crédito
        color: const Color(0xFFE57373), // Coral Suave
      );
      await addNotebook(debtNotebook);
    }

    final debt = Debt(
      id: 'd_${entry.id}',
      notebookId: debtNotebook.id,
      name: entry.notes,
      totalAmount: entry.amount,
      currentBalance: entry.amount,
      interestRate: 0,
      minimumPayment: 0,
      dueDate: DateTime.now().add(const Duration(days: 30)),
      type: 'tarjeta',
    );

    await _dbHelper.insert('debts', debt.toMap());
    debts.value = [...debts.value, debt];
  }

  Future<void> addEntries(List<Entry> newEntries) async {
    for (var entry in newEntries) {
      bool exists = entries.value.any((e) =>
          e.date.year == entry.date.year &&
          e.date.month == entry.date.month &&
          e.date.day == entry.date.day &&
          e.amount == entry.amount &&
          e.notes == entry.notes);
      if (!exists) await addEntry(entry);
    }
  }

  Future<void> editEntry(String id, Entry updatedEntry) async {
    final index = entries.value.indexWhere((e) => e.id == id);
    if (index != -1) {
      final oldEntry = entries.value[index];
      await _updateAccountBalance(
          oldEntry.accountId, oldEntry.type, oldEntry.amount,
          isAddition: false);
      await _dbHelper.update('entries', updatedEntry.toMap(), id);
      await _updateAccountBalance(
          updatedEntry.accountId, updatedEntry.type, updatedEntry.amount,
          isAddition: true);
      final newList = List<Entry>.from(entries.value);
      newList[index] = updatedEntry;
      entries.value = newList;
      _checkBudgetAlert(updatedEntry);
    }
  }

  Future<void> deleteEntry(String id) async {
    final index = entries.value.indexWhere((e) => e.id == id);
    if (index != -1) {
      final entry = entries.value[index];
      await _updateAccountBalance(entry.accountId, entry.type, entry.amount,
          isAddition: false);
      await _dbHelper.delete('entries', id);
      entries.value = entries.value.where((e) => e.id != id).toList();
    }
  }

  Future<void> _updateAccountBalance(
      String accountId, String type, double amount,
      {required bool isAddition}) async {
    final index = accounts.value.indexWhere((a) => a.id == accountId);
    if (index != -1) {
      final account = accounts.value[index];
      double newBalance = account.balance;
      double adjustment = isAddition ? amount : -amount;
      if (type == 'income') {
        newBalance += adjustment;
      } else {
        newBalance -= adjustment;
      }

      final updatedAccount = Account(
          id: account.id,
          userId: account.userId,
          name: account.name,
          type: account.type,
          balance: newBalance,
          color: account.color);
      await _dbHelper.update('accounts', updatedAccount.toMap(), accountId);
      final newList = List<Account>.from(accounts.value);
      newList[index] = updatedAccount;
      accounts.value = newList;
    }
  }

  void _checkBudgetAlert(Entry entry) {
    if (entry.type != 'expense') return;
    final category = getCategory(entry.categoryId);
    final totalSpent = entries.value
        .where((e) =>
            e.categoryId == entry.categoryId &&
            e.type == 'expense' &&
            e.date.month == entry.date.month &&
            e.date.year == entry.date.year)
        .fold(0.0, (sum, e) => sum + e.amount);

    final limit = category.budgetLimit ?? 0;
    if (limit > 0) _processAlert(category.name, totalSpent, limit);

    for (var notebook in notebooks.value) {
      if (notebook.type.toLowerCase().contains('mensual')) {
        final plan =
            getMonthlyPlan(notebook.id, entry.date.month, entry.date.year);
        final planLimit = plan.categoryLimits[entry.categoryId] ?? 0;
        if (planLimit > 0) _processAlert(category.name, totalSpent, planLimit);
      }
    }
  }

  void _processAlert(String categoryName, double spent, double limit) {
    if (spent > limit) {
      budgetAlert.value =
          '¡ALERTA! Has excedido el presupuesto de $categoryName (\$${spent.toStringAsFixed(0)} de \$${limit.toStringAsFixed(0)}).';
    } else if (spent >= limit * 0.8) {
      budgetAlert.value =
          '⚠️ Atención: Estás al ${(spent / limit * 100).toStringAsFixed(0)}% de tu presupuesto en $categoryName.';
    }
  }

  // Notebook Methods
  Future<void> addNotebook(Notebook notebook) async {
    await _dbHelper.insert('notebooks', notebook.toMap());
    notebooks.value = [...notebooks.value, notebook];
  }

  Future<void> deleteNotebook(String id) async {
    await _dbHelper.delete('notebooks', id);
    notebooks.value = notebooks.value.where((n) => n.id != id).toList();
  }

  Future<void> editNotebook(String id, Notebook updatedNotebook) async {
    await _dbHelper.update('notebooks', updatedNotebook.toMap(), id);
    final index = notebooks.value.indexWhere((n) => n.id == id);
    if (index != -1) {
      final newList = List<Notebook>.from(notebooks.value);
      newList[index] = updatedNotebook;
      notebooks.value = newList;
    }
  }

  Category getCategory(String id) {
    return categories.value
        .firstWhere((c) => c.id == id, orElse: () => categories.value.first);
  }

  Account getAccount(String id) {
    return accounts.value
        .firstWhere((a) => a.id == id, orElse: () => accounts.value.first);
  }

  double getNotebookProgress(String notebookId) {
    final notebook = notebooks.value.firstWhere((n) => n.id == notebookId);
    if (notebook.targetAmount == null || notebook.targetAmount == 0) return 0;
    final total = entries.value.where((e) => e.notebookId == notebookId).fold(
        0.0, (sum, e) => e.type == 'income' ? sum + e.amount : sum - e.amount);
    if (notebook.type == 'Ahorro') {
      return (total / notebook.targetAmount!).clamp(0.0, 1.0);
    }
    final spent = entries.value
        .where((e) => e.notebookId == notebookId && e.type == 'expense')
        .fold(0.0, (sum, e) => sum + e.amount);
    return (spent / notebook.targetAmount!).clamp(0.0, 1.0);
  }

  String formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  // Subscription Methods
  Future<void> addSubscription(Subscription sub) async {
    await _dbHelper.insert('subscriptions', sub.toMap());
    subscriptions.value = [...subscriptions.value, sub];
  }

  Future<void> deleteSubscription(String id) async {
    await _dbHelper.delete('subscriptions', id);
    subscriptions.value = subscriptions.value.where((s) => s.id != id).toList();
  }

  Future<void> toggleSubscription(String id) async {
    final index = subscriptions.value.indexWhere((s) => s.id == id);
    if (index != -1) {
      final sub = subscriptions.value[index];
      final updatedSub = Subscription(
          id: sub.id,
          notebookId: sub.notebookId,
          name: sub.name,
          amount: sub.amount,
          frequency: sub.frequency,
          nextBillingDate: sub.nextBillingDate,
          isActive: !sub.isActive,
          categoryId: sub.categoryId,
          accountId: sub.accountId,
          lastProcessed: sub.lastProcessed);
      await _dbHelper.update('subscriptions', updatedSub.toMap(), id);
      final newList = List<Subscription>.from(subscriptions.value);
      newList[index] = updatedSub;
      subscriptions.value = newList;
    }
  }

  Future<void> checkAndProcessSubscriptions() async {
    final now = DateTime.now();
    final updatedSubs = List<Subscription>.from(subscriptions.value);
    bool changed = false;
    for (int i = 0; i < updatedSubs.length; i++) {
      final sub = updatedSubs[i];
      if (!sub.isActive) continue;
      if (sub.nextBillingDate.isBefore(now)) {
        final entry = Entry(
          id: 'sub_gen_${DateTime.now().millisecondsSinceEpoch}_${sub.id}',
          notebookId: sub.notebookId,
          accountId: sub.accountId,
          type: 'expense',
          amount: sub.amount,
          categoryId: sub.categoryId,
          date: now,
          notes: 'Recurrente: ${sub.name}',
          tags: ['Suscripción'],
        );
        await addEntry(entry);
        DateTime nextDate = sub.frequency == 'monthly'
            ? DateTime(sub.nextBillingDate.year, sub.nextBillingDate.month + 1,
                sub.nextBillingDate.day)
            : DateTime(sub.nextBillingDate.year + 1, sub.nextBillingDate.month,
                sub.nextBillingDate.day);
        final newSub = Subscription(
            id: sub.id,
            notebookId: sub.notebookId,
            name: sub.name,
            amount: sub.amount,
            frequency: sub.frequency,
            nextBillingDate: nextDate,
            isActive: sub.isActive,
            categoryId: sub.categoryId,
            accountId: sub.accountId,
            lastProcessed: now);
        updatedSubs[i] = newSub;
        await _dbHelper.update('subscriptions', newSub.toMap(), sub.id);
        changed = true;
      }
    }
    if (changed) subscriptions.value = updatedSubs;
  }

  // Plan/Debt Updates
  Future<void> updateMonthlyPlan(MonthlyPlan plan) async {
    await _dbHelper.insert('monthly_plans', plan.toMap());
    final index = monthlyPlans.value.indexWhere((p) => p.id == plan.id);
    if (index != -1) {
      final newList = List<MonthlyPlan>.from(monthlyPlans.value);
      newList[index] = plan;
      monthlyPlans.value = newList;
    } else {
      monthlyPlans.value = [...monthlyPlans.value, plan];
    }
  }

  MonthlyPlan getMonthlyPlan(String notebookId, int month, int year) {
    return monthlyPlans.value.firstWhere(
      (p) => p.notebookId == notebookId && p.month == month && p.year == year,
      orElse: () => MonthlyPlan(
        id: '${notebookId}_${month}_$year',
        notebookId: notebookId,
        month: month,
        year: year,
        expectedIncome: 0,
        targetSavings: 0,
        categoryLimits: {},
      ),
    );
  }

  Future<void> addDebt(Debt debt) async {
    await _dbHelper.insert('debts', debt.toMap());
    debts.value = [...debts.value, debt];
  }

  Future<void> updateDebt(Debt debt) async {
    await _dbHelper.update('debts', debt.toMap(), debt.id);
    final index = debts.value.indexWhere((d) => d.id == debt.id);
    if (index != -1) {
      final newList = List<Debt>.from(debts.value);
      newList[index] = debt;
      debts.value = newList;
    }
  }

  // CSV Import (Delegado al servicio para mayor robustez)
  Future<int> importFromCSV(String notebookId, String accountId) async {
    try {
      final service = CSVImportService();
      final List<Entry> newEntries =
          await service.importCSV(notebookId: notebookId, accountId: accountId);

      if (newEntries.isEmpty) return 0;

      await addEntries(newEntries);
      return newEntries.length;
    } catch (e) {
      debugPrint('Error en importación CSV: $e');
      return -1;
    }
  }

  String _detectCategory(String note, String type) {
    final n = note.toLowerCase();
    final cats = categories.value.where((c) => c.type == type).toList();
    if (cats.isEmpty) return 'c8';
    if (n.contains('rest') || n.contains('comida') || n.contains('rappi')) {
      return cats
          .firstWhere((c) => c.name.contains('Alim'), orElse: () => cats.first)
          .id;
    }
    if (n.contains('uber') || n.contains('gas')) {
      return cats
          .firstWhere((c) => c.name.contains('Trans'), orElse: () => cats.first)
          .id;
    }
    if (n.contains('netflix') || n.contains('spotify')) {
      return cats
          .firstWhere((c) => c.name.contains('Susc'), orElse: () => cats.first)
          .id;
    }
    return cats
        .firstWhere((c) => c.name.contains('Otro'), orElse: () => cats.first)
        .id;
  }
}
