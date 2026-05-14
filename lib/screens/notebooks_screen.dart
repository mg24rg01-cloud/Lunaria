import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../models/schema.dart';
import '../utils/formatters.dart';
import 'add_transaction_screen.dart';
import 'notebook_detail_screen.dart';
import '../utils/l10n.dart';

class NotebooksScreen extends StatefulWidget {
  const NotebooksScreen({super.key});

  @override
  State<NotebooksScreen> createState() => _NotebooksScreenState();
}

class _NotebooksScreenState extends State<NotebooksScreen> {
  String _selectedCategory = 'Todos';
  String _searchQuery = '';
  List<Map<String, dynamic>> get categories => [
    {'name': L10n.s('all'), 'id': 'Todos'},
    {'name': L10n.s('active'), 'id': 'Activos'},
    {'name': L10n.s('archived'), 'id': 'Archivados'},
    {'name': L10n.s('goals'), 'id': 'Metas'},
  ];

  void _filterNotebooksByCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _clearSearch() {
    setState(() => _searchQuery = '');
  }

  void _showSearchDialog(BuildContext context) {
    String query = _searchQuery;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(L10n.s('search_notebooks'), style: const TextStyle(color: Color(0xFFD4A5A5))),
              content: TextField(
                autofocus: true,
                controller: TextEditingController(text: query),
                decoration: InputDecoration(
                  hintText: L10n.s('search_notebooks'),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[200]!)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4A5A5))),
                ),
                onChanged: (value) => setDialogState(() => query = value),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                TextButton(
                  onPressed: () {
                    _clearSearch();
                    Navigator.pop(context);
                  },
                  child: Text(L10n.s('clear') == 'clear' ? 'Limpiar' : L10n.s('clear'), style: const TextStyle(color: Color(0xFFD4A5A5))),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = query;
                    });
                    Navigator.pop(context);
                  },
                  child: Text(L10n.s('confirm'), style: const TextStyle(color: Color(0xFFD4A5A5), fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showScreenMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              _buildMenuItem(
                icon: Icons.add,
                title: 'Crear nuevo cuaderno',
                onTap: () {
                  Navigator.pop(context);
                  _showAddNotebookDialog(context);
                },
              ),
              _buildMenuItem(
                icon: Icons.clear_all,
                title: 'Limpiar filtros',
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedCategory = 'Todos';
                    _searchQuery = '';
                  });
                },
              ),
              _buildMenuItem(
                icon: Icons.info_outline,
                title: 'Ver detalles',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Selecciona una categoría o busca un cuaderno.', style: TextStyle(color: Theme.of(context).cardColor)),
                      backgroundColor: const Color(0xFFD4A5A5),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  static const Map<String, List<String>> _categoryFilters = {
    'Finanzas': ['finanzas', 'financiero', 'financiera'],
    'Ahorros': ['ahorro', 'ahorros'],
    'Viajes': ['viaje', 'viajes'],
    'Personales': ['personal', 'personales'],
  };

  List<Notebook> _getFilteredNotebooks(List<Notebook> notebooks) {
    final categoryFiltered = _selectedCategory == 'Todos'
        ? notebooks
        : notebooks.where((notebook) {
            if (_selectedCategory == 'Archivados') return false; // Simulated for now
            if (_selectedCategory == 'Metas') return notebook.targetAmount != null;
            if (_selectedCategory == 'Activos') return true; // Simulated for now
            return true;
          }).toList();

    if (_searchQuery.isEmpty) return categoryFiltered;
    final query = _searchQuery.toLowerCase();
    return categoryFiltered.where((notebook) {
      final name = notebook.name.toLowerCase();
      final type = notebook.type.toLowerCase();
      return name.contains(query) || type.contains(query);
    }).toList();
  }

  void _showAddTransactionSheet(BuildContext context, String notebookId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionScreen(initialNotebookId: notebookId),
    );
  }

  void _showNotebookMenu(BuildContext context, Notebook notebook) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              _buildMenuItem(
                icon: Icons.edit,
                title: 'Editar cuaderno',
                onTap: () {
                  Navigator.pop(context);
                  _showEditNotebookDialog(context, notebook);
                },
              ),
              _buildMenuItem(
                icon: Icons.share,
                title: 'Compartir',
                onTap: () {
                  Navigator.pop(context);
                  _shareNotebook(notebook);
                },
              ),
              _buildMenuItem(
                icon: Icons.archive,
                title: 'Archivar',
                onTap: () {
                  Navigator.pop(context);
                  _archiveNotebook(notebook);
                },
              ),
              const Divider(height: 1),
              _buildMenuItem(
                icon: Icons.delete,
                title: 'Eliminar',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, notebook);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color ?? const Color(0xFF8D8D8D), size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: color ?? const Color(0xFF8D8D8D),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNotebookDialog(BuildContext context, Notebook notebook) {
    String name = notebook.name;
    String selectedTemplate = notebook.type;
    double? targetAmount = notebook.targetAmount;
    
    final List<String> templates = [
      'Control Mensual', 'Suscripciones', 'Seguimiento de Ahorro', 'Deudas'
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Editar Cuaderno', style: TextStyle(color: Color(0xFFD4A5A5))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: TextEditingController(text: name),
                      onChanged: (val) => name = val,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[200]!)),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4A5A5))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedTemplate,
                      decoration: InputDecoration(
                        labelText: 'Plantilla',
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[200]!)),
                      ),
                      items: templates.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Color(0xFF8D8D8D))))).toList(),
                      onChanged: (val) {
                        if(val != null) setState(() => selectedTemplate = val);
                      },
                    ),
                    if (selectedTemplate == 'Seguimiento de Ahorro') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: TextEditingController(text: targetAmount?.toString() ?? ''),
                        onChanged: (val) => targetAmount = double.tryParse(val),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Meta de ahorro total',
                          labelStyle: const TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[200]!)),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4A5A5))),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                TextButton(
                  onPressed: () {
                    if (name.isNotEmpty) {
                      final updatedNotebook = Notebook(
                        id: notebook.id,
                        userId: notebook.userId,
                        name: name,
                        description: notebook.description,
                        type: selectedTemplate,
                        color: notebook.color,
                        icon: notebook.icon,
                        targetAmount: selectedTemplate == 'Seguimiento de Ahorro' ? targetAmount : null,
                      );
                      
                      final currentNotebooks = AppState().notebooks.value;
                      final index = currentNotebooks.indexWhere((n) => n.id == notebook.id);
                      if (index != -1) {
                        final updatedList = List<Notebook>.from(currentNotebooks);
                        updatedList[index] = updatedNotebook;
                        AppState().notebooks.value = updatedList;
                      }
                      
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Cuaderno actualizado', style: TextStyle(color: Theme.of(context).cardColor)),
                          backgroundColor: const Color(0xFFD4A5A5),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      );
                    }
                  },
                  child: const Text('Guardar', style: TextStyle(color: Color(0xFFD4A5A5), fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _shareNotebook(Notebook notebook) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Compartir "${notebook.name}" próximamente', style: TextStyle(color: Theme.of(context).cardColor)),
        backgroundColor: const Color(0xFFD4A5A5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _archiveNotebook(Notebook notebook) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${notebook.name}" archivado', style: TextStyle(color: Theme.of(context).cardColor)),
        backgroundColor: const Color(0xFFD4A5A5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Notebook notebook) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(L10n.s('delete_notebook'), style: const TextStyle(color: Colors.red)),
          content: Text('${L10n.s('delete_confirm')} "${notebook.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(L10n.s('cancel'), style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final currentNotebooks = AppState().notebooks.value;
                final updatedList = currentNotebooks.where((n) => n.id != notebook.id).toList();
                AppState().notebooks.value = updatedList;
                
                final currentEntries = AppState().entries.value;
                final updatedEntries = currentEntries.where((e) => e.notebookId != notebook.id).toList();
                AppState().entries.value = updatedEntries;
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(L10n.s('delete_notebook'), style: TextStyle(color: Theme.of(context).cardColor)),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              },
              child: Text(L10n.s('delete'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color dustyPink = isDarkMode ? const Color(0xFFF49FB6) : const Color(0xFFD4A5A5);
    final Color softGray = isDarkMode ? Colors.white70 : const Color(0xFF4F5060);
    final Color titleColor = isDarkMode ? Colors.white : const Color(0xFF1D1D26);
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF2C2C37);
    final Color background = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    L10n.s('notebooks'),
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  InkWell(
                    onTap: () => _showAddNotebookDialog(context),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: dustyPink, // Salmon pink
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                L10n.s('organize_finance'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: isDarkMode ? Colors.white70 : softGray,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF16161A) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDarkMode ? Colors.white10 : Colors.grey[200]!),
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: L10n.s('search_notebooks'),
                    hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.grey),
                    prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.white54 : Colors.grey),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    fillColor: Colors.transparent,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final categoryMap = categories[index];
                    final category = categoryMap['name'] as String;
                    final icon = categoryMap['icon'] as IconData?;
                    final isSelected = category == _selectedCategory;
                    
                    return GestureDetector(
                      onTap: () => _filterNotebooksByCategory(category),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFC792DF).withValues(alpha: 0.15) : (isDarkMode ? const Color(0xFF16161A) : Colors.white),
                          border: Border.all(color: isSelected ? const Color(0xFFC792DF).withValues(alpha: 0.5) : (isDarkMode ? Colors.white10 : const Color(0xFFE7E6EC))),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (icon != null) ...[
                              Icon(icon, size: 16, color: isSelected ? const Color(0xFFC792DF) : (isDarkMode ? Colors.white54 : const Color(0xFF8D8D8D))),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              category,
                              style: TextStyle(
                                color: isSelected ? (isDarkMode ? Colors.white : const Color(0xFFC792DF)) : (isDarkMode ? Colors.white54 : const Color(0xFF8D8D8D)),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ValueListenableBuilder<List<Notebook>>(
                  valueListenable: AppState().notebooks,
                  builder: (context, notebooks, child) {
                    return ValueListenableBuilder<List<Entry>>(
                      valueListenable: AppState().entries,
                      builder: (context, entries, child) {
                        final filteredNotebooks = _getFilteredNotebooks(notebooks);
                        return GridView.builder(
                          padding: const EdgeInsets.only(bottom: 120),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            crossAxisSpacing: 18,
                            mainAxisSpacing: 18,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: filteredNotebooks.length,
                          itemBuilder: (context, index) {
                            final nb = filteredNotebooks[index];
                            final nbEntries = entries.where((e) => e.notebookId == nb.id).toList();
                            double nbTotal = 0;
                            for (var e in nbEntries) {
                              if (e.type == 'income') nbTotal += e.amount;
                              if (e.type == 'expense') nbTotal -= e.amount;
                            }
                            return _NotebookCard(
                              notebook: nb,
                              amount: nbTotal,
                              transactionCount: nbEntries.length,
                              onMenuPressed: () => _showNotebookMenu(context, nb),
                              onAddTransaction: () => _showAddTransactionSheet(context, nb.id),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderActionButton(BuildContext context, IconData icon, void Function(BuildContext) onTap) {
    return InkWell(
      onTap: () => onTap(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF4F5060)),
      ),
    );
  }

  void _showAddNotebookDialog(BuildContext context) {
    String name = '';
    String selectedTemplate = 'Control Mensual';
    double? targetAmount;
    
    final List<String> templates = [
      'Control Mensual', 'Suscripciones', 'Seguimiento de Ahorro', 'Deudas'
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Nuevo Cuaderno', style: TextStyle(color: Color(0xFFD4A5A5))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (val) => name = val,
                      decoration: InputDecoration(
                        labelText: 'Nombre ej. Viaje Japón',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[200]!)),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4A5A5))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedTemplate,
                      decoration: InputDecoration(
                        labelText: 'Plantilla',
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[200]!)),
                      ),
                      items: templates.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Color(0xFF8D8D8D))))).toList(),
                      onChanged: (val) {
                        if(val != null) setState(() => selectedTemplate = val);
                      },
                    ),
                    if (selectedTemplate == 'Seguimiento de Ahorro') ...[
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: (val) => targetAmount = double.tryParse(val),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Meta de ahorro total',
                          labelStyle: const TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[200]!)),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4A5A5))),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                TextButton(
                  onPressed: () {
                    if (name.isNotEmpty) {
                      AppState().addNotebook(Notebook(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        userId: AppState().user.value?.id ?? 'guest',
                        name: name,
                        description: '',
                        type: selectedTemplate,
                        color: const Color(0xFFD4A5A5),
                        icon: Icons.book,
                        targetAmount: selectedTemplate == 'Seguimiento de Ahorro' ? targetAmount : null,
                        month: selectedTemplate == 'Control Mensual' ? DateTime.now().month : null,
                        year: selectedTemplate == 'Control Mensual' ? DateTime.now().year : null,
                      ));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Crear', style: TextStyle(color: Color(0xFFD4A5A5), fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }
}

class _NotebookCard extends StatelessWidget {
  final Notebook notebook;
  final double amount;
  final int transactionCount;
  final VoidCallback onMenuPressed;
  final VoidCallback onAddTransaction;

  const _NotebookCard({
    required this.notebook,
    required this.amount,
    required this.transactionCount,
    required this.onMenuPressed,
    required this.onAddTransaction,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color softGray = isDarkMode ? Colors.white70 : const Color(0xFF8D8D8D);
    final progress = AppState().getNotebookProgress(notebook.id);
    final progressLabel = _progressLabel();
    final footerLabel = notebook.type;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => NotebookDetailScreen(notebook: notebook)));
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: notebook.color.withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: notebook.color.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(notebook.icon, size: 22, color: notebook.color),
                  ),
                ),
                InkWell(
                  onTap: onMenuPressed,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white10 : const Color(0xFFF7F7FB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.more_vert, color: softGray, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              notebook.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDarkMode ? Colors.white : const Color(0xFF2C2C37),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatCurrency(amount),
              style: TextStyle(
                color: notebook.color,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$transactionCount transacciones',
              style: TextStyle(
                color: softGray,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            if (notebook.targetAmount != null) ...[
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white12 : const Color(0xFFF3F3F8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: notebook.color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                progressLabel,
                style: TextStyle(
                  color: notebook.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: Material(
                color: notebook.color,
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: onAddTransaction,
                  icon: Icon(Icons.add, size: 18, color: Theme.of(context).cardColor),
                  padding: const EdgeInsets.all(10),
                  tooltip: 'Nuevo movimiento',
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              footerLabel,
              style: TextStyle(
                color: softGray,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _progressLabel() {
    final progress = AppState().getNotebookProgress(notebook.id);
    final percent = (progress * 100).toStringAsFixed(0);
    if (notebook.type.toLowerCase().contains('ahorro')) {
      return '$percent% de la meta';
    }
    return '$percent% del presupuesto';
  }
}
