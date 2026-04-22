import 'package:flutter/material.dart';

class PerfilConfiguracionPage extends StatelessWidget {
  const PerfilConfiguracionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configuración"),
        backgroundColor: Colors.blueGrey,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text("Editar Nombre"),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Función próximamente disponible")),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: Colors.deepPurple),
            title: const Text("Cambiar Contraseña"),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.palette_outlined, color: Colors.teal),
            title: const Text("Modo Oscuro"),
            trailing: Switch(value: false, onChanged: (v) {}),
          ),
        ],
      ),
    );
  }
}
