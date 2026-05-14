import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/schema.dart';
import '../state/app_state.dart';
import '../utils/formatters.dart';
import 'add_transaction_screen.dart';
import '../utils/l10n.dart';

class NotebookDetailScreen extends StatefulWidget {
  final Notebook notebook;

  const NotebookDetailScreen({super.key, required this.notebook});

  @override
  State<NotebookDetailScreen> createState() => _NotebookDetailScreenState();
}

class _NotebookDetailScreenState extends State<NotebookDetailScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
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
        iconTheme: IconThemeData(color: softGray),
        title: _isSearching 
          ? TextField(
              autofocus: true,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: L10n.s('search_movements'),
                hintStyle: TextStyle(color: softGray.withOpacity(0.5)),
                border: InputBorder.none,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            )
          : Text(widget.notebook.name, style: TextStyle(fontWeight: FontWeight.w400, color: dustyPink)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search), 
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchQuery = '';
            })
          ),
          PopupMenuButton<String>(
            iconColor: softGray,
            onSelected: (value) {
              if (value == 'delete') _confirmDeleteNotebook(context);
              if (value == 'edit') _showRenameNotebookDialog(context);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text(L10n.s('rename_notebook'))),
              PopupMenuItem(value: 'delete', child: Text(L10n.s('delete_notebook'), style: const TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionSheet(context),
        backgroundColor: dustyPink,
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: ValueListenableBuilder<List<Entry>>(
        valueListenable: AppState().entries,
        builder: (context, entries, child) {
          final isMonthlyControl = widget.notebook.type.toLowerCase().contains('mensual');
          
          List<Entry> monthEntries;
          if (isMonthlyControl) {
            monthEntries = entries.where((e) => 
              e.date.year == _selectedMonth.year && 
              e.date.month == _selectedMonth.month
            ).toList();
          } else {
            final nbEntries = entries.where((e) => e.notebookId == widget.notebook.id).toList();
            monthEntries = nbEntries.where((e) => e.date.year == _selectedMonth.year && e.date.month == _selectedMonth.month).toList();
          }
          
          final filteredEntries = _searchQuery.isEmpty 
            ? monthEntries 
            : monthEntries.where((e) => 
                e.notes.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                AppState().getCategory(e.categoryId).name.toLowerCase().contains(_searchQuery.toLowerCase())
              ).toList();
              
          return _buildTemplateView(context, filteredEntries);
        }
      ),
    );
  }

    Widget _buildTemplateView(BuildContext context, List<Entry> entries) {
    String t = widget.notebook.type.toLowerCase();
    if (t.contains('mensual')) return _buildMonthlyControl(context, entries);
    if (t.contains('ahorro')) return _buildSavingsGoal(context, entries);
    if (t.contains('suscripciones')) return _buildSubscriptions(context, entries);
    if (t.contains('deudas')) return _buildDeudas(context, entries);
    
    return _buildDailyLog(context, entries);
  }

  Widget _buildMonthlyControl(BuildContext context, List<Entry> entries) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          _buildMonthPicker(),
          TabBar(
            isScrollable: true,
            indicatorColor: widget.notebook.color,
            labelColor: widget.notebook.color,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(text: 'Planeación'),
              Tab(text: 'Presupuesto'),
              Tab(text: 'Registro'),
              Tab(text: 'Análisis'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPlanningSection(context, entries),
                _buildBudgetSection(context, entries),
                _buildRegistrySection(context, entries),
                _buildAnalysisSection(context, entries),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanningSection(BuildContext context, List<Entry> entries) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color softGray = isDarkMode ? Colors.white70 : const Color(0xFF8D8D8D);
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF2C2C37);
    return ValueListenableBuilder<List<MonthlyPlan>>(
      valueListenable: AppState().monthlyPlans,
      builder: (context, plans, child) {
        final plan = AppState().getMonthlyPlan(widget.notebook.id, _selectedMonth.month, _selectedMonth.year);
        
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Planifica tu mes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 8),
            Text('Define tus expectativas antes de empezar.', style: TextStyle(color: softGray, fontSize: 14)),
            const SizedBox(height: 32),
            
            _buildPlanningField(
              'Ingresos Esperados', 
              Icons.payments_outlined, 
              plan.expectedIncome,
              (val) {
                final dVal = double.tryParse(val) ?? 0;
                AppState().updateMonthlyPlan(MonthlyPlan(
                  id: plan.id,
                  notebookId: plan.notebookId,
                  month: plan.month,
                  year: plan.year,
                  expectedIncome: dVal,
                  targetSavings: plan.targetSavings,
                  categoryLimits: plan.categoryLimits,
                ));
              }
            ),
            const SizedBox(height: 24),
            _buildPlanningField(
              'Meta de Ahorro', 
              Icons.savings_outlined, 
              plan.targetSavings,
              (val) {
                final dVal = double.tryParse(val) ?? 0;
                AppState().updateMonthlyPlan(MonthlyPlan(
                  id: plan.id,
                  notebookId: plan.notebookId,
                  month: plan.month,
                  year: plan.year,
                  expectedIncome: plan.expectedIncome,
                  targetSavings: dVal,
                  categoryLimits: plan.categoryLimits,
                ));
              }
            ),
            
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.notebook.color, widget.notebook.color.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFD4A5A5).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Disponible para Gastar', style: TextStyle(color: Theme.of(context).cardColor, fontSize: 16)),
                      Builder(builder: (context) {
                        double realIngresos = entries.where((e) => e.type == 'income').fold(0.0, (sum, e) => sum + e.amount);
                        double realGastos = entries.where((e) => e.type == 'expense').fold(0.0, (sum, e) => sum + e.amount);
                        
                        // Lógica: Empezamos con lo planeado, pero si los ingresos reales superan lo planeado, sumamos el excedente.
                        // Y siempre restamos los gastos reales.
                        double budgetBase = plan.expectedIncome > realIngresos ? plan.expectedIncome : realIngresos;
                        double disponible = budgetBase - plan.targetSavings - realGastos;
                        
                        return Text(formatCurrency(disponible), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Theme.of(context).cardColor));
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Este es tu límite real de gasto para no afectar tu meta de ahorro.', style: TextStyle(fontSize: 11, color: Colors.white70, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan mensual guardado correctamente.')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C37),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Confirmar Plan Mensual'),
            )
          ],
        );
      }
    );
  }

  Widget _buildPlanningField(String label, IconData icon, double initialValue, Function(String) onChanged) {
    final controller = TextEditingController(text: initialValue > 0 ? initialValue.toString() : '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 12),
        Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus) onChanged(controller.text);
          },
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            onSubmitted: onChanged,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFFD4A5A5), size: 20),
              prefixText: '\$ ',
              hintText: '0.00',
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E26) : const Color(0xFFF7F7FB),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFD4A5A5))),
            ),
          ),
        ),
      ],
    );
  }

  void _handleCSVImport(BuildContext context) async {
    // Para importar, necesitamos saber a qué cuenta asignar los movimientos
    // Mostramos un diálogo rápido para elegir la cuenta
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar desde Banco'),
        content: const Text('Selecciona qué cuenta quieres usar para estos movimientos.'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final debitAcc = AppState().accounts.value.firstWhere((a) => a.type == 'debit', orElse: () => AppState().accounts.value.first);
              final count = await AppState().importFromCSV(widget.notebook.id, debitAcc.id);
              if (count > 0) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('¡Éxito! Se importaron $count movimientos.')));
              } else if (count == -1) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al leer el archivo CSV.')));
              }
            },
            child: const Text('Tarjeta de Débito'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final creditAcc = AppState().accounts.value.firstWhere((a) => a.type == 'credit', orElse: () => AppState().accounts.value.first);
              final count = await AppState().importFromCSV(widget.notebook.id, creditAcc.id);
              if (count > 0) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('¡Éxito! Se importaron $count movimientos.')));
              }
            },
            child: const Text('Tarjeta de Crédito'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteNotebook(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar cuaderno?'),
        content: const Text('Se borrarán todos los movimientos y datos asociados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              AppState().deleteNotebook(widget.notebook.id);
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Screen
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRenameNotebookDialog(BuildContext context) {
    String newName = widget.notebook.name;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar cuaderno'),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(hintText: widget.notebook.name),
          onChanged: (val) => newName = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (newName.isNotEmpty) {
                AppState().editNotebook(widget.notebook.id, Notebook(
                  id: widget.notebook.id,
                  userId: widget.notebook.userId,
                  name: newName,
                  description: widget.notebook.description,
                  type: widget.notebook.type,
                  icon: widget.notebook.icon,
                  color: widget.notebook.color,
                  targetAmount: widget.notebook.targetAmount,
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSection(BuildContext context, List<Entry> entries) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color softGray = isDarkMode ? Colors.white70 : const Color(0xFF8D8D8D);
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF2C2C37);
    return ValueListenableBuilder<List<MonthlyPlan>>(
      valueListenable: AppState().monthlyPlans,
      builder: (context, plans, child) {
        final plan = AppState().getMonthlyPlan(widget.notebook.id, _selectedMonth.month, _selectedMonth.year);
        final categories = AppState().categories.value.where((c) => c.type == 'expense').toList();

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Límites por Categoría', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 8),
            Text('Controla tus gastos estableciendo topes.', style: TextStyle(color: softGray, fontSize: 14)),
            const SizedBox(height: 24),
            ...categories.map((cat) {
              final limit = plan.categoryLimits[cat.id] ?? 0;
              final spent = entries.where((e) => e.categoryId == cat.id && e.type == 'expense').fold(0.0, (sum, e) => sum + e.amount);
              final remaining = limit - spent;
              final percent = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
              final isOver = limit > 0 && spent > limit;
              final isWarning = limit > 0 && spent >= limit * 0.8 && spent <= limit;

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isOver ? Colors.red.withOpacity(0.3) : (isWarning ? Colors.orange.withOpacity(0.3) : const Color(0xFFF0F0F0))),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(cat.icon, color: cat.color, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                          onPressed: () => _showEditLimitDialog(context, plan, cat),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: percent,
                      backgroundColor: const Color(0xFFF7F7FB),
                      color: isOver ? Colors.red : (isWarning ? Colors.orange : cat.color),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Gastado: ${formatCurrency(spent)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          limit > 0 ? 'Quedan: ${formatCurrency(remaining)}' : 'Sin límite', 
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isOver ? Colors.red : (isWarning ? Colors.orange : Colors.green))
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      }
    );
  }

  void _showEditLimitDialog(BuildContext context, MonthlyPlan plan, Category cat) {
    final controller = TextEditingController(text: (plan.categoryLimits[cat.id] ?? 0).toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Límite para ${cat.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: '\$ '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final newLimit = double.tryParse(controller.text) ?? 0;
              final newLimits = Map<String, double>.from(plan.categoryLimits);
              newLimits[cat.id] = newLimit;
              AppState().updateMonthlyPlan(MonthlyPlan(
                id: plan.id,
                notebookId: plan.notebookId,
                month: plan.month,
                year: plan.year,
                expectedIncome: plan.expectedIncome,
                targetSavings: plan.targetSavings,
                categoryLimits: newLimits,
              ));
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrySection(BuildContext context, List<Entry> entries) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (entries.isEmpty) 
          const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Text('No hay movimientos este mes.', style: TextStyle(color: Colors.grey)))),
        ...entries.map((e) => _buildDailyItem(e)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildAnalysisSection(BuildContext context, List<Entry> entries) {
    const Color dustyPink = Color(0xFFD4A5A5);
    // Ya no filtramos por notebookId aquí, usamos 'entries' que ya vienen interpretadas por el mes.
    
    double ingresos = entries.where((e) => e.type == 'income').fold(0.0, (sum, e) => sum + e.amount);
    double gastos = entries.where((e) => e.type == 'expense').fold(0.0, (sum, e) => sum + e.amount);
    double balance = ingresos - gastos;
    
    final plan = AppState().getMonthlyPlan(widget.notebook.id, _selectedMonth.month, _selectedMonth.year);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Totals Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildAnalysisCard('Ingresos', formatCurrency(ingresos), Colors.green),
            _buildAnalysisCard('Gastos', formatCurrency(gastos), dustyPink),
            _buildAnalysisCard('Balance', formatCurrency(balance), Colors.blue),
            _buildAnalysisCard('Meta Ahorro', formatCurrency(plan.targetSavings), Colors.orange),
          ],
        ),
        const SizedBox(height: 32),
        
        // Planned vs Real
        const Text('Planeado vs Real', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        _buildComparisonRow('Ingresos', plan.expectedIncome, ingresos),
        _buildComparisonRow('Ahorro', plan.targetSavings, balance > 0 ? balance : 0),
        
        const SizedBox(height: 32),
        const Text('Distribución', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 240,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 65,
                  sections: _buildAnalysisPieSections(entries),
                ),
              ),
            ),
            Column(
              children: [
                const Text('Total Gastos', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(formatCurrency(gastos), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF2C2C37))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Legend
        _buildChartLegend(entries),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildAnalysisCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, double planned, double actual) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey)),
              Text('${((actual/planned)*100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: LinearProgressIndicator(value: (actual/planned).clamp(0, 1), backgroundColor: const Color(0xFFF7F7FB), color: const Color(0xFFD4A5A5))),
              const SizedBox(width: 12),
              Text(formatCurrency(actual), style: const TextStyle(fontSize: 12)),
              const Text(' / ', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text(formatCurrency(planned), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildAnalysisPieSections(List<Entry> entries) {
    final gastos = entries.where((e) => e.type == 'expense').toList();
    if (gastos.isEmpty) return [PieChartSectionData(value: 100, color: const Color(0xFFF7F7FB), radius: 35, showTitle: false)];
    
    Map<String, double> catMap = {};
    for (var e in gastos) {
      catMap[e.categoryId] = (catMap[e.categoryId] ?? 0) + e.amount;
    }
    
    // Sort by amount
    final sortedEntries = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    // Palette harmonious with dusty pink
    final List<Color> themePalette = [
      const Color(0xFFD4A5A5), // Dusty Pink
      const Color(0xFF9E7E7E), // Muted Brown
      const Color(0xFFA5A5D4), // Soft Lavender
      const Color(0xFFA5D4CB), // Soft Teal
      const Color(0xFFD4C9A5), // Soft Gold
      const Color(0xFFC0A5D4), // Soft Purple
    ];
    
    int colorIdx = 0;
    return sortedEntries.map((kv) {
      final color = themePalette[colorIdx % themePalette.length];
      colorIdx++;
      return PieChartSectionData(
        value: kv.value,
        color: color,
        radius: 35,
        showTitle: false,
      );
    }).toList();
  }

  Widget _buildChartLegend(List<Entry> entries) {
    final gastos = entries.where((e) => e.type == 'expense').toList();
    if (gastos.isEmpty) return const SizedBox();
    
    Map<String, double> catMap = {};
    for (var e in gastos) {
      catMap[e.categoryId] = (catMap[e.categoryId] ?? 0) + e.amount;
    }
    final total = gastos.fold(0.0, (sum, e) => sum + e.amount);
    final sortedEntries = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final List<Color> themePalette = [
      const Color(0xFFD4A5A5),
      const Color(0xFF9E7E7E),
      const Color(0xFFA5A5D4),
      const Color(0xFFA5D4CB),
      const Color(0xFFD4C9A5),
      const Color(0xFFC0A5D4),
    ];

    return Column(
      children: sortedEntries.asMap().entries.map((entry) {
        final idx = entry.key;
        final kv = entry.value;
        final cat = AppState().getCategory(kv.key);
        final color = themePalette[idx % themePalette.length];
        final percentage = (kv.value / total * 100).toStringAsFixed(1);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 12),
              Expanded(child: Text(cat.name, style: const TextStyle(fontSize: 14, color: Color(0xFF4F5060)))),
              Text(formatCurrency(kv.value), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 8),
              Text('$percentage%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthPicker() {
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 12,
        itemBuilder: (context, index) {
          final isSelected = _selectedMonth.month == (index + 1);
          return GestureDetector(
            onTap: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, index + 1)),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFD4A5A5) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? const Color(0xFFD4A5A5) : const Color(0xFFEEEEEE)),
              ),
              child: Center(
                child: Text(
                  months[index], 
                  style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniStat(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(formatCurrency(amount), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildCategoryItem(Category cat, double amount, double total) {
    double percent = total > 0 ? amount / total : 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(cat.icon, color: cat.color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    Text(formatCurrency(amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: percent,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  color: cat.color,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCategoryProgress(String name, double total, double spent, IconData icon) {
    const Color dustyPink = Color(0xFFD4A5A5);
    const Color softGray = Color(0xFF8D8D8D);

    double percent = total > 0 ? spent / total : 0;
    if(percent > 1) percent = 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: dustyPink.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: dustyPink, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w400, color: softGray, fontSize: 14)),
                    Text(formatCurrency(spent), style: const TextStyle(color: dustyPink, fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: percent, backgroundColor: Colors.grey[100], color: dustyPink, minHeight: 4, borderRadius: BorderRadius.circular(2))
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDailyLog(BuildContext context, List<Entry> entries) {
    const Color dustyPink = Color(0xFFD4A5A5);
    const Color softGray = Color(0xFF8D8D8D);

    double totalGastos = entries.where((e) => e.type == 'expense').fold(0, (sum, e) => sum + e.amount);
    double ingresos = entries.where((e) => e.type == 'income').fold(0, (sum, e) => sum + e.amount);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text('Total Gastos', style: TextStyle(color: softGray, fontSize: 12)),
                const SizedBox(height: 8),
                Text(formatCurrency(totalGastos), style: const TextStyle(color: dustyPink, fontSize: 24, fontWeight: FontWeight.w300)),
              ],
            ),
            Container(width: 1, height: 40, color: Colors.grey[200]),
            Column(
              children: [
                const Text('Balance', style: TextStyle(color: softGray, fontSize: 12)),
                const SizedBox(height: 8),
                Text(formatCurrency(ingresos - totalGastos), style: TextStyle(color: (ingresos - totalGastos) >= 0 ? Colors.green : Colors.red, fontSize: 24, fontWeight: FontWeight.w300)),
              ],
            )
          ],
        ),
        const SizedBox(height: 56),
        const Text('Movimientos', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 16, color: softGray)),
        const SizedBox(height: 24),
        if (entries.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('No hay movimientos aún', style: TextStyle(color: Colors.grey)))),
        ...entries.map((e) => _buildDailyItem(e))
      ],
    );
  }

  Widget _buildDailyItem(Entry e) {
    const Color dustyPink = Color(0xFFD4A5A5);
    const Color softGray = Color(0xFF8D8D8D);
    final cat = AppState().getCategory(e.categoryId);
    String prefix = e.type == 'expense' ? '-' : '+';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: InkWell(
        onLongPress: () => _showAddTransactionSheet(context, entry: e),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: dustyPink.withOpacity(0.05), borderRadius: BorderRadius.circular(16)), child: Icon(cat.icon, color: dustyPink, size: 20)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.notes, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 16, color: softGray)),
                  Text(AppState().formatDate(e.date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$prefix${formatCurrency(e.amount)}', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: e.type == 'expense' ? softGray : Colors.green)),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert, size: 14, color: Colors.grey),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') _showAddTransactionSheet(context, entry: e);
                    if (value == 'delete') AppState().deleteEntry(e.id);
                  },
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsGoal(BuildContext context, List<Entry> entries) {
    const Color dustyPink = Color(0xFFD4A5A5);
    const Color softGray = Color(0xFF8D8D8D);

    double saved = entries.where((e) => e.type == 'income').fold(0.0, (sum, e) => sum + e.amount) - 
                   entries.where((e) => e.type == 'expense').fold(0.0, (sum, e) => sum + e.amount);
    
    double target = widget.notebook.targetAmount ?? 0;
    double percent = target > 0 ? saved / target : 0;
    if(percent > 1) percent = 1;
    if(percent < 0) percent = 0;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      children: [
        const Center(child: Text('Progreso de Meta', style: TextStyle(color: softGray, fontSize: 16))),
        const SizedBox(height: 32),
        Center(child: Text(formatCurrency(saved), style: const TextStyle(color: dustyPink, fontSize: 64, fontWeight: FontWeight.w300, letterSpacing: -1.5))),
        if (target > 0) Center(child: Text('de ${formatCurrency(target)}', style: const TextStyle(color: softGray, fontSize: 14))),
        const SizedBox(height: 48),
        LinearProgressIndicator(value: percent, backgroundColor: Colors.grey[100], color: dustyPink, minHeight: 8, borderRadius: BorderRadius.circular(4)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${(percent * 100).toStringAsFixed(0)}% logrado', style: const TextStyle(color: dustyPink, fontSize: 12, fontWeight: FontWeight.bold)),
            if (target > 0) Text('Faltan: ${formatCurrency(target - saved)}', style: const TextStyle(color: softGray, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 56),
        const Text('Historial de Ahorro', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 16, color: softGray)),
        const SizedBox(height: 24),
        if(entries.isEmpty) const Center(child: Text('Registra ingresos para ver tu progreso', style: TextStyle(color: Colors.grey))),
        ...entries.map((e) => _buildDailyItem(e))
      ],
    );
  }

  Widget _buildBudget(BuildContext context, List<Entry> entries) {
    const Color dustyPink = Color(0xFFD4A5A5);
    const Color softGray = Color(0xFF8D8D8D);
    
    double totalBudget = widget.notebook.targetAmount ?? 0;
    double totalSpent = entries.where((e) => e.type == 'expense').fold(0.0, (sum, e) => sum + e.amount);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      children: [
        const Text('Presupuesto vs Gasto Real', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 16, color: softGray)),
        const SizedBox(height: 32),
        _buildCategoryProgress('General', totalBudget, totalSpent, Icons.pie_chart),
        const SizedBox(height: 40),
        const Text('Desglose por Categoría', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 16, color: softGray)),
        const SizedBox(height: 24),
        ...entries.where((e) => e.type == 'expense').map((e) => _buildDailyItem(e)),
      ],
    );
  }

  Widget _buildSubscriptions(BuildContext context, List<Entry> entries) {
    const Color dustyPink = Color(0xFFD4A5A5);
    const Color softGray = Color(0xFF8D8D8D);
    
    return ValueListenableBuilder<List<Subscription>>(
      valueListenable: AppState().subscriptions,
      builder: (context, subs, child) {
        final notebookSubs = subs.where((s) => s.notebookId == widget.notebook.id).toList();
        
        double monthlyTotal = notebookSubs.where((s) => s.isActive).fold(0.0, (sum, s) => sum + s.monthlyEquivalent);
        double yearlyTotal = monthlyTotal * 12;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: [
            // 1. Intelligent Dashboard Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C2C37), Color(0xFF4F5060)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('IMPACTO MENSUAL NORMALIZADO', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Text(formatCurrency(monthlyTotal), style: TextStyle(color: Theme.of(context).cardColor, fontSize: 36, fontWeight: FontWeight.w300, letterSpacing: -1)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildImpactItem('Anual', formatCurrency(yearlyTotal)),
                      _buildImpactItem('Suscripciones', notebookSubs.length.toString()),
                      _buildImpactItem('Activas', notebookSubs.where((s) => s.isActive).length.toString()),
                    ],
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            const Text('Añadir nueva suscripción', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF2C2C37))),
            const SizedBox(height: 16),
            _buildQuickAddGrid(context),
            
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Gestión Automática', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF2C2C37))),
                Text('${notebookSubs.length} configuradas', style: const TextStyle(color: softGray, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 20),
            if (notebookSubs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text('Registra una suscripción para que la app la gestione por ti.', style: TextStyle(color: Colors.grey, fontSize: 14, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                ),
              ),
            ...notebookSubs.map((s) => _buildSubscriptionTile(context, s)),
            
            const SizedBox(height: 40),
            const Text('Historial de Cobros Reales', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF2C2C37))),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              const Center(child: Text('No hay cobros registrados aún.', style: TextStyle(color: Colors.grey, fontSize: 12))),
            ...entries.map((e) => _buildDailyItem(e)),
            const SizedBox(height: 100),
          ],
        );
      }
    );
  }

  Widget _buildImpactItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: Theme.of(context).cardColor, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildQuickAddGrid(BuildContext context) {
    final List<Map<String, dynamic>> popularApps = [
      {'name': 'Netflix', 'color': const Color(0xFFE50914), 'icon': Icons.movie},
      {'name': 'Spotify', 'color': const Color(0xFF1DB954), 'icon': Icons.music_note},
      {'name': 'Disney+', 'color': const Color(0xFF113CCF), 'icon': Icons.video_collection},
      {'name': 'Prime Video', 'color': const Color(0xFF00A8E1), 'icon': Icons.tv},
      {'name': 'Apple Music', 'color': const Color(0xFFFA2D48), 'icon': Icons.apple},
      {'name': 'Personalizada', 'color': const Color(0xFF8D8D8D), 'icon': Icons.add_circle_outline, 'isCustom': true},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: popularApps.length,
        itemBuilder: (context, index) {
          final app = popularApps[index];
          return GestureDetector(
            onTap: () {
              if (app['isCustom'] == true) {
                _showAddSubscriptionDialog(context, '', Colors.grey, Icons.star_border);
              } else {
                _showAddSubscriptionDialog(context, app['name'], app['color'], app['icon']);
              }
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF0F0F0)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(app['icon'], color: app['color'], size: 24),
                  const SizedBox(height: 8),
                  Text(app['name'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF4F5060)), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionTile(BuildContext context, Subscription sub) {
    final daysUntil = sub.nextBillingDate.difference(DateTime.now()).inDays;
    final isClose = daysUntil >= 0 && daysUntil <= 3;
    
    IconData subIcon = Icons.sync;
    if (sub.name.toLowerCase().contains('netflix')) {
      subIcon = Icons.movie;
    } else if (sub.name.toLowerCase().contains('spotify')) subIcon = Icons.music_note;
    else if (sub.name.toLowerCase().contains('disney')) subIcon = Icons.video_collection;
    else if (sub.name.toLowerCase().contains('prime')) subIcon = Icons.tv;
    else if (sub.name.toLowerCase().contains('apple')) subIcon = Icons.apple;
    else if (sub.classification != null) {
      switch (sub.classification) {
        case 'Entretenimiento': subIcon = Icons.movie; break;
        case 'Educación': subIcon = Icons.school; break;
        case 'Productividad': subIcon = Icons.bolt; break;
        case 'Bienestar': subIcon = Icons.spa; break;
        case 'Servicios': subIcon = Icons.lightbulb; break;
        case 'Membresías': subIcon = Icons.card_membership; break;
        case 'Personal': subIcon = Icons.person; break;
        default: subIcon = Icons.more_horiz;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isClose ? const Color(0xFFD4A5A5).withOpacity(0.3) : const Color(0xFFF5F5F5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (sub.isActive ? const Color(0xFFD4A5A5) : Colors.grey).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(subIcon, color: sub.isActive ? const Color(0xFFD4A5A5) : Colors.grey, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: sub.isActive ? const Color(0xFF2C2C37) : Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  'Próximo cobro: ${AppState().formatDate(sub.nextBillingDate)}', 
                  style: TextStyle(color: isClose ? const Color(0xFFD4A5A5) : Colors.grey, fontSize: 12, fontWeight: isClose ? FontWeight.bold : FontWeight.normal)
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatCurrency(sub.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C2C37))),
              Text(sub.frequency == 'monthly' ? 'al mes' : 'al año', style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
          const SizedBox(width: 10),
          Switch(
            value: sub.isActive, 
            activeThumbColor: const Color(0xFFD4A5A5),
            onChanged: (val) => AppState().toggleSubscription(sub.id),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
            onPressed: () => AppState().deleteSubscription(sub.id),
          )
        ],
      ),
    );
  }

  void _showAddSubscriptionDialog(BuildContext context, String initialAppName, Color appColor, IconData appIcon) {
    String currentAppName = initialAppName;
    double amount = 0;
    String freq = 'monthly';
    String classification = 'Entretenimiento';
    DateTime billingDate = DateTime.now().add(const Duration(days: 1));
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Icon(appIcon, color: appColor),
                  const SizedBox(width: 12),
                  Text(initialAppName.isEmpty ? 'Nueva suscripción' : 'Configurar $initialAppName', style: const TextStyle(fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('La app registrará este gasto automáticamente según el periodo.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 20),
                    if (initialAppName.isEmpty) ...[
                      TextField(
                        onChanged: (val) => currentAppName = val,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del servicio',
                          hintText: 'Ej. Gimnasio, Seguro, etc.',
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFEEEEEE))),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4A5A5))),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: classification,
                        decoration: const InputDecoration(labelText: 'Clasificación'),
                        items: const [
                          DropdownMenuItem(value: 'Entretenimiento', child: Text('Entretenimiento')),
                          DropdownMenuItem(value: 'Educación', child: Text('Educación')),
                          DropdownMenuItem(value: 'Productividad', child: Text('Productividad')),
                          DropdownMenuItem(value: 'Bienestar', child: Text('Bienestar')),
                          DropdownMenuItem(value: 'Servicios', child: Text('Servicios')),
                          DropdownMenuItem(value: 'Membresías', child: Text('Membresías')),
                          DropdownMenuItem(value: 'Personal', child: Text('Personal')),
                          DropdownMenuItem(value: 'Otros', child: Text('Otros')),
                        ],
                        onChanged: (val) => setState(() => classification = val!),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      onChanged: (val) => amount = double.tryParse(val) ?? 0,
                      decoration: const InputDecoration(
                        labelText: 'Monto del pago',
                        prefixText: '\$ ',
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFEEEEEE))),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4A5A5))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: freq,
                      decoration: const InputDecoration(labelText: 'Frecuencia de cobro'),
                      items: const [
                        DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
                        DropdownMenuItem(value: 'yearly', child: Text('Anual')),
                      ],
                      onChanged: (val) => setState(() => freq = val!),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context, 
                          initialDate: billingDate, 
                          firstDate: DateTime.now(), 
                          lastDate: DateTime.now().add(const Duration(days: 365))
                        );
                        if (picked != null) setState(() => billingDate = picked);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Próximo cobro:', style: TextStyle(color: Colors.grey)),
                            Text(AppState().formatDate(billingDate), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD4A5A5))),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                TextButton(
                  onPressed: () {
                    if (amount > 0) {
                      final categoryId = AppState().categories.value.firstWhere(
                        (c) => c.name.toLowerCase().contains('suscrip'), 
                        orElse: () => AppState().categories.value.first
                      ).id;
                      
                      final accountId = AppState().accounts.value.firstWhere(
                        (a) => a.type == 'debit', 
                        orElse: () => AppState().accounts.value.first
                      ).id;

                      AppState().addSubscription(Subscription(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        notebookId: widget.notebook.id,
                        name: currentAppName.isEmpty ? 'Suscripción' : currentAppName,
                        amount: amount,
                        frequency: freq,
                        nextBillingDate: billingDate,
                        categoryId: categoryId,
                        accountId: accountId,
                        classification: initialAppName.isEmpty ? classification : null,
                      ));
                      
                      Navigator.pop(context);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Suscripción activada. Se cobrará automáticamente.'),
                          backgroundColor: Color(0xFFD4A5A5),
                        )
                      );
                    }
                  },
                  child: const Text('Activar Automático', style: TextStyle(color: Color(0xFFD4A5A5), fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildIncome(BuildContext context, List<Entry> entries) {
    const Color dustyPink = Color(0xFFD4A5A5);
    const Color softGray = Color(0xFF8D8D8D);
    double total = entries.where((e) => e.type == 'income').fold(0.0, (sum, e) => sum + e.amount);
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      children: [
        Column(
          children: [
            const Text('Total Ingresos', style: TextStyle(color: softGray, fontSize: 16)),
            const SizedBox(height: 16),
            Text(formatCurrency(total), style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w300, color: dustyPink, letterSpacing: -1.5)),
          ],
        ),
        const SizedBox(height: 56),
        const Text('Historial', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 16, color: softGray)),
        const SizedBox(height: 24),
        if(entries.where((e) => e.type == 'income').isEmpty) const Center(child: Text('No hay ingresos registrados', style: TextStyle(color: Colors.grey))),
        ...entries.where((e) => e.type == 'income').map((e) => _buildDailyItem(e))
      ],
    );
  }

  Widget _buildFreeTemplate(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dashboard_customize, size: 64, color: Colors.grey[200]),
          const SizedBox(height: 24),
          const Text('Plantilla Libre', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: Color(0xFFD4A5A5))),
          const SizedBox(height: 8),
          const Text('Añade y arrastra bloques para armar\ntu estructura ideal.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8D8D8D))),
        ],
      ),
    );
  }

  void _showAddTransactionSheet(BuildContext context, {Entry? entry}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionScreen(initialNotebookId: widget.notebook.id, entry: entry),
    );
  }
  Widget _buildDeudas(BuildContext context, List<Entry> entries) {
    return ValueListenableBuilder<List<Debt>>(
      valueListenable: AppState().debts,
      builder: (context, allDebts, child) {
        final nbDebts = allDebts.where((d) => d.notebookId == widget.notebook.id).toList();
        
        double totalDeuda = nbDebts.fold(0.0, (sum, d) => sum + d.currentBalance);
        double totalPagosMensuales = nbDebts.fold(0.0, (sum, d) => sum + d.minimumPayment);
        
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Resumen Global
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C37),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  const Text('Deuda Total Acumulada', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(formatCurrency(totalDeuda), style: TextStyle(color: Theme.of(context).cardColor, fontSize: 36, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStatWhite('Pago Mensual', formatCurrency(totalPagosMensuales)),
                      Container(width: 1, height: 30, color: Colors.white12),
                      _buildMiniStatWhite('Deudas Activas', nbDebts.length.toString()),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Text('Estrategias Recomendadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C2C37))),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildStrategyCard('Bola de Nieve', 'Paga primero la deuda más pequeña para ganar motivación.', Icons.ac_unit, Colors.blue),
                  _buildStrategyCard('Avalancha', 'Paga primero la de mayor interés para ahorrar dinero.', Icons.speed, Colors.orange),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tus Deudas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C2C37))),
                TextButton.icon(
                  onPressed: () => _showAddDebtDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Añadir'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFD4A5A5)),
                )
              ],
            ),
            const SizedBox(height: 16),
            if (nbDebts.isEmpty) 
              const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Text('No tienes deudas registradas.', style: TextStyle(color: Colors.grey))))
            else
              ...nbDebts.map((d) => _buildDebtCard(context, d)),
            
            const SizedBox(height: 100),
          ],
        );
      }
    );
  }

  Widget _buildMiniStatWhite(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildStrategyCard(String title, String desc, IconData icon, Color color) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard(BuildContext context, Debt d) {
    final percent = d.progress;
    final isRisk = d.interestRate > 30; // Ejemplo de alerta
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2C2C37))),
                  Text(d.type.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isRisk ? Colors.red : Colors.green).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isRisk ? 'Interés Alto' : 'Bajo Control', 
                  style: TextStyle(color: isRisk ? Colors.red : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Saldo Pendiente', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(formatCurrency(d.currentBalance), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFFD4A5A5))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Pago Mínimo', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(formatCurrency(d.minimumPayment), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: const Color(0xFFF7F7FB),
            color: const Color(0xFFD4A5A5),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(percent * 100).toStringAsFixed(0)}% Pagado', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              Text('Original: ${formatCurrency(d.totalAmount)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDebtDetail('Interés Anual', '${d.interestRate}%'),
              _buildDebtDetail('Fecha de Pago', AppState().formatDate(d.dueDate)),
              ElevatedButton(
                onPressed: () => _showRegisterPaymentDialog(context, d),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4A5A5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Registrar Pago'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebtDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  void _showAddDebtDialog(BuildContext context) {
    String name = '';
    double total = 0;
    double balance = 0;
    double interest = 0;
    double minPay = 0;
    DateTime date = DateTime.now().add(const Duration(days: 7));
    String type = 'Tarjeta';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Añadir Deuda'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(decoration: const InputDecoration(labelText: 'Nombre (ej. Visa BBVA)'), onChanged: (v) => name = v),
                  TextField(decoration: const InputDecoration(labelText: 'Monto Total Original'), keyboardType: TextInputType.number, onChanged: (v) => total = double.tryParse(v) ?? 0),
                  TextField(decoration: const InputDecoration(labelText: 'Saldo Actual'), keyboardType: TextInputType.number, onChanged: (v) => balance = double.tryParse(v) ?? 0),
                  TextField(decoration: const InputDecoration(labelText: 'Interés Anual (%)'), keyboardType: TextInputType.number, onChanged: (v) => interest = double.tryParse(v) ?? 0),
                  TextField(decoration: const InputDecoration(labelText: 'Pago Mínimo'), keyboardType: TextInputType.number, onChanged: (v) => minPay = double.tryParse(v) ?? 0),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => date = picked);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Fecha de pago:', style: TextStyle(color: Colors.grey)),
                          Text(AppState().formatDate(date), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD4A5A5))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              TextButton(
                onPressed: () {
                  if (name.isNotEmpty) {
                    AppState().addDebt(Debt(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      notebookId: widget.notebook.id,
                      name: name,
                      totalAmount: total,
                      currentBalance: balance,
                      interestRate: interest,
                      minimumPayment: minPay,
                      dueDate: date,
                      type: type,
                    ));
                    Navigator.pop(context);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showRegisterPaymentDialog(BuildContext context, Debt d) {
    double amount = d.minimumPayment;
    bool isExtra = false;
    
    // Cálculo educativo
    double monthlyInterest = d.monthlyInterestAmount;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          double capital = (amount - monthlyInterest).clamp(0, amount);
          
          return AlertDialog(
            title: Text('Registrar Pago: ${d.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Monto del Pago', prefixText: '\$ '),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: amount.toString()),
                  onChanged: (v) {
                    setState(() {
                      amount = double.tryParse(v) ?? 0;
                    });
                  },
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      _buildPaymentSplitRow('Interés Mensual', monthlyInterest, Colors.red[300]!),
                      const SizedBox(height: 8),
                      _buildPaymentSplitRow('Reducción de Deuda', capital, Colors.green[300]!),
                      const Divider(),
                      Text(
                        amount <= monthlyInterest 
                          ? '⚠️ Tu pago no reduce la deuda.' 
                          : '¡Genial! Estás reduciendo tu deuda.',
                        style: TextStyle(fontSize: 11, color: amount <= monthlyInterest ? Colors.red : Colors.green, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              TextButton(
                onPressed: () async {
                  // 1. Actualizar saldo de deuda
                  final updatedDebt = Debt(
                    id: d.id,
                    notebookId: d.notebookId,
                    name: d.name,
                    totalAmount: d.totalAmount,
                    currentBalance: (d.currentBalance - (amount - monthlyInterest)).clamp(0, d.totalAmount),
                    interestRate: d.interestRate,
                    minimumPayment: d.minimumPayment,
                    dueDate: d.dueDate,
                    type: d.type,
                    status: (d.currentBalance - (amount - monthlyInterest)) <= 0 ? 'paid' : 'active',
                  );
                  await AppState().updateDebt(updatedDebt);
                  
                  // 2. Registrar como gasto en el sistema global
                  final debtCategory = AppState().categories.value.firstWhere(
                    (c) => c.name.toLowerCase().contains('deuda'),
                    orElse: () => AppState().categories.value.first,
                  );

                  final entry = Entry(
                    id: 'debt_pay_${DateTime.now().millisecondsSinceEpoch}',
                    notebookId: widget.notebook.id,
                    accountId: AppState().accounts.value.first.id, // Default account
                    type: 'expense',
                    amount: amount,
                    categoryId: debtCategory.id,
                    date: DateTime.now(),
                    notes: 'Pago de deuda: ${d.name} (${formatCurrency(capital)} a capital)',
                    tags: ['Deuda'],
                  );
                  await AppState().addEntry(entry);
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pago registrado y sincronizado con tus gastos.')));
                },
                child: const Text('Confirmar Pago'),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildPaymentSplitRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(formatCurrency(amount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ],
    );
  }
}
