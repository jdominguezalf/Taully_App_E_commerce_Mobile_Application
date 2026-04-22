// ---------------------------------------------------
// 🧴 Archivo: limpieza_page.dart
// Proyecto: Minimarket Taully
// Descripción: Página de categoría "Productos de Limpieza"
//              con AppBar compacto, carrito funcional y grid.
//              Ahora Interpreta ofertas activas por productoId.
// ---------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/product_service.dart';
import '../cart.dart';
import 'confimacion-pedi/confirmacion_pedido_page.dart';

class LimpiezaPage extends StatefulWidget {
  final String searchTerm;
  const LimpiezaPage({super.key, this.searchTerm = ''});

  @override
  State<LimpiezaPage> createState() => _LimpiezaPageState();
}

class _LimpiezaPageState extends State<LimpiezaPage> {
  final ProductService _productService = ProductService();

  @override
  Widget build(BuildContext context) {
    // 1️⃣ Escuchamos ofertas activas
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ofertas')
          .where('activo', isEqualTo: true)
          .snapshots(),
      builder: (context, ofertasSnapshot) {
        if (ofertasSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final ofertasDocs = ofertasSnapshot.data?.docs ?? [];

        final Map<String, Map<String, dynamic>> ofertasPorProductoId = {};
        for (var doc in ofertasDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final productoId = data['productoId'];
          if (productoId != null && productoId.toString().isNotEmpty) {
            ofertasPorProductoId[productoId.toString()] = data;
          }
        }

        // 2️⃣ Escuchamos productos Limpieza
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _productService.getProductsByCategory('Prod.Limpieza'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No hay productos disponibles'));
            }

            final productos = snapshot.data!
                .where(
                  (p) => p['name']
                      .toString()
                      .toLowerCase()
                      .contains(widget.searchTerm.toLowerCase()),
                )
                .toList();

            return Scaffold(
              // ============================
              // 💙 APPBAR
              // ============================
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(15),
                child: Container(
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2196F3),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Center(
                          child: Text(
                            'Productos de Limpieza',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildCartIcon(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ============================
              // 🧩 CUERPO
              // ============================
              body: SafeArea(
                top: false,
                child: productos.isEmpty
                    ? const Center(child: Text('No se encontraron productos'))
                    : _buildGrid(productos, ofertasPorProductoId),
              ),
            );
          },
        );
      },
    );
  }

  // ===================================================
  // 🛒 Ícono de carrito
  // ===================================================
  Widget _buildCartIcon(BuildContext context) {
    return Consumer<Cart>(
      builder: (context, cart, _) => Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () => _mostrarCarrito(context),
          ),
          if (cart.totalQuantity > 0)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  '${cart.totalQuantity}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===================================================
  // 🧱 Grid con ofertas
  // ===================================================
  Widget _buildGrid(
    List<Map<String, dynamic>> productos,
    Map<String, Map<String, dynamic>> ofertasPorProductoId,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.59,
      ),
      itemCount: productos.length,
      itemBuilder: (context, index) {
        final item = productos[index];

        final String? productId = item['id'];

        final oferta = productId != null
            ? ofertasPorProductoId[productId]
            : null;

        final double precioBase = (item['price'] as num).toDouble();

        double precioFinal = precioBase;
        double? precioTachado;
        double? descuento;

        if (oferta != null && oferta['precioOferta'] != null) {
          precioFinal = (oferta['precioOferta'] as num).toDouble();

          if (oferta['precioNormal'] is num) {
            precioTachado =
                (oferta['precioNormal'] as num).toDouble();
          } else {
            precioTachado = precioBase;
          }

          if (oferta['descuentoPorcentaje'] is num) {
            descuento =
                (oferta['descuentoPorcentaje'] as num).toDouble();
          }
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagen + badge
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.1,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.network(
                        item['image'],
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, size: 40),
                      ),
                    ),
                  ),
                  if (oferta != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          descuento != null
                              ? '-${descuento.toStringAsFixed(0)}%'
                              : 'Oferta',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        item['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Precios
                      if (oferta == null) ...[
                        Text(
                          'S/ ${precioBase.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Text(
                              'S/ ${precioFinal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (precioTachado != null)
                              Text(
                                'S/ ${precioTachado.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  decoration:
                                      TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                      ],

                      const Spacer(),

                      // Botón agregar
                      ElevatedButton.icon(
                        icon:
                            const Icon(Icons.add_shopping_cart, size: 18),
                        label: const Text('Agregar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          final cart =
                              Provider.of<Cart>(context, listen: false);

                          final productoParaCarrito = {
                            ...item,
                            'price': precioFinal,
                          };

                          cart.addToCart(productoParaCarrito);

                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${item['name']} agregado al carrito'),
                                duration:
                                    const Duration(milliseconds: 800),
                              ),
                            );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===================================================
  // 🧾 Modal del carrito
  // ===================================================
  void _mostrarCarrito(BuildContext context) {
    final cart = Provider.of<Cart>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Carrito de compras'),
        content: Consumer<Cart>(
          builder: (context, cart, child) {
            if (cart.items.isEmpty) {
              return const Text('Tu carrito está vacío');
            }

            return SizedBox(
              height: 320,
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: cart.items.length,
                itemBuilder: (context, index) {
                  final item = cart.items[index];
                  final quantity = item['quantity'];
                  final price = item['price'];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item['image'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('S/ $price x $quantity'),
                              Text(
                                'Total: S/ ${(price * quantity).toStringAsFixed(2)}',
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        Icons.remove_circle_outline),
                                    onPressed: () {
                                      cart.removeFromCart(item);
                                      if (cart.items.isEmpty) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                                  ),
                                  Text('$quantity'),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.add_circle_outline),
                                    onPressed: () => cart.addToCart(item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      cart.removeCompleteItem(
                                          item['name']);
                                      if (cart.items.isEmpty) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          Consumer<Cart>(
            builder: (context, cart, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Total: S/ ${cart.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          TextButton(
            onPressed: () => cart.clear(),
            child: const Text('Vaciar carrito'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Seguir comprando'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ConfirmacionPedidoPage()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'Pagar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
