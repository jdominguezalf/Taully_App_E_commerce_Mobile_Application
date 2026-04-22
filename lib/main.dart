// ---------------------------------------------------
// 🛒 Archivo: lib/main.dart
// Proyecto: Minimarket Taully
// Descripción: Drawer, rutas limpias, búsqueda,
//              categorías sincronizadas en tiempo real y Firebase.
//              Muestra ofertas en ventana emergente al iniciar Home.
// ---------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// 🔹 Firebase Config
import 'firebase_options.dart';

// 🔹 Estado global del carrito
import 'cart.dart';



// 🔹 Páginas principales
import 'pages/pantalla_bienvenida.dart';
import 'pages/pantalla_login.dart';
import 'pages/pantalla_finaliza.dart';
import 'pages/admin_productos.dart';
import 'pages/admin_pedidos.dart';
import 'pages/admin_ofertas.dart';
import 'pages/roles/perfilcliente/perfil_mis_compras.dart';
import 'pages/roles/perfilcliente/perfil_configuracion.dart';
import 'pages/roles/perfilcliente/perfil_soporte.dart';
import 'package:taully/pages/confimacion-pedi/confirmacion_pedido_page.dart';
import 'widgets/cart_page.dart';
// 🔹 Versión
import 'utils/version_checker.dart';
import 'pages/version_blocked_screen.dart';

// 🔹 Páginas de registro
import 'pages/pantallas_de_registro/pantalla_selector_registro.dart';
import 'pages/pantallas_de_registro/pantalla_registro_admin.dart';
import 'pages/pantallas_de_registro/pantalla_registro_cliente.dart';

// 🔹 Páginas de productos
import 'pages/abarrotes_page.dart';
import 'pages/golosinas_page.dart';
import 'pages/limpieza_page.dart';
import 'pages/ricocan_page.dart';
import 'pages/productos_busqueda_page.dart';

// 🔹 Perfil
import 'pages/roles/perfilcliente/perfil_cliente.dart';

// 🔹 Animación personalizada
import 'widgets/custom_page_route.dart';

// ===================================================
// 🚀 MAIN con chequeo de versión
// ===================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 👇 Antes de levantar la app, verificamos versión contra Firestore
  final versionStatus = await VersionChecker.checkVersion();

  runApp(
    ChangeNotifierProvider(
      create: (context) => Cart(),
      child: versionStatus.isAllowed
          ? const MyApp() // app normal
          : VersionBlockedScreen(
              mensaje: versionStatus.message,
              minVersion: versionStatus.minVersion,
            ),
    ),
  );
}

// ===================================================
// 🎨 APLICACIÓN PRINCIPAL
// ===================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minimarket Taully',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        appBarTheme: const AppBarTheme(
          elevation: 2,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: '/Bienvenida',
      onGenerateRoute: _generateRoutes,

      // 👇 Aquí hacemos que TODA la app se vea como “celular” en Web
      builder: (context, child) {
        if (!kIsWeb) return child!; // En móvil, normal

        return Container(
          color: const Color(0xFFFFFDE7), // color de fondo alrededor
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 800, // 👉 ancho máximo (480, 600, 720…)
            ),
            child: child,
          ),
        );
      },
    );
  }

  // 🔹 Rutas principales
  Route _generateRoutes(RouteSettings settings) {
    switch (settings.name) {
      case '/Bienvenida':
        return CustomPageRoute(child: const PantallaBienvenida());
      case '/home':
        return CustomPageRoute(child: const HomePage());
      case '/Finaliza':
        return CustomPageRoute(child: PantallaFinaliza());
      case '/login':
        return CustomPageRoute(child: const PantallaLogin());
      case '/admin-productos':
        return CustomPageRoute(child: const AdminProductosPage());
      case '/admin-pedidos':
        return CustomPageRoute(child: const AdminPedidosPage());
      case '/admin-ofertas':
        return CustomPageRoute(child: const AdminOfertasPage());
      case '/selector-registro':
        return CustomPageRoute(child: const PantallaSelectorRegistro());
      case '/registro-cliente':
        return CustomPageRoute(child: const PantallaRegistroCliente());
      case '/registro-admin':
        return CustomPageRoute(child: const PantallaRegistroAdmin());
      case '/perfil-cliente':
        return CustomPageRoute(child: const PerfilClientePage());
      case '/confirmacion-pedido':
        return CustomPageRoute(child: const ConfirmacionPedidoPage());
      case '/perfil-mis-compras':
        return CustomPageRoute(child: const PerfilMisComprasPage());
      case '/perfil-configuracion':
        return CustomPageRoute(child: const PerfilConfiguracionPage());
      case '/perfil-soporte':
        return CustomPageRoute(child: const PerfilSoportePage());
      case '/Mi-Carrito':
        return CustomPageRoute(child: const CartPage());
      default:
        return MaterialPageRoute(
          builder: (context) => const PantallaBienvenida(),
        );
    }
  }
}

