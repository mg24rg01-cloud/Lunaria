import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../services/csv_import_service.dart';
import '../models/schema.dart';
import '../utils/l10n.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final bool _faceIdEnabled = true;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color dustyPink = isDarkMode ? const Color(0xFFF49FB6) : const Color(0xFFD4A5A5);
    final Color softGray = isDarkMode ? Colors.white70 : const Color(0xFF8D8D8D);
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF2C2C37);
    return ValueListenableBuilder<User?>(
      valueListenable: AppState().user,
      builder: (context, user, child) {
        if (user == null) return const SizedBox.shrink();

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            children: [
          Text(L10n.s('profile'), style: TextStyle(color: dustyPink, fontSize: 24, fontWeight: FontWeight.w400)),
          const SizedBox(height: 48),

          Center(
            child: Column(
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: dustyPink.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: dustyPink.withOpacity(0.3), width: 2),
                  ),
                  child: Center(child: Text(user.name[0], style: TextStyle(color: dustyPink, fontSize: 40, fontWeight: FontWeight.w300))),
                ),
                const SizedBox(height: 24),
                Text(user.name, style: TextStyle(color: dustyPink, fontSize: 24, fontWeight: FontWeight.w400)),
                const SizedBox(height: 4),
                Text(user.email, style: TextStyle(color: softGray, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 48),

          Text(L10n.s('settings'), style: TextStyle(color: softGray, fontSize: 14, fontWeight: FontWeight.w400)),
          const SizedBox(height: 16),
          
          _buildSettingsTile(Icons.edit_outlined, L10n.s('change_nickname'), onTap: () => _showEditNicknameDialog(context)),
          _buildSettingsTile(
            _isDarkMode(user) ? Icons.dark_mode_outlined : Icons.light_mode_outlined, 
            '${L10n.s('theme')} (${_isDarkMode(user) ? L10n.s('dark') : L10n.s('light')})', 
            trailing: Switch(
              value: _isDarkMode(user),
              activeThumbColor: dustyPink,
              onChanged: (val) => AppState().updateProfile(theme: val ? 'dark' : 'light'),
            )
          ),
          _buildSettingsTile(Icons.language_outlined, L10n.s('language'), trailing: _buildLanguageDropdown(user)),
          _buildSettingsTile(Icons.upload_file_outlined, L10n.s('import_csv'), onTap: () => _handleCSVImport(context)),
          _buildSettingsTile(Icons.notifications_outlined, L10n.s('notifications'), onTap: () => _showNotificationsModal(context)),
          _buildSettingsTile(Icons.download_outlined, L10n.s('export_data'), onTap: () => _showExportModal(context)),
          _buildSettingsTile(Icons.delete_forever_outlined, L10n.s('clear_all_data'), color: Colors.red[300], onTap: () => _showClearDataDialog(context)),
          
          const SizedBox(height: 32),
          Center(
            child: TextButton(
              onPressed: () => _showLogoutDialog(context),
              child: Text(L10n.s('logout'), style: TextStyle(color: dustyPink, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
      },
    );
  }

  bool _isDarkMode(User user) => user.themePreference == 'dark';

  Widget _buildLanguageDropdown(User user) {
    const Map<String, String> languages = {
      'es': 'Español',
      'en': 'English',
      'zh': '中文',
    };

    return DropdownButton<String>(
      value: user.language,
      underline: const SizedBox(),
      items: languages.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: (val) {
        if (val != null) AppState().updateProfile(language: val);
      },
    );
  }

  void _showEditNicknameDialog(BuildContext context) {
    final user = AppState().user.value!;
    final controller = TextEditingController(text: user.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Apodo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nuevo apodo'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              AppState().updateProfile(name: controller.text);
              Navigator.pop(context);
            }, 
            child: const Text('Guardar')
          ),
        ],
      )
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas salir? Necesitarás tu contraseña para volver a entrar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              AppState().logout();
            }, 
            child: const Text('Salir', style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, {Widget? trailing, VoidCallback? onTap, Color? color}) {
    const Color softGray = Color(0xFF8D8D8D);
    final displayColor = color ?? softGray;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Row(
          children: [
            Icon(icon, color: displayColor, size: 24),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(color: displayColor, fontSize: 16, fontWeight: FontWeight.w400)),
            const Spacer(),
            trailing ?? Icon(Icons.chevron_right, color: displayColor, size: 20),
          ],
        ),
      ),
    );
  }


  Future<void> _handleCSVImport(BuildContext context) async {
    final accounts = AppState().accounts.value;
    final notebooks = AppState().notebooks.value;
    
    if (accounts.isEmpty || notebooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primero crea una cuenta y un cuaderno')));
      return;
    }

    try {
      // Usar la primera cuenta y cuaderno por defecto para la prueba rápida
      final entries = await CSVImportService().importCSV(
        notebookId: notebooks.first.id,
        accountId: accounts.first.id,
      );

      if (entries.isNotEmpty) {
        await AppState().addEntries(entries);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('¡Éxito! Se importaron ${entries.length} movimientos.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: Colors.red[300],
      ));
    }
  }


  void _showNotificationsModal(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color softGray = isDarkMode ? Colors.white70 : const Color(0xFF8D8D8D);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notificaciones', style: TextStyle(color: Color(0xFFD4A5A5), fontSize: 20, fontWeight: FontWeight.w400)),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: Text('Alertas de Presupuesto', style: TextStyle(color: softGray)),
                    value: true,
                    activeThumbColor: const Color(0xFFD4A5A5),
                    onChanged: (val) {},
                  ),
                  SwitchListTile(
                    title: Text('Recordatorios de Tarjetas', style: TextStyle(color: softGray)),
                    value: true,
                    activeThumbColor: const Color(0xFFD4A5A5),
                    onChanged: (val) {},
                  ),
                  SwitchListTile(
                    title: Text('Resumen Semanal', style: TextStyle(color: softGray)),
                    value: false,
                    activeThumbColor: const Color(0xFFD4A5A5),
                    onChanged: (val) {},
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  void _showExportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Exportar Datos', style: TextStyle(color: Color(0xFFD4A5A5), fontSize: 20, fontWeight: FontWeight.w400)),
              const SizedBox(height: 8),
              const Text('Tu información es 100% tuya. Descárgala en el formato que prefieras.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildExportFormatBtn(context, 'CSV', Icons.table_chart_outlined),
                  _buildExportFormatBtn(context, 'JSON', Icons.data_object),
                  _buildExportFormatBtn(context, 'PDF', Icons.picture_as_pdf_outlined),
                ],
              )
            ],
          ),
        );
      }
    );
  }

  Widget _buildExportFormatBtn(BuildContext context, String title, IconData icon) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Generando archivo $title...', style: TextStyle(color: Theme.of(context).cardColor)),
          backgroundColor: const Color(0xFFD4A5A5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ));
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4A5A5).withOpacity(0.3)),
            ),
            child: Icon(icon, color: const Color(0xFFD4A5A5)),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Color(0xFF8D8D8D))),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color softGray = isDarkMode ? Colors.white70 : const Color(0xFF8D8D8D);
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF2C2C37);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('⚠️ Borrar Datos', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Esta acción es irreversible.',
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Se borrarán permanentemente todos tus cuadernos, movimientos, cuentas, deudas y suscripciones.',
              style: TextStyle(color: softGray, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AppState().clearAllData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      )
    );
  }
}
