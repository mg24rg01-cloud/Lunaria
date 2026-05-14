import 'package:flutter/material.dart';
import 'templates_screen.dart';
import '../models/schema.dart'; 

class TemplateDetailScreen extends StatelessWidget {
  final String title;
  final Color color;
  final TemplateType type;

  const TemplateDetailScreen({super.key, required this.title, required this.color, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: color.withOpacity(0.1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Editor de Plantilla', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('Guardar', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16))
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: color, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildTemplateContent(context),
          const SizedBox(height: 40),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Text('Agregar nuevo campo', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTemplateContent(BuildContext context) {
    switch (type) {
      case TemplateType.mensual:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldMock(context, 'Mes y Año', Icons.calendar_today, 'Selector Automático'),
            const SizedBox(height: 16),
            _buildSectionHeader('Sección de Ingresos'),
            _buildFieldMock(context, 'Lista de Ingresos', Icons.list, 'Nombre, Monto, Fecha, Categoría'),
            _buildFieldMock(context, 'Total de Ingresos', Icons.functions, 'Cálculo Automático', isAuto: true),
            const SizedBox(height: 16),
            _buildSectionHeader('Sección de Gastos'),
            _buildFieldMock(context, 'Lista de Gastos', Icons.list, 'Nombre, Monto, Categoría, Fecha, Notas'),
            _buildFieldMock(context, 'Total de Gastos', Icons.functions, 'Cálculo Automático', isAuto: true),
            const SizedBox(height: 16),
            _buildSectionHeader('Ahorro y Balance'),
            _buildFieldMock(context, 'Ahorro Objetivo', Icons.flag, 'Campo Numérico'),
            _buildFieldMock(context, 'Balance Automático', Icons.account_balance_wallet, 'Ingresos - Gastos', isAuto: true),
          ],
        );
      case TemplateType.diario:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldMock(context, 'Fecha', Icons.today, 'Por defecto: Hoy', isAuto: true),
            _buildFieldMock(context, 'Categoría', Icons.category, 'Selección Rápida'),
            _buildFieldMock(context, 'Monto', Icons.attach_money, 'Teclado Rápido'),
            _buildFieldMock(context, 'Nota Opcional', Icons.notes, 'Texto Breve'),
            const SizedBox(height: 16),
            _buildFieldMock(context, 'Botón Rápido', Icons.flash_on, 'Guardar en < 5s', isAuto: true),
            _buildFieldMock(context, 'Totales', Icons.functions, 'Suma Automática', isAuto: true),
          ],
        );
      case TemplateType.ahorro:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldMock(context, 'Nombre de la Meta', Icons.flag, 'Texto'),
            _buildFieldMock(context, 'Monto Objetivo', Icons.monetization_on, 'Número'),
            _buildFieldMock(context, 'Fecha Límite', Icons.event, 'Selector de Fecha'),
            _buildFieldMock(context, 'Barra de Progreso', Icons.linear_scale, 'Visual', isAuto: true),
            const SizedBox(height: 16),
            _buildSectionHeader('Aportaciones'),
            _buildFieldMock(context, 'Historial', Icons.history, 'Lista de aportaciones'),
          ],
        );
      case TemplateType.presupuesto:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldMock(context, 'Lista de Categorías', Icons.category, 'Texto'),
            _buildFieldMock(context, 'Presupuesto Asignado', Icons.account_balance, 'Número'),
            _buildFieldMock(context, 'Gasto Real', Icons.money_off, 'Cálculo Automático', isAuto: true),
            _buildFieldMock(context, 'Diferencia / Alertas', Icons.warning, 'Indicador Verde/Rojo', isAuto: true),
          ],
        );
      case TemplateType.comparacion:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldMock(context, 'Selector de Periodos', Icons.date_range, 'Mes/Año Múltiple'),
            _buildFieldMock(context, 'Gráfico de Barras', Icons.bar_chart, 'Generado', isAuto: true),
            _buildFieldMock(context, 'Insights Automáticos', Icons.lightbulb, 'Cambios %', isAuto: true),
          ],
        );
      case TemplateType.suscripciones:
        return _buildSubscriptionsTemplate(context);
      case TemplateType.ingresos:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldMock(context, 'Fuente', Icons.work, 'Trabajo, Freelance, etc.'),
            _buildFieldMock(context, 'Monto', Icons.attach_money, 'Número'),
            _buildFieldMock(context, 'Gráfica de Ingresos', Icons.show_chart, 'Automático', isAuto: true),
          ],
        );
      case TemplateType.libre:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Esta plantilla está vacía. Añade bloques para construir tu formato ideal.', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 24),
          ],
        );
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
    );
  }

  Widget _buildFieldMock(BuildContext context, String title, IconData icon, String typeStr, {bool isAuto = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(icon, color: isAuto ? color : Colors.grey[600], size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: isAuto ? color.withOpacity(0.1) : Colors.grey[100], borderRadius: BorderRadius.circular(8)),
            child: Text(typeStr, style: TextStyle(fontSize: 12, color: isAuto ? color : Colors.grey[600], fontWeight: isAuto ? FontWeight.bold : FontWeight.normal)),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.drag_indicator, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsTemplate(BuildContext context) {
    const Color dustyPink = Color(0xFFD4A5A5);
    const Color softLilac = Color(0xFFF8E9F2);

    final subscriptions = [
      {'name': 'Netflix', 'price': '\$10/mes', 'due': '2 días', 'icon': Icons.movie, 'color': const Color(0xFFE50914)},
      {'name': 'Spotify', 'price': '\$8/mes', 'due': '5 días', 'icon': Icons.music_note, 'color': const Color(0xFF1DB954)},
      {'name': 'Disney +', 'price': '\$11/mes', 'due': '8 días', 'icon': Icons.video_collection, 'color': const Color(0xFF113CCF)},
      {'name': 'Prime Video', 'price': '\$14/mes', 'due': '12 días', 'icon': Icons.tv, 'color': const Color(0xFF00A8E1)},
      {'name': 'Apple Music', 'price': '\$9/mes', 'due': '15 días', 'icon': Icons.apple, 'color': const Color(0xFFFA2D48)},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: softLilac,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Control de Suscripciones', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF5B2D5B))),
              const SizedBox(height: 8),
              const Text('Ver todas tus suscripciones en un solo lugar y evitar cobros sorpresa.', style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF7F6A80))),
              const SizedBox(height: 20),
              Row(
                children: [
                  _TemplateStat(label: 'Pago mensual', value: '\$10', icon: Icons.calendar_month),
                  const SizedBox(width: 12),
                  _TemplateStat(label: 'Gastos innecesarios', value: '2', icon: Icons.trending_down),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Suscripciones activas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
            Text('3 items', style: TextStyle(fontSize: 12, color: Color(0xFF9B8F9F))),
          ],
        ),
        const SizedBox(height: 16),
        ...subscriptions.map((sub) => _buildSubscriptionCard(context, sub)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, size: 18),
          label: const Text('AÃ±adir suscripciÃ³n', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: dustyPink,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, Map<String, dynamic> sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: (sub['color'] as Color).withOpacity(0.18), borderRadius: BorderRadius.circular(18)),
            child: Icon(sub['icon'] as IconData, color: sub['color'] as Color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(sub['price'] as String, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF8D7B94))),
                    const SizedBox(width: 10),
                    Text('Vence ${sub['due']}', style: const TextStyle(fontSize: 12, color: Color(0xFFB39DB3))),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFFCE8F3), borderRadius: BorderRadius.circular(16)),
            child: const Text('Activo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFD16FA8))),
          ),
        ],
      ),
    );
  }

  Widget _TemplateStat({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8D7E5)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: const Color(0xFFF8E1EB), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: const Color(0xFFB95F89)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF5B2D5B))),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8D7E92))),
            ],
          )
        ],
      ),
    );
  }
}

