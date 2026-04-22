// ---------------------------------------------------
// 🔎 Archivo: search_results_page.dart
// Proyecto: Minimarket Taully
// Descripción: Resultados de búsqueda de productos,
//              integrando ofertas activas vinculadas
//              por productoId (precio oferta, badge,
//              y precio que va al carrito).
// ---------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:taully/services/product_service.dart';
import '../cart.dart';

class SearchResultsPage extends StatefulWidget {
  final String searchTerm;
  const SearchResultsPage({super.key, required this.searchTerm});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final ProductService _productService = ProductService();
  late Future<List<Map<String, dynamic>>> _searchResults;

  @override
  void initState() {
    super.initState();
    _searchResults = _getResults();
  }

  Future<List<Map<String, dynamic>>> _getResults() async {
    // 👇 Asegúrate que ProductService.getAllProductsOnce()
    // devuelva cada producto con campo 'id' = doc.id
    final allProducts = await _productService.getAllProductsOnce();
    return allProducts
        .where(
          (product) => product['name']
              .toString()
              .toLowerCase()
              .contains(widget.searchTerm.toLowerCase()),
        )
        .toList();
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
            // 🔗 Clave = id del producto en 'products'
            ofertasPorProductoId[productoId.toString()] = data;
          }
        }

        // 2️⃣ Ahora cargamos los productos (resultado de búsqueda)
        return Scaffold(
          appBar: AppBar(
            title: const Text('Resultados de búsqueda'),
            backgroundColor: Colors.amber,
          ),
          body: FutureBuilder<List<Map<String, dynamic>>>(
            future: _searchResults,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('No se encontraron productos.'),
                );
              }

              final results = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final item = results[index];

                  // ⚠️ IMPORTANTE: que item['id'] venga de doc.id de 'products'
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

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item['image'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image, size: 32),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (oferta != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
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
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: oferta == null
                            ? Text(
                                'S/ ${precioBase.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              )
                            : Row(
                                children: [
                                  Text(
                                    'S/ ${precioFinal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
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
                      ),
                      trailing: ElevatedButton.icon(
                        icon: const Icon(Icons.add_shopping_cart, size: 16),
                        label: const Text('Agregar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final cart =
                              Provider.of<Cart>(context, listen: false);

                          // 👇 Mandamos al carrito el producto ya con precioFinal (con oferta si hay)
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
                                  '${item['name']} agregado al carrito',
                                ),
                                duration:
                                    const Duration(milliseconds: 800),
                              ),
                            );
                        },
                      ),
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
}
