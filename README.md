# Taully App – Sistema E-commerce Móvil

## Descripción
Taully es una aplicación móvil desarrollada para gestionar un proceso de compra digital, permitiendo a los usuarios registrarse, iniciar sesión, visualizar productos, agregarlos al carrito y generar pedidos desde una interfaz móvil.

## Objetivo del proyecto
Desarrollar una aplicación e-commerce funcional que simule un entorno real de ventas digitales, integrando autenticación, base de datos en la nube y actualización de información en tiempo real.

## Tecnologías y software utilizados
- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Console
- Visual Studio Code
- Android Studio (para emulación y compilación)
- Git y GitHub

## Base de datos utilizada
La aplicación utiliza **Cloud Firestore**, una base de datos NoSQL en la nube, para almacenar:
- información de usuarios
- productos
- pedidos
- estados relacionados al flujo de compra

## Arquitectura del sistema
El sistema trabaja bajo una arquitectura **cliente-servidor**:
- **Cliente:** aplicación móvil desarrollada en Flutter
- **Servidor/backend:** servicios cloud de Firebase
- **Base de datos:** Cloud Firestore
- **Autenticación:** Firebase Authentication
- **Almacenamiento de imágenes o recursos:** Firebase Storage (si lo usaste)

## Funcionamiento del sistema
El flujo principal de la aplicación es el siguiente:

1. El usuario se registra o inicia sesión mediante Firebase Authentication.
2. Una vez autenticado, accede al catálogo de productos.
3. Los productos son obtenidos desde Cloud Firestore.
4. El usuario puede seleccionar productos y agregarlos al carrito.
5. Al confirmar la compra, la aplicación registra el pedido en Firestore.
6. La información del pedido queda disponible para su seguimiento o procesamiento.
7. El sistema mantiene sincronización entre la interfaz del usuario y la base de datos.

## Funcionamiento en tiempo real
La aplicación utiliza **Cloud Firestore en tiempo real**, lo que permite que los cambios realizados en la base de datos se reflejen automáticamente en la interfaz sin necesidad de recargar manualmente la aplicación.

Ejemplos de funcionamiento en tiempo real:
- actualización de productos disponibles
- cambios en pedidos registrados
- sincronización inmediata de datos entre usuario y sistema

## Funcionalidades principales
- Registro de usuarios
- Inicio de sesión
- Visualización de productos
- Carrito de compras
- Registro de pedidos
- Lectura y escritura de datos en la nube
- Interfaz orientada a experiencia de usuario

## Rol desarrollado en el proyecto
- Desarrollo de interfaz en Flutter
- Integración con Firebase
- Implementación de autenticación
- Estructuración de lógica de pedidos
- Conexión con base de datos en tiempo real
- Diseño del flujo entre usuario y sistema

## Capturas del sistema
Agregar aquí imágenes de:
- pantalla de login
- pantalla principal
- listado de productos
- carrito de compras
- registro de pedido

## Aprendizajes obtenidos
- Integración de aplicaciones móviles con servicios cloud
- Uso de bases de datos NoSQL en tiempo real
- Diseño de lógica de negocio para compras digitales
- Organización de flujo de información en una app móvil

## Mejoras futuras
- integración de notificaciones push
- panel administrativo
- control de stock
- historial de pedidos
