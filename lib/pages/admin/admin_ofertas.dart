// ---------------------------------------------------
// 🎯 Archivo: admin_ofertas.dart
// Proyecto: Minimarket Taully
// Descripción: Gestión de ofertas (crear, editar,
//              activar/desactivar, eliminar) con
//              imagen local o por URL, precios y
//              categoría, todo guardado en Firestore.
//              Ahora con vínculo a productos (productoId)
//              y UI más profesional.
// ---------------------------------------------------

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_auth/firebase_auth.dart';

class AdminOfertasPage extends StatefulWidget {
  const AdminOfertasPage({Key? key}) : super(key: key);

  @override
  State<AdminOfertasPage> createState() => _AdminOfertasPageState();
}

class _AdminOfertasPageState extends State<AdminOfertasPage> {
  // 📌 Controllers principales
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  // 📌 Campos para precios y categoría
  final TextEditingController _precioNormalController = TextEditingController();
  final TextEditingController _precioOfertaController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  bool _isEditing = false;
  String? _editId;
  String? _nombreAdmin;
  String? _correoAdmin;

  // 🔗 Vínculo con productos
  List<Map<String, dynamic>> _productos = [];
  String? _productoIdSeleccionado;

  // 🔍 Filtros de vista
  String _filtroVista = 'todas'; // todas, activas, inactivas
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarDatosAdmin();
    _cargarProductos();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _urlController.dispose();
    _precioNormalController.dispose();
    _precioOfertaController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  // ===================================================
  // 👤 Datos del admin logueado (para Drawer)
  // ===================================================
  Future<void> _cargarDatosAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nombreAdmin = data['nombre'] ?? user.email;
          _correoAdmin = data['email'] ?? user.email;
        });
      }
    }
  }

  // ===================================================
  // 📦 Cargar productos para vincular a ofertas
  // ===================================================
  Future<void> _cargarProductos() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('products')
          .get();

      debugPrint('Productos cargados: ${snap.docs.length}');

      setState(() {
        _productos = snap.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Sin nombre',
            'price': data['price'],
            'image': data['image'],
            'category': data['category'],
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error al cargar productos: $e');
    }
  }

  // ===================================================
  // 📸 Seleccionar imagen desde galería
  // ===================================================
  Future<void> _seleccionarImagen() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final ext = path.extension(pickedFile.path).toLowerCase();
      if (['.jpg', '.jpeg', '.png', '.webp'].contains(ext)) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _urlController.clear(); // si hay imagen local, limpiamos URL
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Formato no válido. Usa JPG, PNG o WEBP.'),
          ),
        );
      }
    }
  }

  // ===================================================
  // ☁️ Subir imagen local a Firebase Storage
  // ===================================================
  Future<String?> _subirImagen(File imagen) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imagen.path)}';
      final ref = FirebaseStorage.instance.ref().child('ofertas/$fileName');
      await ref.putFile(imagen);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error al subir imagen: $e');
      return null;
    }
  }

  // ===================================================
  // 🧮 Calcular descuento en porcentaje (opcional)
  // ===================================================
  double? _calcularDescuento(double? normal, double? oferta) {
    if (normal == null || oferta == null) return null;
    if (normal <= 0 || oferta >= normal) return null;
    final descuento = (1 - (oferta / normal)) * 100;
    return double.parse(descuento.toStringAsFixed(1));
  }

  // ===================================================
  // 💾 Guardar o actualizar oferta
  // ===================================================
  Future<void> _guardarOferta() async {
    final titulo = _tituloController.text.trim();
    final descripcion = _descripcionController.text.trim();
    final urlManual = _urlController.text.trim();
    final categoria = _categoriaController.text.trim();

    final precioNormalStr =
        _precioNormalController.text.trim().replaceAll(',', '.');
    final precioOfertaStr =
        _precioOfertaController.text.trim().replaceAll(',', '.');

    double? precioNormal =
        precioNormalStr.isNotEmpty ? double.tryParse(precioNormalStr) : null;
    double? precioOferta =
        precioOfertaStr.isNotEmpty ? double.tryParse(precioOfertaStr) : null;

    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Ingresa un título para la oferta.')),
      );
      return;
    }

    if (precioNormalStr.isNotEmpty && precioNormal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Precio normal inválido.')),
      );
      return;
    }

    if (precioOfertaStr.isNotEmpty && precioOferta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Precio de oferta inválido.')),
      );
      return;
    }

    // Imagen: priorizamos URL manual, luego imagen local subida
    String imageUrl = '';

    if (urlManual.isNotEmpty &&
        (urlManual.startsWith('http://') ||
            urlManual.startsWith('https://'))) {
      imageUrl = urlManual;
    } else if (_imageFile != null) {
      final url = await _subirImagen(_imageFile!);
      if (url != null) imageUrl = url;
    }

    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Debes seleccionar una imagen o ingresar una URL válida.',
          ),
        ),
      );
      return;
    }

    // Descuento calculado (si aplica)
    final descuento = _calcularDescuento(precioNormal, precioOferta);

    // 🔗 Nombre del producto vinculado (si hay)
    String? nombreProductoVinculado;
    if (_productoIdSeleccionado != null) {
      final prod = _productos.firstWhere(
        (p) => p['id'] == _productoIdSeleccionado,
        orElse: () => <String, dynamic>{},
      );
      if (prod.isNotEmpty) {
        nombreProductoVinculado = (prod['name'] ?? '').toString();
      }
    }

    // Construimos data base
    final Map<String, dynamic> data = {
      'titulo': titulo,
      'descripcion': descripcion,
      'imagen': imageUrl,
      'categoria': categoria,
      'precioNormal': precioNormal,
      'precioOferta': precioOferta,
      'descuentoPorcentaje': descuento,
      'creadoPor': _nombreAdmin ?? _correoAdmin,
      'productoId': _productoIdSeleccionado,     // id del producto
      'productoNombre': nombreProductoVinculado, // nombre del producto vinculado
    };

    if (_isEditing && _editId != null) {
      data['fechaActualizacion'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection('ofertas')
          .doc(_editId)
          .update(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Oferta actualizada correctamente.')),
      );
    } else {
      data['activo'] = true;
      data['fecha'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance.collection('ofertas').add(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Oferta registrada exitosamente.')),
      );
    }

    Navigator.of(context).pop();
    _resetFormulario();
  }

  // ===================================================
  // 🧹 Limpiar formulario
  // ===================================================
  void _resetFormulario() {
    setState(() {
      _isEditing = false;
      _editId = null;
      _tituloController.clear();
      _descripcionController.clear();
      _urlController.clear();
      _precioNormalController.clear();
      _precioOfertaController.clear();
      _categoriaController.clear();
      _imageFile = null;
      _productoIdSeleccionado = null; // limpiamos relación
    });
  }

  // ===================================================
  // 🗑️ Eliminar oferta (con confirmación)
  // ===================================================
  Future<void> _eliminarOferta(String id, String titulo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar oferta'),
        content: Text(
          '¿Seguro que deseas eliminar la oferta:\n\n"$titulo"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    await FirebaseFirestore.instance.collection('ofertas').doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🗑️ Oferta eliminada correctamente.')),
    );
  }

  // ===================================================
  // 🔄 Cambiar estado activo/inactivo
  // ===================================================
  Future<void> _cambiarEstado(String id, bool estadoActual) async {
    await FirebaseFirestore.instance
        .collection('ofertas')
        .doc(id)
        .update({'activo': !estadoActual});
  }

  // ===================================================
  // 📋 Abrir modal de formulario (Nuevo / Editar)
  // ===================================================
  void _abrirFormulario({DocumentSnapshot? oferta}) {
  if (oferta != null) {
    final data = oferta.data() as Map<String, dynamic>;

    setState(() {
      _isEditing = true;
      _editId = oferta.id;
      _tituloController.text = data['titulo'] ?? '';
      _descripcionController.text = data['descripcion'] ?? '';
      _urlController.text = data['imagen'] ?? '';
      _precioNormalController.text =
          data['precioNormal'] != null ? data['precioNormal'].toString() : '';
      _precioOfertaController.text =
          data['precioOferta'] != null ? data['precioOferta'].toString() : '';
      _categoriaController.text = data['categoria'] ?? '';
      _productoIdSeleccionado = data['productoId'];
      _imageFile = null;
    });
  } else {
    _resetFormulario();
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // 👈 para ver el blur/dim
    builder: (context) {
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          color: Colors.black.withOpacity(0.25), // fondo oscurecido
          child: DraggableScrollableSheet(
            initialChildSize: 0.88,
            minChildSize: 0.7,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // “Handle” superior
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Encabezado
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.orange.shade50,
                            child: Icon(
                              _isEditing
                                  ? Icons.edit_outlined
                                  : Icons.local_offer_outlined,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _isEditing
                                  ? 'Editar oferta'
                                  : 'Nueva oferta',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _resetFormulario();
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Contenido scrolleable
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                        child: _buildFormularioProfesional(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
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


  // ===================================================
  // 🧾 FORMULARIO DE OFERTA con previsualización
  // ===================================================
 Widget _buildFormularioProfesional() {
  double? precioNormal = double.tryParse(
    _precioNormalController.text.trim().replaceAll(',', '.'),
  );
  double? precioOferta = double.tryParse(
    _precioOfertaController.text.trim().replaceAll(',', '.'),
  );
  final descuento = _calcularDescuento(precioNormal, precioOferta);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Sección: Datos básicos
      _buildSectionTitle('Datos básicos'),
      const SizedBox(height: 8),
      Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título de la oferta',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción / Detalles',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _categoriaController,
                decoration: const InputDecoration(
                  labelText: 'Categoría (opcional)',
                  hintText: 'Ej. Abarrotes, Golosinas, Limpieza...',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(height: 16),

// Sección: Producto y precios
_buildSectionTitle('Producto y precios'),
const SizedBox(height: 8),
Card(
  elevation: 1,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _productoIdSeleccionado,
          isExpanded: true,
          items: _productos.map((p) {
            return DropdownMenuItem<String>(
              value: p['id'] as String,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      p['name'] ?? 'Sin nombre',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (p['price'] != null)
                    Text(
                      'S/ ${p['price'].toString()}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
       onChanged: (val) {
  setState(() {
    _productoIdSeleccionado = val;
    if (val == null) return;

    final prod = _productos.firstWhere(
      (p) => p['id'] == val,
      orElse: () => <String, dynamic>{},
    );

    if (prod.isNotEmpty) {
      // ❌ Ya NO tocamos el título
      // _tituloController.text = prod['name'] ?? '';

      // ✅ Solo sugerimos categoría (si viene del producto)
      if (prod['category'] != null) {
        _categoriaController.text = prod['category'].toString();
      }

      // ✅ Solo sugerimos precio normal (si viene del producto)
      if (prod['price'] != null) {
        _precioNormalController.text = prod['price'].toString();
      }

      // ❌ IMPORTANTE:
      // No tocamos la imagen de la oferta
      // _urlController NO se modifica
      // _imageFile NO se modifica

      // Opcional: limpiar precio oferta si cambias de producto
      _precioOfertaController.clear();
    }
  });
},
          decoration: const InputDecoration(
            labelText: 'Producto vinculado (opcional)',
            prefixIcon: Icon(Icons.inventory_2_outlined),
          ),
        ),

        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _precioNormalController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Precio normal',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _precioOfertaController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Precio oferta',
                  prefixIcon: Icon(Icons.local_offer_outlined),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        if (descuento != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.trending_down,
                size: 18,
                color: Colors.green,
              ),
              const SizedBox(width: 6),
              Text(
                'Descuento estimado: -$descuento %',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  ),
),


      const SizedBox(height: 16),

      // Sección: Imagen
      _buildSectionTitle('Imagen de la oferta'),
      const SizedBox(height: 8),
      Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL de imagen (opcional)',
                  hintText: 'https://mi-servidor.com/imagen.jpg',
                  prefixIcon: Icon(Icons.link),
                ),
                onChanged: (val) {
                  if (val.isNotEmpty) {
                    setState(() => _imageFile = null);
                  }
                },
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text('Seleccionar desde galería'),
                  onPressed: _seleccionarImagen,
                ),
              ),
              const SizedBox(height: 8),
              if (_imageFile != null || _urlController.text.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _imageFile != null
                        ? Image.file(
                            _imageFile!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            _urlController.text,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox(
                              height: 160,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),

      const SizedBox(height: 20),

      // Botones de acción
      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: Text(_isEditing ? 'Actualizar' : 'Guardar'),
              onPressed: _guardarOferta,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.cancel),
              label: const Text('Cancelar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade400,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _resetFormulario();
              },
            ),
          ),
        ],
      ),
    ],
  );
}
Widget _buildSectionTitle(String title) {
  return Row(
    children: [
      Container(
        width: 4,
        height: 18,
        decoration: BoxDecoration(
          color: Colors.orange.shade400,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ],
  );
}

  

  // ===================================================
  // 📋 LISTA DE OFERTAS + filtros
  // ===================================================
  Widget _buildListaOfertas() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ofertas')
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No hay ofertas registradas.'));
        }

        // Filtramos según estado y búsqueda
        List<QueryDocumentSnapshot> filtradas = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final activo = data['activo'] ?? false;
          final titulo = (data['titulo'] ?? '').toString().toLowerCase();

          if (_filtroVista == 'activas' && !activo) return false;
          if (_filtroVista == 'inactivas' && activo) return false;

          if (_busqueda.isNotEmpty &&
              !titulo.contains(_busqueda.toLowerCase())) {
            return false;
          }

          return true;
        }).toList();

        int totalOfertas = docs.length;
        int activas = docs
            .where((d) => (d.data() as Map<String, dynamic>)['activo'] == true)
            .length;
        int inactivas = totalOfertas - activas;

        return Column(
          children: [
            // Header: filtros + stats
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ofertas registradas',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar por título...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() => _busqueda = value.trim());
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _chipFiltroVista('Todas', 'todas'),
                      _chipFiltroVista('Activas', 'activas'),
                      _chipFiltroVista('Inactivas', 'inactivas'),
                      const Spacer(),
                      Text(
                        '$activas activas \n $inactivas inactivas',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: filtradas.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay ofertas según el filtro actual.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.black54,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtradas.length,
                      itemBuilder: (context, index) {
                        final oferta = filtradas[index];
                        final data = oferta.data() as Map<String, dynamic>;
                        final activa = data['activo'] ?? false;

                        final double? precioNormal = data['precioNormal'] is num
                            ? (data['precioNormal'] as num).toDouble()
                            : null;
                        final double? precioOferta = data['precioOferta'] is num
                            ? (data['precioOferta'] as num).toDouble()
                            : null;
                        final double? descuento =
                            data['descuentoPorcentaje'] is num
                                ? (data['descuentoPorcentaje'] as num)
                                    .toDouble()
                                : _calcularDescuento(
                                    precioNormal, precioOferta);

                        final bool tieneProductoVinculado =
                            (data['productoId'] ?? '').toString().isNotEmpty;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _abrirFormulario(oferta: oferta),
                            onLongPress: () => _eliminarOferta(
                              oferta.id,
                              data['titulo'] ?? 'esta oferta',
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      data['imagen'] ?? '',
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => const Icon(
                                        Icons.image_not_supported,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                data['titulo'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ),
                                            if ((data['categoria'] ?? '')
                                                .toString()
                                                .isNotEmpty)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      Colors.orange.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  data['categoria'],
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors
                                                        .orange.shade800,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          data['descripcion'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),

                                        if (tieneProductoVinculado) ...[
                                          Row(
                                            children: const [
                                              Icon(
                                                Icons.link,
                                                size: 14,
                                                color: Colors.blueGrey,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Vinculado a un producto',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.blueGrey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                        ],

                                        if (precioNormal != null ||
                                            precioOferta != null)
                                          Row(
                                            children: [
                                              if (precioOferta != null)
                                                Text(
                                                  'S/ ${precioOferta.toStringAsFixed(2)}  ',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              if (precioNormal != null)
                                                Text(
                                                  'S/ ${precioNormal.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                  ),
                                                ),
                                              if (descuento != null) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    '-$descuento%',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.red.shade700,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Switch(
                                        value: activa,
                                        onChanged: (val) => _cambiarEstado(
                                            oferta.id, activa),
                                        activeColor: Colors.green,
                                      ),
                                      Text(
                                        activa ? 'Activo' : 'Inactivo',
                                        style: const TextStyle(fontSize: 12),
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
    );
  }

  Widget _chipFiltroVista(String label, String value) {
    final bool selected = _filtroVista == value;
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
        onSelected: (_) => setState(() => _filtroVista = value),
      ),
    );
  }

  // ===================================================
  // 🧩 BUILD PRINCIPAL
  // ===================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: const Text(
          'Gestión de Ofertas',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Agregar oferta',
            onPressed: () => _abrirFormulario(),
          ),
        ],
      ),
      body: _buildListaOfertas(),
    );
  }
}
