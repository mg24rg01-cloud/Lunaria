import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../utils/l10n.dart';
import 'dashboard_screen.dart';
import 'notebooks_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    AppState().budgetAlert.addListener(_onBudgetAlert);
  }

  @override
  void dispose() {
    AppState().budgetAlert.removeListener(_onBudgetAlert);
    super.dispose();
  }

  void _onBudgetAlert() {
    final alert = AppState().budgetAlert.value;
    if (alert != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(alert, style: TextStyle(color: Theme.of(context).cardColor)),
          backgroundColor: Colors.red[300],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
      // Clear alert so it doesn't show again if listener is re-added
      AppState().budgetAlert.value = null;
    }
  }

  final List<Widget> _screens = [
    const DashboardScreen(),
    const NotebooksScreen(),
    const ReportsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AppState().user,
      builder: (context, user, child) {
        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          bottomNavigationBar: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFFD4A5A5),
              unselectedItemColor: Colors.grey[400],
              selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              elevation: 0,
              items: [
                BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: L10n.s('start') == 'start' ? 'Inicio' : L10n.s('start')),
                BottomNavigationBarItem(icon: const Icon(Icons.book_outlined), activeIcon: const Icon(Icons.book), label: L10n.s('notebooks')),
                BottomNavigationBarItem(icon: const Icon(Icons.bar_chart_outlined), activeIcon: const Icon(Icons.bar_chart), label: L10n.s('reports')),
                BottomNavigationBarItem(icon: const Icon(Icons.person_outline), activeIcon: const Icon(Icons.person), label: L10n.s('profile')),
              ],
            ),
          ),
        );
      },
    );
  }
}
