import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../cart.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);
    final items = cart.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Carrito',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'Tu carrito está vacío 🛒',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final String name =
                          (item['name'] ?? 'Producto').toString();
                      final double price =
                          (item['price'] ?? 0.0) as double;
                      final int quantity =
                          (item['quantity'] ?? 0) as int;
                      final String? imageUrl =
                          item['image'] as String?;

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              // Imagen
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(10),
                                child: imageUrl != null &&
                                        imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) =>
                                                const Icon(
                                          Icons.image_outlined,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      )
                                    : const SizedBox(
                                        width: 60,
                                        height: 60,
                                        child: Icon(
                                          Icons.image_outlined,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 10),

                              // Info principal
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 2,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'S/ ${price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Controles de cantidad
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      cart.removeFromCart(item);
                                    },
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Text(
                                    '$quantity',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      cart.addToCart(item);
                                    },
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              ),

                              // Borrar todo el ítem
                              IconButton(
                                onPressed: () {
                                  cart.removeCompleteItem(
                                      item['name'] as String);
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Resumen y botón de continuar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'S/ ${cart.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Aquí puedes ir a la pantalla de confirmación de pedido
                          Navigator.pushNamed(
                              context, '/confirmacion-pedido');
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text(
                          'Finalizar pedido',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
