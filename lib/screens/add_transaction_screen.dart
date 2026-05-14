import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../models/schema.dart';
import '../utils/formatters.dart';
import '../utils/l10n.dart';

class AddTransactionScreen extends StatefulWidget {
  final String? initialNotebookId;
  final Entry? entry;
  const AddTransactionScreen({super.key, this.initialNotebookId, this.entry});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool isExpense = true;
  String _amount = '0';
  final TextEditingController _titleController = TextEditingController();
  late String _selectedCategory;
  late String _selectedAccountId;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    final categories = AppState().categories.value;
    if (categories.isEmpty) {
      _selectedCategory = 'temp';
    } else {
      _selectedCategory = categories.firstWhere((c) => c.type == 'expense', orElse: () => categories.first).id;
    }
    
    final accounts = AppState().accounts.value;
    if (widget.entry != null) {
      _isEdit = true;
      final existing = widget.entry!;
      isExpense = existing.type != 'income';
      _amount = existing.amount.toStringAsFixed(existing.amount.truncateToDouble() == existing.amount ? 0 : 2);
      _titleController.text = existing.notes;
      _selectedCategory = existing.categoryId;
      _selectedAccountId = existing.accountId;
    } else {
      try {
        _selectedAccountId = accounts.firstWhere((a) => a.type == 'debit').id;
      } catch (e) {
        _selectedAccountId = accounts.isNotEmpty ? accounts.first.id : 'a1';
      }
    }
  }

  void _onKeypadTap(String value) {
    setState(() {
      if (value == '<') {
        if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);
        } else {
          _amount = '0';
        }
      } else if (value == '.') {
        if (!_amount.contains('.')) _amount += '.';
      } else {
        if (_amount == '0') {
          _amount = value;
        } else {
          _amount += value;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = AppState().categories.value;
    List<Category> filteredCats = categories.where((c) => c.type == (isExpense ? 'expense' : 'income')).toList();
    if (!filteredCats.any((c) => c.id == _selectedCategory) && filteredCats.isNotEmpty) {
      _selectedCategory = filteredCats.first.id;
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color dustyPink = isDarkMode ? const Color(0xFFF49FB6) : const Color(0xFFD4A5A5);
    final Color softGray = isDarkMode ? Colors.white70 : const Color(0xFF8D8D8D);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            
            // Type Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => setState(() => isExpense = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(color: isExpense ? dustyPink.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                    child: Text(L10n.s('expense'), style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: isExpense ? dustyPink : Colors.grey[400])),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => setState(() => isExpense = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(color: !isExpense ? dustyPink.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                    child: Text(L10n.s('income_label'), style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: !isExpense ? dustyPink : Colors.grey[400])),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Amount
            Text('\$$_amount', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w300, color: dustyPink, letterSpacing: -1.5)),
            const SizedBox(height: 12),
            
            // Details Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: softGray, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: L10n.s('transaction_hint'),
                      hintStyle: TextStyle(color: Colors.grey[300], fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                  Container(height: 1, color: isDarkMode ? Colors.white10 : Colors.grey[100]),
                  const SizedBox(height: 10),
                  
                  // Categories
                  SizedBox(
                    height: 65,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredCats.length,
                      itemBuilder: (context, index) {
                        final c = filteredCats[index];
                        final isSelected = c.id == _selectedCategory;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = c.id),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? dustyPink.withOpacity(0.1) : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white),
                                    border: Border.all(color: isSelected ? dustyPink : (isDarkMode ? Colors.white12 : Colors.grey[200]!)),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(c.icon, color: isSelected ? dustyPink : Colors.grey[400], size: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(c.name, style: TextStyle(fontSize: 8, color: isSelected ? dustyPink : Colors.grey[400])),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Account Selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white.withOpacity(0.05) : const Color(0xFFF7F7FB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDarkMode ? Colors.white12 : const Color(0xFFF0F0F0)),
                    ),
                    child: DropdownButton<String>(
                      value: _getDisplayLabel(_selectedAccountId),
                      isExpanded: true,
                      dropdownColor: Theme.of(context).cardColor,
                      underline: const SizedBox(),
                      icon: Icon(Icons.keyboard_arrow_down, color: dustyPink),
                      style: TextStyle(color: softGray, fontSize: 14),
                      items: [
                        _buildDropdownItem(L10n.s('cash'), Icons.money, Colors.green),
                        _buildDropdownItem(L10n.s('debit_card'), Icons.credit_card, Colors.blue),
                        _buildDropdownItem(L10n.s('credit_card'), Icons.account_balance_wallet, Colors.orange),
                      ],
                      onChanged: (label) {
                        if (label != null) {
                          _handleSelection(label);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildCompactKeypadRow(['1', '2', '3']),
                  const SizedBox(height: 8),
                  _buildCompactKeypadRow(['4', '5', '6']),
                  const SizedBox(height: 8),
                  _buildCompactKeypadRow(['7', '8', '9']),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCompactKeypadButton('.'),
                      const SizedBox(width: 12),
                      _buildCompactKeypadButton('0'),
                      const SizedBox(width: 12),
                      _buildCompactKeypadButton('<'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        double amount = double.tryParse(_amount) ?? 0;
                        if(amount > 0 && _titleController.text.isNotEmpty) {
                          final notebookId = widget.entry?.notebookId ?? widget.initialNotebookId ?? (AppState().notebooks.value.isNotEmpty ? AppState().notebooks.value.first.id : 'n1');
                          final entry = Entry(
                            id: widget.entry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            notebookId: notebookId,
                            accountId: _selectedAccountId,
                            type: isExpense ? 'expense' : 'income',
                            amount: amount,
                            categoryId: _selectedCategory,
                            date: DateTime.now(),
                            notes: _titleController.text,
                            tags: widget.entry?.tags ?? [],
                          );
                          
                          if (_isEdit) {
                            AppState().editEntry(entry.id, entry);
                          } else {
                            AppState().addEntry(entry);
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${_isEdit ? L10n.s('success') : (isExpense ? L10n.s('expense') : L10n.s('income_label'))}: ${formatCurrency(amount)}', 
                                style: TextStyle(color: Theme.of(context).cardColor)
                              ),
                              backgroundColor: dustyPink,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dustyPink,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        elevation: 0,
                      ),
                      child: Text(L10n.s('save'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Theme.of(context).cardColor)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayLabel(String id) {
    final account = AppState().accounts.value.firstWhere((a) => a.id == id, orElse: () => AppState().accounts.value.first);
    if (account.type == 'cash') return L10n.s('cash');
    if (account.type == 'debit') return L10n.s('debit_card');
    return L10n.s('credit_card');
  }

  void _handleSelection(String label) {
    final accounts = AppState().accounts.value;
    if (label == L10n.s('cash')) {
      setState(() => _selectedAccountId = accounts.firstWhere((a) => a.type == 'cash').id);
    } else if (label == L10n.s('debit_card')) {
      setState(() => _selectedAccountId = accounts.firstWhere((a) => a.type == 'debit').id);
    } else {
      setState(() => _selectedAccountId = accounts.firstWhere((a) => a.type == 'credit').id);
    }
  }

  DropdownMenuItem<String> _buildDropdownItem(String label, IconData icon, Color color) {
    return DropdownMenuItem(
      value: label,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildCompactKeypadRow(List<String> values) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: values.map((v) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: _buildCompactKeypadButton(v),
      )).toList(),
    );
  }

  Widget _buildCompactKeypadButton(String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => _onKeypadTap(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 70,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: value == '<' 
            ? Icon(Icons.backspace_outlined, size: 18, color: Colors.grey[400]) 
            : Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: isDark ? Colors.white70 : Colors.grey[600])),
        ),
      ),
    );
  }
}
