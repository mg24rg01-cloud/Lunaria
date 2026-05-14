import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/schema.dart';
import '../state/app_state.dart';
import '../widgets/summary_card.dart';
import 'notebook_detail_screen.dart';
import 'package:intl/intl.dart';
import '../utils/l10n.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dustyPink = isDarkMode ? const Color(0xFFF49FB6) : const Color(0xFFD4A5A5);
    final softBlue = isDarkMode ? const Color(0xFF00BCD4) : const Color(0xFF81D4FA);
    final softGreen = isDarkMode ? const Color(0xFF66BB6A) : const Color(0xFF81C784);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2C2C37);
    final subtleTextColor = isDarkMode ? Colors.white70 : Colors.grey[600]!;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        L10n.s('hello'),
                        style: TextStyle(color: subtleTextColor, fontSize: 16),
                      ),
                      ValueListenableBuilder(
                        valueListenable: AppState().user,
                        builder: (context, user, child) {
                          return Text(
                            user?.name ?? 'Usuario',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: dustyPink.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: dustyPink.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Icon(Icons.person_outline, color: dustyPink),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              Text(
                L10n.s('current_status'),
                style: TextStyle(
                  color: subtleTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              
              ValueListenableBuilder(
                valueListenable: AppState().accounts,
                builder: (context, accounts, child) {
                  return ValueListenableBuilder(
                    valueListenable: AppState().entries,
                    builder: (context, entries, child) {
                      double totalBalance = accounts.fold(0, (sum, item) => sum + item.balance);
                      double income = entries.where((e) => e.type == 'income').fold(0, (sum, e) => sum + e.amount);
                      double expense = entries.where((e) => e.type == 'expense').fold(0, (sum, e) => sum + e.amount);
 
                      return Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [dustyPink, dustyPink.withValues(alpha: 0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: dustyPink.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(L10n.s('total_balance'), style: const TextStyle(color: Colors.white70, fontSize: 16)),
                                const SizedBox(height: 8),
                                Text(
                                  NumberFormat.simpleCurrency().format(totalBalance),
                                  style: TextStyle(color: Theme.of(context).cardColor, fontSize: 36, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildMiniStat(L10n.s('income'), income, Icons.arrow_upward),
                                    _buildMiniStat(L10n.s('expenses'), expense, Icons.arrow_downward),
                                  ],
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            L10n.s('quick_analysis'),
                            style: TextStyle(color: subtleTextColor, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 16),
                          _buildQuickChart(context, income, expense),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                L10n.s('recent_activity'),
                                style: TextStyle(color: subtleTextColor, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: Text(L10n.s('view_all'), style: TextStyle(color: dustyPink)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (entries.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: isDarkMode ? Colors.white12 : Colors.grey[100]!),
                              ),
                              child: Center(
                                child: Text(L10n.s('no_recent_activity'), style: TextStyle(color: subtleTextColor)),
                              ),
                            )
                          else
                            ...entries.take(5).map((e) => _buildTransactionItem(context, e)),
                        ],
                      );
                    }
                  );
                },
              ),
              
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    L10n.s('recent_notebooks'),
                    style: TextStyle(color: subtleTextColor, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  TextButton(
                    onPressed: () {}, // Navigate to Notebooks
                    child: Text(L10n.s('view_all'), style: TextStyle(color: dustyPink)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              ValueListenableBuilder(
                valueListenable: AppState().notebooks,
                builder: (context, notebooks, child) {
                  if (notebooks.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isDarkMode ? Colors.white12 : Colors.grey[100]!),
                      ),
                      child: Center(
                        child: Text(L10n.s('no_active_notebooks'), style: TextStyle(color: subtleTextColor)),
                      ),
                    );
                  }
                  
                  return SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: notebooks.length > 3 ? 3 : notebooks.length,
                      itemBuilder: (context, index) {
                        final nb = notebooks[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NotebookDetailScreen(notebook: nb))),
                            child: SummaryCard(
                              title: nb.name,
                              amount: nb.month == DateTime.now().month ? (L10n.s('this_month') == 'this_month' ? 'Este Mes' : L10n.s('this_month')) : '${nb.month}/${nb.year}',
                              icon: nb.icon,
                              color: nb.color,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, double amount, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(
              NumberFormat.simpleCurrency().format(amount),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildQuickChart(BuildContext context, double income, double expense) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = isDarkMode ? Colors.white12 : Colors.grey[100]!;
    
    if (income == 0 && expense == 0) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
        ),
        child: Center(child: Text(L10n.s('no_data_this_month') == 'no_data_this_month' ? 'Sin datos este mes' : L10n.s('no_data_this_month'), style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.grey))),
      );
    }
    
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: [
                  if (income > 0)
                    PieChartSectionData(
                      color: const Color(0xFF81C784),
                      value: income,
                      title: '',
                      radius: 20,
                    ),
                  if (expense > 0)
                    PieChartSectionData(
                      color: const Color(0xFFD4A5A5),
                      value: expense,
                      title: '',
                      radius: 20,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _chartLegend(context, L10n.s('income'), const Color(0xFF81C784), income),
              const SizedBox(height: 8),
              _chartLegend(context, L10n.s('expenses'), const Color(0xFFD4A5A5), expense),
            ],
          )
        ],
      ),
    );
  }

  Widget _chartLegend(BuildContext context, String label, Color color, double amount) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : Colors.grey)),
            Text(NumberFormat.simpleCurrency().format(amount), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
          ],
        )
      ],
    );
  }

  Widget _buildTransactionItem(BuildContext context, Entry entry) {
    final cat = AppState().getCategory(entry.categoryId);
    final isIncome = entry.type == 'income';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? Colors.white12 : Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cat.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(cat.icon, color: cat.color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.notes.isNotEmpty ? entry.notes : cat.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDarkMode ? Colors.white : Colors.black87)),
                const SizedBox(height: 4),
                Text(DateFormat('dd MMM yyyy').format(entry.date), style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${NumberFormat.simpleCurrency().format(entry.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isIncome ? Colors.green[400] : Colors.red[300],
            ),
          ),
        ],
      ),
    );
  }
}
