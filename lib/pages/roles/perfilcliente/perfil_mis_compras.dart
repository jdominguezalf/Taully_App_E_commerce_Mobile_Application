import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PerfilMisComprasPage extends StatefulWidget {
  const PerfilMisComprasPage({super.key});

  @override
  State<PerfilMisComprasPage> createState() => _PerfilMisComprasPageState();
}

class _PerfilMisComprasPageState extends State<PerfilMisComprasPage> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "⚠️ Debes iniciar sesión para ver tus compras.",
            style: TextStyle(fontFamily: 'Poppins'),
          ),
        ),
      );
    }

    print("🟢 UID actual logueado: ${user!.uid}");
    print("🟢 Email actual logueado: ${user!.email}");

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDE7),
      appBar: AppBar(
        title: const Text(
          "Mis Compras",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.orangeAccent,
        centerTitle: true,
        elevation: 3,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pedidos')
            .where('usuario_id', isEqualTo: user!.uid)
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Si hay error
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "❌ Error al cargar tus pedidos.",
                style: TextStyle(fontFamily: 'Poppins', color: Colors.redAccent),
              ),
            );
          }

          // Mientras carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            );
          }

          // Si no hay pedidos con UID → buscar por email
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pedidos')
                  .where('email', isEqualTo: user!.email)
                  .orderBy('fecha', descending: true)
                  .snapshots(),
              builder: (context, secondSnapshot) {
                if (secondSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.orangeAccent),
                  );
                }

                if (!secondSnapshot.hasData ||
                    secondSnapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "🛍️ Aún no has realizado compras.",
                      style:
                          TextStyle(fontFamily: 'Poppins', fontSize: 16),
                    ),
                  );
                }

                return _buildListaPedidos(secondSnapshot.data!.docs);
              },
            );
          }

          // Mostrar pedidos encontrados por UID
          return _buildListaPedidos(snapshot.data!.docs);
        },
      ),
    );
  }

  // ======================================================
  // 📋 Construir la lista de pedidos
  // ======================================================
  Widget _buildListaPedidos(List<QueryDocumentSnapshot> pedidos) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      physics: const BouncingScrollPhysics(),
      itemCount: pedidos.length,
      itemBuilder: (context, index) {
        final data = pedidos[index].data() as Map<String, dynamic>;
        final fecha = (data['fecha'] is Timestamp)
            ? (data['fecha'] as Timestamp).toDate()
            : DateTime.now();
        final total = (data['total'] is num)
            ? (data['total'] as num).toStringAsFixed(2)
            : "0.00";
        final estado = data['estado'] ?? 'Pendiente';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade100,
              child: const Icon(Icons.receipt_long,
                  color: Colors.orangeAccent),
            ),
            title: Text(
              "Pedido #${pedidos[index].id.substring(0, 6)}",
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "Fecha: ${fecha.day}/${fecha.month}/${fecha.year}\n"
              "Total: S/. $total\nEstado: $estado",
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                size: 18, color: Colors.orangeAccent),
            onTap: () => _mostrarDetallePedido(context, data),
          ),
        );
      },
    );
  }

  // ======================================================
  // 🧾 Detalle del pedido (modal inferior)
  // ======================================================
  void _mostrarDetallePedido(BuildContext context, Map<String, dynamic> data) {
    final List<dynamic> items = data['items'] ?? [];
    final total = (data['total'] is num)
        ? (data['total'] as num).toStringAsFixed(2)
        : "0.00";
    final metodoPago = data['metodo_pago'] ?? 'No especificado';
    final estado = data['estado'] ?? 'Pendiente';
    final direccion = data['direccion'] ?? 'Sin dirección';
    final telefono = data['telefono'] ?? 'No registrado';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "🧾 Detalle del Pedido",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ...items.map((item) {
                final nombre = item['name'] ?? 'Producto';
                final cantidad = item['quantity'] ?? 1;
                final precio = (item['price'] is num)
                    ? (item['price'] as num).toStringAsFixed(2)
                    : "0.00";
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "$nombre (x$cantidad)",
                          style: const TextStyle(fontFamily: 'Poppins'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        "S/. $precio",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 30, thickness: 1),
              _infoRow("Total:", "S/. $total", bold: true),
              _infoRow("Método de pago:", metodoPago),
              _infoRow("Estado:", estado),
              _infoRow("Teléfono:", telefono),
              _infoRow("Dirección:", direccion),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text(
                    "Cerrar",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: bold ? Colors.orangeAccent : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
