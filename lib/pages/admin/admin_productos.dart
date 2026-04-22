// ---------------------------------------------------
// 📦 AdminProductosPage
// Gestión de productos (CRUD + exportación a PDF)
// ---------------------------------------------------
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/product_service.dart';

class AdminProductosPage extends StatefulWidget {
  const AdminProductosPage({Key? key}) : super(key: key);

  @override
  State<AdminProductosPage> createState() => _AdminProductosPageState();
}

class _AdminProductosPageState extends State<AdminProductosPage> {
  final ProductService _productService = ProductService();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _detallesController = TextEditingController();
  final List<String> _categorias = [
    'Abarrotes',
    'Golosinas',
    'Prod.Limpieza',
    'Comd.Animales',
  ];
  String _categoriaSeleccionada = 'Abarrotes';
  String _filtroNombre = '';

  File? _imageFile;
  String? _imageUrlManual;
  final ImagePicker _picker = ImagePicker();

  bool _isAdding = false;
  String? _editId;
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

  // ---------- IMAGEN PRODUCTO ----------
  Future<void> _seleccionarImagen() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final ext = path.extension(pickedFile.path).toLowerCase();
      if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageUrlManual = null;
          _urlController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Formato no válido. Usa JPG, PNG, GIF, WEBP'),
          ),
        );
      }
    }
  }

  Future<String?> _subirImagen(File imagen) async {
    try {
      final fileName = path.basename(imagen.path);
      final ref = FirebaseStorage.instance.ref().child('productos/$fileName');
      await ref.putFile(imagen);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error al subir imagen: $e');
      return null;
    }
  }

  // ---------- GUARDAR / ACTUALIZAR PRODUCTO ----------
  Future<void> _guardarProducto() async {
    final nombre = _nombreController.text.trim();
    final precioTexto = _precioController.text.trim();
    final urlManual = _urlController.text.trim();
    final direccion = _direccionController.text.trim();
    final detalles = _detallesController.text.trim();


    if (nombre.isEmpty || precioTexto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa nombre y precio')),
      );
      return;
    }

    final precio = double.tryParse(precioTexto);
    if (precio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Precio inválido')),
      );
      return;
    }

    String imageUrl = 'https://via.placeholder.com/150';

    // Prioridad: URL manual > imagen subida > placeholder
    if (urlManual.isNotEmpty) {
      imageUrl = urlManual;
    } else if (_imageFile != null) {
      final url = await _subirImagen(_imageFile!);
      if (url != null) imageUrl = url;
    }

    final data = {
      'name': nombre,
      'price': precio,
      'category': _categoriaSeleccionada,
      'image': imageUrl,
      'address': direccion,
    };

    if (_editId != null) {
      await _productService.updateProduct(_editId!, data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto actualizado')),
      );
    } else {
      await _productService.addProduct(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto agregado')),
      );
    }

    _resetFormulario();
  }

  void _resetFormulario() {
    setState(() {
      _isAdding = false;
      _editId = null;
      _imageFile = null;
      _imageUrlManual = null;
      _urlController.clear();
      _nombreController.clear();
      _precioController.clear();
      _direccionController.clear();
    });
  }

  Future<void> _eliminarProducto(String id) async {
    await _productService.deleteProduct(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Producto eliminado')),
    );
  }

  // ---------- EXPORTAR A PDF ----------
  Future<void> _exportarPDF(List<Map<String, dynamic>> productos) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Lista de Productos - $_categoriaSeleccionada',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Nombre', 'Precio', 'Categoría', 'Detalle/Dirección'],
            data: productos
                .map(
                  (p) => [
                    p['name'],
                    'S/ ${p['price']}',
                    p['category'],
                    p['address'] ?? '',
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _exportarTodosLosProductos() async {
    final productos = await _productService.getAllProducts().first;
    await _exportarPDF(productos);
  }

  // ---------- FORMULARIO ----------
  Widget _buildFormulario() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          TextField(
            controller: _nombreController,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _precioController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Precio (S/)'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _categoriaSeleccionada,
            items: _categorias
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (val) => setState(() => _categoriaSeleccionada = val!),
            decoration: const InputDecoration(labelText: 'Categoría'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _direccionController,
            decoration: const InputDecoration(
              labelText: 'Detalle / Dirección (opcional)',
              hintText: 'Ej: Góndola 3, estante 2',
            ),
          ),
          // 🆕 NUEVA SECCIÓN DETALLES DEL PRODUCTO
TextField(
  controller: _detallesController,
  decoration: const InputDecoration(
    labelText: 'Detalles del producto (opcional)',
    hintText: 'Ej: Marca, tamaño, sabor, unidad, observaciones…',
  ),
  maxLines: 2,
),
const SizedBox(height: 12),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'URL de imagen (opcional)',
              hintText: 'https://tuservidor.com/imagen.jpg',
            ),
            onChanged: (val) {
              if (val.isNotEmpty) {
                setState(() {
                  _imageFile = null;
                  _imageUrlManual = val;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.image),
            label: const Text('Seleccionar desde galería'),
            onPressed: _seleccionarImagen,
          ),
          const SizedBox(height: 12),
          if (_imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_imageFile!, height: 140, fit: BoxFit.cover),
            ),
          if (_imageFile == null && _imageUrlManual != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(_imageUrlManual!,
                  height: 140, fit: BoxFit.cover),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  onPressed: _guardarProducto,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancelar'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  onPressed: _resetFormulario,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- LISTA DE PRODUCTOS ----------
  Widget _buildListaProductos() {
    return Column(
      children: [
        // 🔍 Búsqueda + exportaciones
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (val) => setState(
                    () => _filtroNombre = val.trim().toLowerCase(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Exportar categoría a PDF',
                onPressed: () {
                  _productService
                      .getProductsByCategory(_categoriaSeleccionada)
                      .first
                      .then((productos) {
                    final filtrados = productos
                        .where(
                          (p) => p['name']
                              .toString()
                              .toLowerCase()
                              .contains(_filtroNombre),
                        )
                        .toList();
                    _exportarPDF(filtrados);
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.file_copy),
                tooltip: 'Exportar todos los productos',
                onPressed: _exportarTodosLosProductos,
              ),
            ],
          ),
        ),
        // 🎯 Filtro por categoría
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonFormField<String>(
            value: _categoriaSeleccionada,
            items: _categorias
                .map(
                  (cat) =>
                      DropdownMenuItem(value: cat, child: Text(cat)),
                )
                .toList(),
            onChanged: (val) => setState(() => _categoriaSeleccionada = val!),
            decoration: const InputDecoration(
              labelText: 'Filtrar por categoría',
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 📋 Lista
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _productService.getProductsByCategory(
              _categoriaSeleccionada,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final productos = snapshot.data!
                  .where(
                    (p) => p['name']
                        .toString()
                        .toLowerCase()
                        .contains(_filtroNombre),
                  )
                  .toList();

              if (productos.isEmpty) {
                return const Center(
                  child: Text('No hay productos registrados en esta categoría'),
                );
              }

              return ListView.builder(
                itemCount: productos.length,
                itemBuilder: (context, index) {
                  final p = productos[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          p['image'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported,
                            size: 32,
                          ),
                        ),
                      ),
                      title: Text(
                        p['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
  'S/ ${p['price']} · ${p['category']}'
  '\n📍 ${p['address'] ?? 'Sin ubicación'}'
  '\n📝 ${p['details'] ?? 'Sin detalles adicionales'}',
),

                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon:
                                const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              setState(() {
                                _editId = p['id'];
                                _nombreController.text = p['name'];
                                _precioController.text =
                                    p['price'].toString();
                                _categoriaSeleccionada = p['category'];
                                _direccionController.text =
                                    p['address'] ?? '';
                                       _detallesController.text = p['details'] ?? '';
                                _imageUrlManual = p['image'];
                                _urlController.text = p['image'];
                                _imageFile = null;
                                _isAdding = true;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _eliminarProducto(p['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ===================================================
  // 🎨 DRAWER (Menú lateral actualizado)
  // ===================================================
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
          _drawerItem(Icons.inventory, 'Gestión de Productos', Colors.blue,
              '/admin-productos'),
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
      appBar: AppBar(
        title: const Text('Gestión de Productos'),
        actions: [
          if (_nombreAdmin != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  _nombreAdmin!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isAdding ? _buildFormulario() : _buildListaProductos(),
      floatingActionButton: !_isAdding
          ? FloatingActionButton(
              onPressed: () => setState(() => _isAdding = true),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
