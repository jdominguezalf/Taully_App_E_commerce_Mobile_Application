import 'package:flutter/material.dart';

/// Transición personalizada reutilizable para todas las pantallas.
/// Combina un efecto de fade + slide (desliza desde la derecha).
class CustomPageRoute extends PageRouteBuilder {
  final Widget child;

  CustomPageRoute({required this.child})
      : super(
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            // Deslizamiento suave desde la derecha
            const beginOffset = Offset(0.2, 0.0);
            const endOffset = Offset.zero;
            final tween = Tween(begin: beginOffset, end: endOffset)
                .chain(CurveTween(curve: Curves.easeOutCubic));

            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
        );
}
