// ---------------------------------------------------
// 🔎 Archivo: productos_busqueda_page.dart
// Proyecto: Minimarket Taully
// Descripción: Resultados de búsqueda en Home, integrando
//              ofertas activas vinculadas por productoId.
//              Muestra badge, precio oferta y manda al
//              carrito el precioFinal.
// ---------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../cart.dart';
import '../services/product_service.dart';
import '../widgets/check_page.dart';
import '../pages/confimacion-pedi/confirmacion_pedido_page.dart';

class ProductosBusquedaPage extends StatelessWidget {
  final String searchTerm;
  final ProductService _productService = ProductService();

  ProductosBusquedaPage({super.key, required this.searchTerm});

  Color obtenerColorCategoria(String categoria) {
    switch (categoria.trim().toLowerCase()) {
      case 'abarrotes':
        return Colors.orange.shade600;
      case 'golosinas':
        return Colors.pink.shade600;
      case 'limpieza':
      case 'prod.limpieza':
        return Colors.blue.shade600;
      case 'comd.animales':
      case 'mascotas':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1️⃣ Escuchamos ofertas activas para armar mapa productoId -> oferta
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ofertas')
          .where('activo', isEqualTo: true)
          .snapshots(),
      builder: (context, ofertasSnapshot) {
        if (ofertasSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
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

        // 2️⃣ Ahora escuchamos todos los productos y filtramos por nombre
        return Scaffold(
          appBar: AppBar(
            title: const Text('Resultados de búsqueda'),
            backgroundColor: const Color.fromARGB(255, 44, 196, 235),
            actions: [
              Consumer<Cart>(
                builder: (context, cart, _) => Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      onPressed: () => _mostrarCarrito(context),
                    ),
                    if (cart.totalQuantity > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${cart.totalQuantity}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          body: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _productService.getAllProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No hay productos disponibles'));
              }

              final productosFiltrados = snapshot.data!
                  .where(
                    (item) => item['name']
                        .toString()
                        .toLowerCase()
                        .contains(searchTerm.toLowerCase()),
                  )
                  .toList();

              if (productosFiltrados.isEmpty) {
                return const Center(
                    child: Text('No se encontraron coincidencias'));
              }

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.59,
                ),
                itemCount: productosFiltrados.length,
                itemBuilder: (context, index) {
                  final item = productosFiltrados[index];

                  // ⚠️ IMPORTANTE: que ProductService incluya 'id' = doc.id
                  final String? productId = item['id']?.toString();

                  final oferta = productId != null
                      ? ofertasPorProductoId[productId]
                      : null;

                  final double precioBase =
                      (item['price'] as num).toDouble();

                  double precioFinal = precioBase;
                  double? precioTachado;
                  double? descuento;

                  if (oferta != null && oferta['precioOferta'] != null) {
                    final double precioOferta =
                        (oferta['precioOferta'] as num).toDouble();
                    final double? precioNormalOferta =
                        oferta['precioNormal'] is num
                            ? (oferta['precioNormal'] as num).toDouble()
                            : null;

                    precioFinal = precioOferta;
                    precioTachado = precioNormalOferta ?? precioBase;

                    if (oferta['descuentoPorcentaje'] is num) {
                      descuento =
                          (oferta['descuentoPorcentaje'] as num).toDouble();
                    }
                  }

                  final categoriaColor =
                      obtenerColorCategoria(item['category'] ?? '');

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Imagen + badge Oferta si aplica
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
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.local_offer,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        descuento != null
                                            ? '-${descuento!.toStringAsFixed(0)}%'
                                            : 'Oferta',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
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

                                // 💰 Precios (con o sin oferta)
                                if (oferta == null) ...[
                                  Text(
                                    'S/ ${precioBase.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: categoriaColor,
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
                                          'S/ ${precioTachado!.toStringAsFixed(2)}',
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

                                // 🛒 Botón Agregar (usa precioFinal)
                                ElevatedButton.icon(
                                  icon: const Icon(
                                    Icons.add_shopping_cart,
                                    size: 18,
                                  ),
                                  label: const Text('Agregar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: categoriaColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    final cart = Provider.of<Cart>(
                                      context,
                                      listen: false,
                                    );

                                    final productoParaCarrito = {
                                      ...item,
                                      'price': precioFinal, // 👈 respeta oferta
                                    };

                                    cart.addToCart(productoParaCarrito);

                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${item['name']} agregado al carrito',
                                          ),
                                          duration: const Duration(
                                            milliseconds: 800,
                                          ),
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
            },
          ),
        );
      },
    );
  }

  // ===================================================
  // 🧾 Modal del carrito (igual que antes)
  // ===================================================
  void _mostrarCarrito(BuildContext context) {
    final cart = Provider.of<Cart>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Carrito de compras'),
        content: Consumer<Cart>(
          builder: (context, cart, _) {
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
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                      Icons.remove_circle_outline,
                                    ),
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
                                      Icons.add_circle_outline,
                                    ),
                                    onPressed: () => cart.addToCart(item),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      cart.removeCompleteItem(item['name']);
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
                MaterialPageRoute(builder: (_) => const ConfirmacionPedidoPage()),
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
