// ---------------------------------------------------
// 🧾 AdminPedidosPage
// Gestión de pedidos + métricas + reporte PDF
// Versión con diseño más profesional
// ---------------------------------------------------
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// 📄 Reportes PDF
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminPedidosPage extends StatefulWidget {
  const AdminPedidosPage({Key? key}) : super(key: key);

  @override
  State<AdminPedidosPage> createState() => _AdminPedidosPageState();
}

class _AdminPedidosPageState extends State<AdminPedidosPage> {
  String _periodo = 'hoy'; // hoy, semana, mes
  String _filtroEstado = 'Todos'; // Todos, Pendiente, Finalizado
  String? _nombreAdmin;

  @override
  void initState() {
    super.initState();
    _cargarNombreAdmin();
  }

  Future<void> _cargarNombreAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _nombreAdmin = doc['nombre'] ?? user.email;
        });
      }
    }
  }

  DateTime _fechaDesde() {
    final now = DateTime.now();
    if (_periodo == 'hoy') {
      return DateTime(now.year, now.month, now.day);
    } else if (_periodo == 'semana') {
      return now.subtract(const Duration(days: 7));
    } else {
      // mes
      return now.subtract(const Duration(days: 30));
    }
  }

  // ---------- MÉTRICAS ----------
  Widget _buildMetricCard(
    String titulo,
    String valor,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- DETALLE PEDIDO ----------
  void _mostrarDetallePedido(BuildContext context, Map<String, dynamic> pedido) {
    final List<dynamic> items = pedido['items'] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '🧾 Detalle del Pedido',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 600),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.orange),
                  title: Text(
                    pedido['nombre'] ?? 'Sin nombre',
                    style: const TextStyle(fontFamily: 'Poppins'),
                  ),
                  subtitle: const Text('Cliente'),
                ),
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.blue),
                  title: Text(
                    pedido['email'] ?? 'Sin correo',
                    style: const TextStyle(fontFamily: 'Poppins'),
                  ),
                  subtitle: const Text('Correo electrónico'),
                ),
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.green),
                  title: Text(
                    pedido['telefono'] ?? 'Sin teléfono',
                    style: const TextStyle(fontFamily: 'Poppins'),
                  ),
                  subtitle: const Text('Teléfono'),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.red),
                  title: Text(
                    pedido['direccion'] ?? 'No especificada',
                    style: const TextStyle(fontFamily: 'Poppins'),
                  ),
                  subtitle: const Text('Dirección'),
                ),
                const Divider(height: 32),
                const Text(
                  '🛍️ Productos:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                ...items.map((item) {
                  final subtotal =
                      (item['price'] * item['quantity']).toStringAsFixed(2);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item['name']} x${item['quantity']}',
                            style: const TextStyle(
                                fontSize: 14, fontFamily: 'Poppins'),
                          ),
                        ),
                        Text('S/ $subtotal'),
                      ],
                    ),
                  );
                }).toList(),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      'S/ ${(pedido['total'] as num).toDouble().toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estado:',
                        style: TextStyle(fontFamily: 'Poppins')),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: pedido['estado'] == 'Finalizado'
                            ? Colors.green[100]
                            : Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pedido['estado'] ?? 'Pendiente',
                        style: TextStyle(
                          color: pedido['estado'] == 'Finalizado'
                              ? Colors.green[800]
                              : Colors.orange[800],
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.close),
            label: const Text('Cerrar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ---------- REPORTES PDF ----------
  Future<void> _exportarReportePDF({
    required List<QueryDocumentSnapshot> pedidos,
    required double totalVentas,
    required int pedidosPendientes,
    required int pedidosFinalizados,
  }) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final desde = _fechaDesde();
    String periodoTexto;
    if (_periodo == 'hoy') {
      periodoTexto = 'Hoy (${desde.day}/${desde.month}/${desde.year})';
    } else if (_periodo == 'semana') {
      periodoTexto =
          'Últimos 7 días (${desde.day}/${desde.month}/${desde.year} - ${now.day}/${now.month}/${now.year})';
    } else {
      periodoTexto =
          'Últimos 30 días (${desde.day}/${desde.month}/${desde.year} - ${now.day}/${now.month}/${now.year})';
    }

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Reporte de Pedidos - Minimarket Taully',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Paragraph(
            text: 'Generado por: ${_nombreAdmin ?? 'Administrador'}',
          ),
          pw.Paragraph(text: 'Periodo: $periodoTexto'),
          pw.Paragraph(text: 'Estado filtrado: $_filtroEstado'),
          pw.SizedBox(height: 10),
          pw.Text(
            'Resumen de ventas',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Bullet(
              text: 'Total de ventas: S/ ${totalVentas.toStringAsFixed(2)}'),
          pw.Bullet(text: 'Número de pedidos: ${pedidos.length.toString()}'),
          pw.Bullet(text: 'Pedidos pendientes: $pedidosPendientes'),
          pw.Bullet(text: 'Pedidos finalizados: $pedidosFinalizados'),
          pw.Bullet(
            text:
                'Ticket promedio: S/ ${pedidos.isNotEmpty ? (totalVentas / pedidos.length).toStringAsFixed(2) : '0.00'}',
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Detalle de pedidos',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Table.fromTextArray(
            headers: [
              'Fecha',
              'Cliente',
              'Total (S/)',
              'Estado',
            ],
            data: pedidos.map((d) {
              final data = d.data() as Map<String, dynamic>;
              final fechaCampo = data['fecha'];
              DateTime fecha;
              if (fechaCampo is Timestamp) {
                fecha = fechaCampo.toDate();
              } else if (fechaCampo is DateTime) {
                fecha = fechaCampo;
              } else {
                fecha = now;
              }
              final fechaTexto =
                  '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
              final total =
                  (data['total'] as num?)?.toDouble().toStringAsFixed(2) ??
                      '0.00';
              final estado = data['estado'] ?? 'Pendiente';
              final nombre = data['nombre'] ?? 'Sin nombre';

              return [fechaTexto, nombre, total, estado];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // ---------- DRAWER ----------
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFFF176)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Image.asset(
                    'lib/imgtaully/Taully_remo.png',
                    height: 50,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _nombreAdmin ?? 'Administrador',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          _drawerItem(Icons.home, 'Ir a Home', Colors.orange, '/home'),
          _drawerItem(Icons.inventory, 'Gestión de Productos',
              Colors.blue, '/admin-productos'),
          _drawerItem(Icons.receipt_long, 'Gestión de Pedidos',
              Colors.teal, '/admin-pedidos'),
          _drawerItem(Icons.local_offer, 'Gestión de Ofertas',
              Colors.redAccent, '/admin-ofertas'),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
      IconData icon, String title, Color color, String? route) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: const TextStyle(fontFamily: 'Poppins'),
      ),
      onTap: () {
        if (route != null) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }

  // ---------- UI PRINCIPAL ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: const Text(
          'Panel de Pedidos',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (_nombreAdmin != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings,
                      size: 18, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    _nombreAdmin!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pedidos')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final desde = _fechaDesde();

          // Filtrar por fecha y estado
          final filtrados = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final fechaCampo = data['fecha'];
            DateTime fecha;
            if (fechaCampo is Timestamp) {
              fecha = fechaCampo.toDate();
            } else if (fechaCampo is DateTime) {
              fecha = fechaCampo;
            } else {
              return false;
            }

            if (fecha.isBefore(desde)) return false;

            if (_filtroEstado != 'Todos' &&
                (data['estado'] ?? 'Pendiente') != _filtroEstado) {
              return false;
            }

            return true;
          }).toList();

          // Métricas
          double totalVentas = 0;
          int pedidosPendientes = 0;
          int pedidosFinalizados = 0;

          for (final d in filtrados) {
            final data = d.data() as Map<String, dynamic>;
            final total = (data['total'] as num?)?.toDouble() ?? 0.0;
            totalVentas += total;

            final estado = data['estado'] ?? 'Pendiente';
            if (estado == 'Pendiente') pedidosPendientes++;
            if (estado == 'Finalizado') pedidosFinalizados++;
          }

          final ticketPromedio =
              filtrados.isNotEmpty ? totalVentas / filtrados.length : 0.0;

          return Column(
            children: [
              // ====== HEADER: Resumen + filtros ======
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen de ventas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Chips de periodo + estado
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _chipFiltroPeriodo('Hoy', 'hoy'),
                          _chipFiltroPeriodo('Últimos 7 días', 'semana'),
                          _chipFiltroPeriodo('Últimos 30 días', 'mes'),
                          const SizedBox(width: 12),
                          _chipFiltroEstado('Todos'),
                          _chipFiltroEstado('Pendiente'),
                          _chipFiltroEstado('Finalizado'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Métricas en "grid"
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Total ventas',
                            'S/ ${totalVentas.toStringAsFixed(2)}',
                            Icons.monetization_on,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricCard(
                            'Pedidos',
                            filtrados.length.toString(),
                            Icons.shopping_bag,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Pendientes',
                            pedidosPendientes.toString(),
                            Icons.pending_actions,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricCard(
                            'Finalizados',
                            pedidosFinalizados.toString(),
                            Icons.check_circle,
                            Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Ticket promedio',
                            'S/ ${ticketPromedio.toStringAsFixed(2)}',
                            Icons.receipt_long,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ====== LISTA DE PEDIDOS (nuevo diseño) ======
              Expanded(
                child: filtrados.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay pedidos en este periodo',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.black54,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        itemCount: filtrados.length,
                        itemBuilder: (context, index) {
                          final doc = filtrados[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final estado = data['estado'] ?? 'Pendiente';

                          final fechaCampo = data['fecha'];
                          DateTime fecha;
                          if (fechaCampo is Timestamp) {
                            fecha = fechaCampo.toDate();
                          } else if (fechaCampo is DateTime) {
                            fecha = fechaCampo;
                          } else {
                            fecha = DateTime.now();
                          }

                          final total =
                              (data['total'] as num?)?.toDouble().toStringAsFixed(2) ??
                                  '0.00';

                          final bool esFinalizado = estado == 'Finalizado';
                          final Color colorEstado =
                              esFinalizado ? Colors.green : Colors.orange;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(
                                color: esFinalizado
                                    ? Colors.green.withOpacity(0.25)
                                    : Colors.orange.withOpacity(0.25),
                                width: 0.7,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () =>
                                  _mostrarDetallePedido(context, data),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Primera fila: avatar + nombre + estado + menú
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: esFinalizado
                                              ? Colors.green[50]
                                              : Colors.orange[50],
                                          child: Icon(
                                            esFinalizado
                                                ? Icons.check
                                                : Icons.timelapse,
                                            color: colorEstado,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                data['nombre'] ?? 'Sin nombre',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Total: S/ $total',
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 12.5,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        // Chip de estado
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                colorEstado.withOpacity(0.08),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            estado,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: colorEstado,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                        // Botón menú (⋮)
                                        PopupMenuButton<String>(
                                          icon: const Icon(
                                            Icons.more_vert,
                                            size: 18,
                                          ),
                                          onSelected: (value) async {
                                            if (value == 'estado') {
                                              final nuevoEstado =
                                                  estado == 'Pendiente'
                                                      ? 'Finalizado'
                                                      : 'Pendiente';

                                              await FirebaseFirestore.instance
                                                  .collection('pedidos')
                                                  .doc(doc.id)
                                                  .update(
                                                    {'estado': nuevoEstado},
                                                  );

                                              if (!mounted) return;

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Pedido marcado como $nuevoEstado',
                                                  ),
                                                  backgroundColor:
                                                      nuevoEstado ==
                                                              'Finalizado'
                                                          ? Colors.green
                                                          : Colors.orange,
                                                  duration: const Duration(
                                                      seconds: 2),
                                                ),
                                              );
                                            } else if (value == 'eliminar') {
                                              await FirebaseFirestore.instance
                                                  .collection('pedidos')
                                                  .doc(doc.id)
                                                  .delete();

                                              if (!mounted) return;

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content:
                                                      Text('Pedido eliminado'),
                                                  duration:
                                                      Duration(seconds: 2),
                                                ),
                                              );
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'estado',
                                              child: Text(
                                                estado == 'Pendiente'
                                                    ? 'Marcar como finalizado'
                                                    : 'Marcar como pendiente',
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'eliminar',
                                              child: Text(
                                                'Eliminar pedido',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 6),

                                    // Segunda fila: fecha
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 13,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}',
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 11.5,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Builder(
        builder: (context) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pedidos')
                .orderBy('fecha', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              final docs = snapshot.data!.docs;
              final desde = _fechaDesde();

              final filtrados = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final fechaCampo = data['fecha'];
                DateTime fecha;
                if (fechaCampo is Timestamp) {
                  fecha = fechaCampo.toDate();
                } else if (fechaCampo is DateTime) {
                  fecha = fechaCampo;
                } else {
                  return false;
                }

                if (fecha.isBefore(desde)) return false;

                if (_filtroEstado != 'Todos' &&
                    (data['estado'] ?? 'Pendiente') != _filtroEstado) {
                  return false;
                }

                return true;
              }).toList();

              double totalVentas = 0;
              int pedidosPendientes = 0;
              int pedidosFinalizados = 0;

              for (final d in filtrados) {
                final data = d.data() as Map<String, dynamic>;
                final total =
                    (data['total'] as num?)?.toDouble() ?? 0.0;
                totalVentas += total;

                final estado = data['estado'] ?? 'Pendiente';
                if (estado == 'Pendiente') pedidosPendientes++;
                if (estado == 'Finalizado') pedidosFinalizados++;
              }

              if (filtrados.isEmpty) {
                return const SizedBox.shrink();
              }

              return FloatingActionButton.extended(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Reporte'),
                backgroundColor: Colors.redAccent,
                onPressed: () => _exportarReportePDF(
                  pedidos: filtrados,
                  totalVentas: totalVentas,
                  pedidosPendientes: pedidosPendientes,
                  pedidosFinalizados: pedidosFinalizados,
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ---------- Chips de filtros ----------
  Widget _chipFiltroPeriodo(String label, String value) {
    final bool selected = _periodo == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
        selected: selected,
        selectedColor: Colors.orange,
        backgroundColor: Colors.grey.shade200,
        onSelected: (_) => setState(() => _periodo = value),
      ),
    );
  }

  Widget _chipFiltroEstado(String estado) {
    final bool selected = _filtroEstado == estado;
    Color color;
    if (estado == 'Pendiente') {
      color = Colors.orange;
    } else if (estado == 'Finalizado') {
      color = Colors.green;
    } else {
      color = Colors.blueGrey;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(
          estado,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
        selected: selected,
        selectedColor: color,
        backgroundColor: Colors.grey.shade200,
        onSelected: (_) => setState(() => _filtroEstado = estado),
      ),
    );
  }
}