// ===================================================
// 🏠 HOME PAGE — Header retráctil + Ofertas emergentes
// ===================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  String _searchTerm = '';
  bool _ofertasMostradas = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {});
    });

    // 👇 Auto-popup sólo una vez al entrar
    Future.delayed(
      const Duration(milliseconds: 700),
      () => _mostrarOfertasEmergentes(autoPopup: true),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

// ===================================================
// 💬 Mostrar ventana emergente con ofertas activas
//    autoPopup = true  → respeta el flag (_ofertasMostradas)
//    autoPopup = false → SIEMPRE muestra (para el botón)
// ===================================================
void _mostrarOfertasEmergentes({bool autoPopup = false}) async {
  // Solo bloqueamos si es auto y ya se mostró
  if (autoPopup && _ofertasMostradas) return;

  final snapshot = await FirebaseFirestore.instance
      .collection('ofertas')
      .where('activo', isEqualTo: true)
      .orderBy('fecha', descending: true)
      .limit(5)
      .get();

  if (snapshot.docs.isEmpty) return;
  if (!mounted) return;

  // Marcamos que ya se mostró al menos una vez
  setState(() => _ofertasMostradas = true);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: const Color.fromARGB(172, 240, 238, 224),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            // Altura “inteligente” según el tamaño de pantalla
            final double cardHeight =
                constraints.maxHeight > 520 ? 380 : 320;

            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "🛍️ Ofertas especiales",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Toca una oferta para ver el producto relacionado",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // 🎯 Carrusel de ofertas con altura controlada
                        SizedBox(
                          height: cardHeight,
                          child: PageView.builder(
                            itemCount: snapshot.docs.length,
                            controller:
                                PageController(viewportFraction: 0.90),
                            itemBuilder: (contextPage, index) {
                              final data = snapshot.docs[index].data()
                                  as Map<String, dynamic>;

                              final String titulo = data['titulo'] ?? '';
                              final String descripcion =
                                  data['descripcion'] ?? '';
                              final String imagen = data['imagen'] ?? '';
                              final String categoria =
                                  data['categoria'] ?? '';

                              // 🔥 Nombre del producto vinculado (guardado en la oferta)
                              final String productoNombre =
                                  (data['productoNombre'] ?? '').toString();

                              final double? precioNormal =
                                  data['precioNormal'] is num
                                      ? (data['precioNormal'] as num)
                                          .toDouble()
                                      : null;
                              final double? precioOferta =
                                  data['precioOferta'] is num
                                      ? (data['precioOferta'] as num)
                                          .toDouble()
                                      : null;
                              final double? descuento =
                                  data['descuentoPorcentaje'] is num
                                      ? (data['descuentoPorcentaje'] as num)
                                          .toDouble()
                                      : null;

                              // 🧭 Función común para ir al producto (móvil + web)
                              void irAlProducto() {
                                // 1) Cerramos el popup
                                Navigator.of(dialogContext).pop();

                                // 2) Texto a usar como búsqueda
                                String terminoBusqueda =
                                    productoNombre.isNotEmpty
                                        ? productoNombre.trim()
                                        : titulo.trim();

                                if (!mounted) return;

                                // 3) Activamos la búsqueda con el nombre del producto
                                setState(() {
                                  _searchTerm =
                                      terminoBusqueda.trim().toLowerCase();
                                  _searchController.text = terminoBusqueda;
                                });
                              }

                              return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 5,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: irAlProducto,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // 🖼 Imagen grande pero CONTROLADA
                                        AspectRatio(
                                          aspectRatio: 3 / 2,
                                          child: Container(
                                            width: double.infinity,
                                            color: Colors.grey.shade100,
                                            child: Image.network(
                                              imagen,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) =>
                                                  const Center(
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  size: 60,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // 📄 Detalles de la oferta
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                10, 8, 10, 6),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        titulo,
                                                        style: const TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                    if (categoria.isNotEmpty)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.orange
                                                              .shade50,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Text(
                                                          categoria,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.orange
                                                                .shade800,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  descripcion,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black54,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),

                                                if (precioNormal != null ||
                                                    precioOferta != null)
                                                  Row(
                                                    children: [
                                                      if (precioOferta != null)
                                                        Text(
                                                          'S/ ${precioOferta.toStringAsFixed(2)}  ',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.green,
                                                          ),
                                                        ),
                                                      if (precioNormal != null)
                                                        Text(
                                                          'S/ ${precioNormal.toStringAsFixed(2)}',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey,
                                                            decoration:
                                                                TextDecoration
                                                                    .lineThrough,
                                                          ),
                                                        ),
                                                      if (descuento != null) ...[
                                                        const SizedBox(
                                                            width: 6),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.red
                                                                .shade50,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              8,
                                                            ),
                                                          ),
                                                          child: Text(
                                                            '-$descuento%',
                                                            style: TextStyle(
                                                              fontSize: 18
                                                              ,
                                                              color: Colors.red
                                                                  .shade700,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),

                                                const Spacer(),

                                                Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: TextButton.icon(
                                                    onPressed: irAlProducto,
                                                    icon: const Icon(
                                                      Icons
                                                          .shopping_bag_outlined,
                                                      size: 18,
                                                    ),
                                                    label: const Text(
                                                      'Ver producto',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.orange,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
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
                    ),
                  ),
                ),

                // ❌ Botón cerrar
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.redAccent,
                    ),
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}



  // ===================================================
  // 🧭 Drawer lateral + estructura base
  // ===================================================
  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado');
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFFFDE7),
      drawer: _buildDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarOfertasEmergentes(autoPopup: false),
        label: const Text(
          'Ver Ofertas',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        icon: const Icon(Icons.local_offer),
        backgroundColor: Colors.orange,
      ),
      body: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (context, _) {
          return [
            SliverAppBar(
              pinned: true,
              floating: true,
              expandedHeight: 160,
              backgroundColor: Colors.amber.shade200,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFD54F), Color(0xFFFFF59D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 15,
                      top: 40,
                      child: IconButton(
                        icon: const Icon(
                          Icons.menu_rounded,
                          color: Colors.black87,
                          size: 30,
                        ),
                        onPressed: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                      ),
                    ),
                    Positioned(
                      right: 15,
                      top: 30,
                      child: Image.asset(
                        'lib/imgtaully/Taully_remo.png',
                        height: 90,
                      ),
                    ),
                    const Positioned(
                      left: 70,
                      top: 55,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "¡Hola! 👋",
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "¿Qué necesitas hoy?",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(80),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: _buildSearchBar(),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            _buildCategories(),
            Expanded(child: _buildProductsSection()),
          ],
        ),
      ),
    );
  }

  // ===================================================
  // 🔍 Barra de búsqueda
  // ===================================================
  Widget _buildSearchBar() {
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(14),
      shadowColor: Colors.amber.withOpacity(0.3),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar productos o categorías...',
          prefixIcon: const Icon(Icons.search, color: Colors.orange),
          suffixIcon: _searchTerm.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchTerm = '';
                      _searchController.clear();
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) =>
            setState(() => _searchTerm = value.trim().toLowerCase()),
      ),
    );
  }

  // ===================================================
  // 🧺 Categorías principales
  // ===================================================
  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _categoryCard(
            'Abarrotes',
            Icons.local_grocery_store,
            Colors.orange,
            0,
          ),
          _categoryCard(
            'Golosinas',
            Icons.cookie,
            Colors.pink,
            1,
          ),
          _categoryCard(
            'Limpieza',
            Icons.cleaning_services,
            Colors.blue,
            2,
          ),
          _categoryCard(
            'Mascotas',
            Icons.pets,
            Colors.green,
            3,
          ),
        ],
      ),
    );
  }

  Widget _categoryCard(
    String name,
    IconData icon,
    Color color,
    int index,
  ) {
    final bool isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 75,
        height: 90,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.25) : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                color: color.withOpacity(
                  isSelected ? 1 : 0.7,
                ),
                fontWeight:
                    isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
              child: Text(
                name,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return _searchTerm.isEmpty
        ? TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(),
            children: const [
              AbarrotesPage(searchTerm: ''),
              GolosinasPage(searchTerm: ''),
              LimpiezaPage(searchTerm: ''),
              RicocanPage(searchTerm: ''),
            ],
          )
        : ProductosBusquedaPage(searchTerm: _searchTerm);
  }
  // ===================================================
  // 📜 Drawer lateral actualizado (cliente + admin)
  // ===================================================
  Widget _buildDrawer() {
    return Drawer(
      child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _getUserData(),
        builder: (context, snapshot) {
          String nombre = 'Usuario';
          String correo = '';
          String rol = '';
          bool isAdmin = false;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data()!;
            nombre = data['nombre'] ?? 'Sin nombre';
            correo = data['email'] ?? '';

            // Intentamos leer el rol desde distintos campos
            rol = (data['rol'] ?? data['tipo'] ?? '').toString().toLowerCase();
            isAdmin = rol == 'admin' || rol == 'administrador';
          }

          return ListView(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            nombre,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      correo,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 Opciones de cliente
              _drawerItem(
                Icons.person,
                'Mi Perfil',
                Colors.green,
                '/perfil-cliente',
              ),
              _drawerItem(
                Icons.shopping_cart,
                'Mi Carrito',
                Colors.orange,
                '/Mi-Carrito', // aún en desarrollo
              ),
              ListTile(
                leading: const Icon(
                  Icons.history,
                  color: Colors.blueGrey,
                ),
                title: const Text(
                  'Historial de Compras',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                onTap: () {
                  Navigator.pop(context); // Cierra el Drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PerfilMisComprasPage(),
                    ),
                  );
                },
              ),

              // 🔹 Panel de administrador (solo si es admin)
              if (isAdmin) ...[
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Panel administrador',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _drawerItem(
                  Icons.inventory_2_outlined,
                  'Gestionar productos',
                  Colors.deepPurple,
                  '/admin-productos',
                ),
                _drawerItem(
                  Icons.receipt_long_outlined,
                  'Pedidos del día',
                  Colors.teal,
                  '/admin-pedidos',
                ),
                _drawerItem(
                  Icons.local_offer_outlined,
                  'Ofertas y promociones',
                  Colors.redAccent,
                  '/admin-ofertas',
                ),
              ],

              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String title,
    Color color,
    String? route,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: const TextStyle(fontFamily: 'Poppins'),
      ),
      onTap: () {
        Navigator.pop(context); // Cerramos drawer siempre

        if (route != null) {
          Navigator.pushNamed(context, route);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title en desarrollo')),
          );
        }
      },
    );
  }
}
