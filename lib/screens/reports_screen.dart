import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../state/app_state.dart';
import '../models/schema.dart';
import '../utils/formatters.dart';
import '../utils/l10n.dart';
import 'notebook_detail_screen.dart';
import '../services/pdf_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color dustyPink = isDarkMode ? const Color(0xFFF49FB6) : const Color(0xFFD4A5A5);
    final Color softGray = isDarkMode ? Colors.white70 : const Color(0xFF8D8D8D);
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF2C2C37);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(L10n.s('reports'), style: TextStyle(color: dustyPink, fontWeight: FontWeight.w400)),
        actions: [
          IconButton(
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(L10n.s('generating')), duration: const Duration(seconds: 2))
              );
              try {
                await PdfService.generateAndSaveReport(
                  month: _selectedMonth,
                  allEntries: AppState().entries.value,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
                );
              }
            }, 
            icon: Icon(Icons.picture_as_pdf_outlined, color: softGray)
          ),
          IconButton(
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(L10n.s('generating')), duration: const Duration(seconds: 2))
              );
              try {
                await PdfService.generateAndSaveReport(
                  month: _selectedMonth,
                  allEntries: AppState().entries.value,
                  share: true,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
                );
              }
            }, 
            icon: Icon(Icons.share_outlined, color: softGray)
          ),
        ],
      ),
      body: ValueListenableBuilder<List<Entry>>(
        valueListenable: AppState().entries,
        builder: (context, entries, child) {
          // 1. Data Processing
          final currentMonthEntries = entries.where((e) => e.date.year == _selectedMonth.year && e.date.month == _selectedMonth.month).toList();
          final prevMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
          final prevMonthEntries = entries.where((e) => e.date.year == prevMonth.year && e.date.month == prevMonth.month).toList();

          double totalIncome = currentMonthEntries.where((e) => e.type == 'income').fold(0.0, (sum, e) => sum + e.amount);
          double totalExpense = currentMonthEntries.where((e) => e.type == 'expense').fold(0.0, (sum, e) => sum + e.amount);
          double prevExpense = prevMonthEntries.where((e) => e.type == 'expense').fold(0.0, (sum, e) => sum + e.amount);
          
          double expenseDiff = totalExpense - prevExpense;
          double expensePercent = prevExpense > 0 ? (expenseDiff / prevExpense) * 100 : 0;

          // Category mapping
          Map<String, double> catGastos = {};
          Map<String, double> prevCatGastos = {};
          for(var e in currentMonthEntries.where((e) => e.type == 'expense')) {
            catGastos[e.categoryId] = (catGastos[e.categoryId] ?? 0) + e.amount;
          }
          for(var e in prevMonthEntries.where((e) => e.type == 'expense')) {
            prevCatGastos[e.categoryId] = (prevCatGastos[e.categoryId] ?? 0) + e.amount;
          }
          final sortedCats = catGastos.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // 9. Filters (Top)
              _buildMonthSelector(),
              const SizedBox(height: 32),

              // 1. Resumen General
              // 1. Resumen General
              _buildGeneralSummary(context, totalIncome, totalExpense, expenseDiff, expensePercent),
              const SizedBox(height: 32),

              // 2. Insight Principal
              _buildMainInsight(totalExpense, prevExpense, totalIncome),
              const SizedBox(height: 32),

              // 3. Gastos por Categoría
              Text(L10n.s('budget'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...sortedCats.map((entry) {
                final cat = AppState().getCategory(entry.key);
                final prevVal = (prevCatGastos[entry.key] ?? 0).toDouble();
                final diff = entry.value - prevVal;
                final perc = prevVal > 0 ? (diff / prevVal) * 100 : 0.0;
                return _buildCategoryItem(context, cat, entry.value, totalExpense, diff, perc);
              }),
              const SizedBox(height: 32),

              // 4. Gráfica de Tendencia
              Text(L10n.s('expense_trend'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildTrendChart(entries),
              const SizedBox(height: 32),

               // 5. Alertas de Presupuesto (Dynamic)
              _buildBudgetAlerts(entries),
              const SizedBox(height: 32),

              // 6 & 7. Insights y Alertas
              const Text('Análisis Detallado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildDetailedInsights(currentMonthEntries, totalIncome, totalExpense),
              
              const SizedBox(height: 100),
            ],
          );
        }
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1)),
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4A5A5)),
        ),
        IconButton(
          onPressed: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1)),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildGeneralSummary(BuildContext context, double income, double expense, double diff, double perc) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E26) : const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Ingresos', income, Colors.green),
              _buildSummaryItem('Gastos', expense, const Color(0xFFD4A5A5)),
              _buildSummaryItem('Balance', income - expense, Colors.blue),
            ],
          ),
          const Divider(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(diff > 0 ? Icons.trending_up : Icons.trending_down, 
                color: diff > 0 ? Colors.red[300] : Colors.green[300], size: 16),
              const SizedBox(width: 8),
              Text(
                '${formatCurrency(diff.abs())} (${perc.abs().toStringAsFixed(1)}%) ${diff > 0 ? "más" : "menos"} que el mes pasado',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(formatCurrency(amount), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildMainInsight(double expense, double prevExpense, double income) {
    String title = '';
    String desc = '';
    IconData icon = Icons.lightbulb_outline;
    Color color = const Color(0xFFD4A5A5);

    if (expense > income) {
      title = 'Alerta de Balance';
      desc = 'Tus gastos han superado tus ingresos este mes. Revisa tus gastos fijos.';
      icon = Icons.warning_amber_rounded;
      color = Colors.red[300]!;
    } else if (expense > prevExpense * 1.2) {
      title = L10n.s('expenses_increasing');
      desc = L10n.s('trending_up');
      icon = Icons.trending_up;
    } else if (expense < prevExpense * 0.9) {
      title = L10n.s('well_done');
      desc = L10n.s('expenses_down');
      icon = Icons.thumb_up_off_alt;
      color = Colors.green[300]!;
    } else {
      title = L10n.s('stable_control');
      desc = L10n.s('stable_behavior');
      icon = Icons.check_circle_outline;
      color = Colors.blue[300]!;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).cardColor, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Theme.of(context).cardColor, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, Category cat, double amount, double total, double diff, double perc) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    double p = total > 0 ? (amount / total) : 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? Colors.white10 : const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(cat.icon, color: cat.color, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600))),
              Text(formatCurrency(amount), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: p,
            backgroundColor: isDarkMode ? Colors.white10 : const Color(0xFFF7F7FB),
            color: cat.color,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(p * 100).toStringAsFixed(1)}% ${L10n.s('of_total')}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Row(
                children: [
                  Icon(diff > 0 ? Icons.arrow_upward : Icons.arrow_downward, size: 10, color: diff > 0 ? Colors.red : Colors.green),
                  Text(' ${perc.abs().toStringAsFixed(0)}% ${L10n.s('vs_last_month')}', style: TextStyle(fontSize: 11, color: diff > 0 ? Colors.red : Colors.green)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<Entry> allEntries) {
    // Last 4 months
    List<FlSpot> spots = [];
    double maxVal = 1000;
    
    for (int i = 0; i < 4; i++) {
      DateTime m = DateTime(_selectedMonth.year, _selectedMonth.month - (3 - i));
      double total = allEntries
          .where((e) => e.date.year == m.year && e.date.month == m.month && e.type == 'expense')
          .fold(0.0, (sum, e) => sum + e.amount);
      spots.add(FlSpot(i.toDouble(), total));
      if (total > maxVal) maxVal = total;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 150,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: LineChart(LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                int midx = _selectedMonth.month - (3 - v.toInt());
                if (midx <= 0) midx += 12;
                return Text(_getMonthName(midx).substring(0, 3), style: const TextStyle(fontSize: 10, color: Colors.grey));
              }, interval: 1)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: const Color(0xFFD4A5A5),
                barWidth: 3,
                belowBarData: BarAreaData(show: true, color: const Color(0xFFD4A5A5).withOpacity(0.1)),
                dotData: const FlDotData(show: true),
              )
            ],
          )),
        ),
        const SizedBox(height: 8),
        Text(
          spots.last.y > spots[2].y ? '⚠️ Tus gastos van en aumento.' : '✅ Tus gastos se han mantenido estables.',
          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildBudgetAlerts(List<Entry> allEntries) {
    final now = _selectedMonth;
    final List<Widget> alertWidgets = [];
    
    // Buscar todos los planes mensuales para este mes/año
    for (var plan in AppState().monthlyPlans.value) {
      if (plan.month == now.month && plan.year == now.year) {
        plan.categoryLimits.forEach((catId, limit) {
          if (limit > 0) {
            final spent = allEntries
                .where((e) => e.categoryId == catId && e.type == 'expense' && e.date.month == now.month && e.date.year == now.year)
                .fold(0.0, (sum, e) => sum + e.amount);
            
            final cat = AppState().getCategory(catId);
            
            if (spent > limit) {
              alertWidgets.add(_buildAlertCard(
                'Presupuesto Excedido', 
                'Has gastado ${formatCurrency(spent)} en ${cat.name} (Límite: ${formatCurrency(limit)})', 
                Icons.error_outline, 
                Colors.red[300]!
              ));
            } else if (spent >= limit * 0.8) {
              alertWidgets.add(_buildAlertCard(
                'Cerca del Límite', 
                'Estás al ${(spent/limit*100).toStringAsFixed(0)}% de tu presupuesto en ${cat.name}', 
                Icons.warning_amber_rounded, 
                Colors.orange[300]!
              ));
            }
          }
        });
      }
    }

    if (alertWidgets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Alertas de Presupuesto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...alertWidgets,
      ],
    );
  }

  Widget _buildAlertCard(String title, String desc, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInsights(List<Entry> currentMonthEntries, double income, double expense) {
    final expenses = currentMonthEntries.where((e) => e.type == 'expense').toList();
    if (expenses.isEmpty && income == 0) {
      return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Text('Registra movimientos para ver análisis personalizados.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))));
    }

    final List<Widget> cards = [];

    // 1. Alerta Crítica (Gastos > Ingresos)
    if (expense > income && income > 0) {
      cards.add(_buildInsightCard('Alerta de Balance', 'Tus gastos superan tus ingresos por ${formatCurrency(expense - income)}.', Icons.error_outline, Colors.red[300]!));
    }

    // 2. Hábitos (Fin de semana)
    if (expenses.isNotEmpty) {
      double weekendSum = expenses.where((e) => e.date.weekday == DateTime.saturday || e.date.weekday == DateTime.sunday).fold(0.0, (sum, e) => sum + e.amount);
      double weekdaySum = expenses.where((e) => e.date.weekday < DateTime.saturday).fold(0.0, (sum, e) => sum + e.amount);
      
      if (weekendSum > weekdaySum && weekdaySum > 0) {
        cards.add(_buildInsightCard('Hábitos', 'Gastas más en fin de semana (${((weekendSum/expense)*100).toStringAsFixed(0)}% del total).', Icons.calendar_today, Colors.blue[300]!));
      } else if (weekdaySum > weekendSum && weekendSum > 0) {
        cards.add(_buildInsightCard('Hábitos', 'Tu mayor gasto ocurre entre semana.', Icons.business_center, Colors.indigo[300]!));
      }
    }

    // 3. Frecuencia y Gastos Hormiga
    if (expenses.length > 15) {
      final smallExpenses = expenses.where((e) => e.amount < 150).length;
      if (smallExpenses > expenses.length * 0.5) {
        cards.add(_buildInsightCard('Gastos Hormiga', 'Muchos movimientos pequeños detectados (\$$smallExpenses compras). Podrías ahorrar consolidando.', Icons.receipt_long, Colors.orange[300]!));
      }
    }

    // 4. Ahorro
    if (income > 0 && income > expense) {
      final savingsRate = ((income - expense) / income) * 100;
      if (savingsRate >= 20) {
        cards.add(_buildInsightCard('Excelente Ahorro', 'Has ahorrado el ${savingsRate.toStringAsFixed(0)}% de tus ingresos. ¡Meta lograda!', Icons.auto_awesome, Colors.green[300]!));
      }
    }

    return Column(
      children: [
        ...cards,
        
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionChip('Ver Suscripciones', Icons.sync, () {
          try {
            final notebook = AppState().notebooks.value.firstWhere(
              (n) => n.type.toLowerCase().contains('suscrip') || n.name.toLowerCase().contains('suscrip')
            );
            Navigator.push(context, MaterialPageRoute(builder: (context) => NotebookDetailScreen(notebook: notebook)));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuaderno de Suscripciones no encontrado')));
          }
        }),
        _buildActionChip('Ir a Presupuesto', Icons.account_balance_wallet, () {
          try {
            final notebook = AppState().notebooks.value.firstWhere(
              (n) => n.type.toLowerCase().contains('control') || n.type.toLowerCase().contains('mensual') || n.name.toLowerCase().contains('presupuesto')
            );
            Navigator.push(context, MaterialPageRoute(builder: (context) => NotebookDetailScreen(notebook: notebook)));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuaderno de Presupuesto no encontrado')));
          }
        }),
          ],
        )
      ],
    );
  }

  Widget _buildInsightCard(String title, String desc, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(desc, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: const Color(0xFFD4A5A5)),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFD4A5A5))),
    );
  }

  String _getMonthName(int month) {
    final months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return months[month - 1];
  }
}
