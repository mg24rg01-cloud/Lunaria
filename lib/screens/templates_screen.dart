import 'package:flutter/material.dart';
import 'template_detail_screen.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Biblioteca de Plantillas', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Plantillas Prediseñadas', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text('Elige la estructura que mejor se adapte a tus necesidades.', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),

          const _TemplateCard(title: '1. Control Mensual Completo', desc: 'Ingresos, gastos, ahorro y balance.', icon: Icons.calendar_month, color: Color(0xFF81D4FA), type: TemplateType.mensual),
          const _TemplateCard(title: '2. Registro Diario Rápido', desc: 'Rapidez para el día a día.', icon: Icons.receipt_long, color: Color(0xFFF48FB1), type: TemplateType.diario),
          const _TemplateCard(title: '3. Seguimiento de Ahorro', desc: 'Metas, progreso y aportaciones.', icon: Icons.track_changes, color: Color(0xFFCE93D8), type: TemplateType.ahorro),
          const _TemplateCard(title: '4. Presupuesto Mensual', desc: 'Asignado vs Real con alertas.', icon: Icons.pie_chart_outline, color: Color(0xFFA5D6A7), type: TemplateType.presupuesto),
          const _TemplateCard(title: '5. Comparación de Meses', desc: 'Analíticas y tendencias.', icon: Icons.compare_arrows, color: Color(0xFFFFCC80), type: TemplateType.comparacion),
          const _TemplateCard(title: '6. Control de Suscripciones', desc: 'Pagos recurrentes y recordatorios.', icon: Icons.autorenew, color: Color(0xFF80CBC4), type: TemplateType.suscripciones),
          const _TemplateCard(title: '7. Control de Ingresos', desc: 'Fuentes de ingreso y filtros.', icon: Icons.work_outline, color: Color(0xFFC5E1A5), type: TemplateType.ingresos),
          const _TemplateCard(title: '8. Plantilla Libre', desc: 'Personalizable, añade tus campos.', icon: Icons.dashboard_customize, color: Color(0xFFFFD54F), type: TemplateType.libre),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

enum TemplateType { mensual, diario, ahorro, presupuesto, comparacion, suscripciones, ingresos, libre }

class _TemplateCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final TemplateType type;

  const _TemplateCard({required this.title, required this.desc, required this.icon, required this.color, required this.type});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => TemplateDetailScreen(title: title, color: color, type: type)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[300], size: 16),
          ],
        ),
      ),
    );
  }
}
